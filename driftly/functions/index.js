/**
 * Driftly Cloud Functions — server-side photo content moderation.
 *
 * Runs Google Cloud Vision's SafeSearch Detection on every photo a user
 * uploads (profile photos, cover photo, cruise memories, Sea Ya, hangout
 * photos) and, if flagged, deletes the photo and applies the same
 * moderationStrikes/isBanned enforcement already used for the text/slur
 * filter in the Flutter app (lib/services/content_moderation_service.dart)
 * — 3 strikes bans the account. This runs with Admin SDK privileges, so
 * unlike the client-side text filter, these strike/ban writes can't be
 * spoofed or reversed by the uploading user's own client.
 */

const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
const vision = require("@google-cloud/vision").v1;

admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage();
const visionClient = new vision.ImageAnnotatorClient();

const BAN_THRESHOLD = 3; // Matches ContentModerationService's text-filter threshold.

// SafeSearch likelihood enum, in increasing order of confidence.
const LIKELIHOOD = ["UNKNOWN", "VERY_UNLIKELY", "UNLIKELY", "POSSIBLE", "LIKELY", "VERY_LIKELY"];

/**
 * Cruise photos routinely include swimwear (pool decks, beach excursions,
 * the "18+ Pool" hot zone) — Vision's "racy" category flags that kind of
 * completely normal content at POSSIBLE/LIKELY fairly often, so it needs a
 * much higher bar than genuine nudity/violence to avoid false-positiving
 * on ordinary cruise photos. Adjust these if real-world flagging turns out
 * too strict or too loose.
 */
const THRESHOLDS = {
  adult: "LIKELY",
  violence: "LIKELY",
  racy: "VERY_LIKELY",
};

function meetsThreshold(value, threshold) {
  return LIKELIHOOD.indexOf(value) >= LIKELIHOOD.indexOf(threshold);
}

function isFlagged(safeSearch) {
  return (
    meetsThreshold(safeSearch.adult, THRESHOLDS.adult) ||
    meetsThreshold(safeSearch.violence, THRESHOLDS.violence) ||
    meetsThreshold(safeSearch.racy, THRESHOLDS.racy)
  );
}

function buildDownloadUrl(bucket, filePath, token) {
  const encodedPath = encodeURIComponent(filePath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodedPath}?alt=media&token=${token}`;
}

/** Parses which of the four known upload surfaces an object path belongs
 * to, and extracts the IDs needed to clean up Firestore + know who to
 * strike. Returns null for any path this function doesn't recognize
 * (fails safe — does nothing rather than guessing). */
function parseUploadPath(filePath) {
  let match;

  match = filePath.match(/^users\/([^/]+)\/photos\/([a-zA-Z]+)_\d+\.jpg$/);
  if (match) {
    return {kind: "profile", userId: match[1], photoType: match[2]};
  }

  match = filePath.match(/^sailings\/([^/]+)\/sea_ya_photos\/([^/]+)\/[^/]+$/);
  if (match) {
    return {kind: "seaYa", sailingId: match[1], userId: match[2]};
  }

  match = filePath.match(/^sailings\/([^/]+)\/memories\/([^/]+)\/[^/]+$/);
  if (match) {
    return {kind: "memory", sailingId: match[1], userId: match[2]};
  }

  match = filePath.match(/^sailings\/([^/]+)\/hangouts\/([^/]+)\/photos\/([^/_]+)_\d+\.jpg$/);
  if (match) {
    return {kind: "hangout", sailingId: match[1], hangoutId: match[2], userId: match[3]};
  }

  return null;
}

const PROFILE_PHOTO_FIELDS = {
  face: ["facePhotoUrl", "selfieUrl"], // selfieUrl mirrors facePhotoUrl — keep both in sync.
  fun: ["funPhotoUrl"],
  wildcard: ["wildcardPhotoUrl"],
  verification: ["verificationPhotoUrl"],
  cover: ["coverPhotoUrl"],
};

async function clearProfilePhotoFields(userId, photoType) {
  const fields = PROFILE_PHOTO_FIELDS[photoType];
  if (!fields) return;
  const updates = {};
  for (const field of fields) updates[field] = null;
  await db.collection("users").doc(userId).update(updates);
}

/** Deletes every doc in `collectionRef` whose `photoUrl` field matches —
 * mirrors the same "query by photoUrl field" pattern already used by
 * ModerationService._deletePhotoFromFirestore on the client side. */
async function deleteDocsByPhotoUrl(collectionRef, photoUrl) {
  const snapshot = await collectionRef.where("photoUrl", "==", photoUrl).get();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  if (!snapshot.empty) await batch.commit();
  return snapshot.size;
}

async function recordStrike(userId) {
  const userRef = db.collection("users").doc(userId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) return;
    const current = snapshot.data().moderationStrikes || 0;
    const updated = current + 1;
    const updates = {
      moderationStrikes: updated,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (updated >= BAN_THRESHOLD) updates.isBanned = true;
    transaction.update(userRef, updates);
  });
}

exports.moderatePhotoUpload = onObjectFinalized(
  // Must match the Storage bucket's own region (this project's bucket is
  // in us-east1) — a Storage-triggered function can't listen cross-region.
  {region: "us-east1", cpu: 1, memory: "512MiB"},
  async (event) => {
    const object = event.data;
    const filePath = object.name;
    const bucketName = object.bucket;

    const parsed = parseUploadPath(filePath);
    if (!parsed) {
      // Not a recognized user-photo path (e.g. a Storage trigger firing
      // for something unrelated) — nothing to do.
      return;
    }

    let safeSearch;
    try {
      const [result] = await visionClient.safeSearchDetection(
        `gs://${bucketName}/${filePath}`,
      );
      safeSearch = result.safeSearchAnnotation;
    } catch (err) {
      logger.error(`SafeSearch check failed for ${filePath}`, err);
      return; // Fail open — don't delete a photo just because the API call itself errored.
    }

    if (!safeSearch || !isFlagged(safeSearch)) {
      return;
    }

    logger.warn(`Flagged photo at ${filePath}`, {
      adult: safeSearch.adult,
      violence: safeSearch.violence,
      racy: safeSearch.racy,
    });

    // Delete the Storage object itself first.
    try {
      await storage.bucket(bucketName).file(filePath).delete();
    } catch (err) {
      logger.error(`Failed to delete flagged Storage object ${filePath}`, err);
    }

    // Clean up the corresponding Firestore reference(s).
    try {
      if (parsed.kind === "profile") {
        await clearProfilePhotoFields(parsed.userId, parsed.photoType);
      } else {
        const token = object.metadata && object.metadata.firebaseStorageDownloadTokens
          ? object.metadata.firebaseStorageDownloadTokens.split(",")[0]
          : null;

        if (token) {
          const photoUrl = buildDownloadUrl(bucketName, filePath, token);

          if (parsed.kind === "seaYa") {
            await deleteDocsByPhotoUrl(
              db.collection("sailings").doc(parsed.sailingId).collection("seaYaPhotos"),
              photoUrl,
            );
          } else if (parsed.kind === "memory") {
            await deleteDocsByPhotoUrl(
              db.collection("sailings").doc(parsed.sailingId).collection("memories"),
              photoUrl,
            );
          } else if (parsed.kind === "hangout") {
            const photosRef = db
              .collection("sailings").doc(parsed.sailingId)
              .collection("hangouts").doc(parsed.hangoutId)
              .collection("photos");
            const deletedCount = await deleteDocsByPhotoUrl(photosRef, photoUrl);
            if (deletedCount > 0) {
              await db
                .collection("sailings").doc(parsed.sailingId)
                .collection("hangouts").doc(parsed.hangoutId)
                .update({photoCount: admin.firestore.FieldValue.increment(-deletedCount)});
            }
          }
        } else {
          logger.warn(`No download token on ${filePath} — skipped Firestore cleanup, Storage object still deleted.`);
        }
      }
    } catch (err) {
      logger.error(`Failed to clean up Firestore reference(s) for ${filePath}`, err);
    }

    // Strike the uploader — best-effort on the hangout path, since its
    // userId comes from an unenforced filename convention rather than a
    // real path segment (storage.rules allows any authenticated user to
    // write there, not just the named uploader).
    try {
      await recordStrike(parsed.userId);
    } catch (err) {
      logger.error(`Failed to record moderation strike for ${parsed.userId}`, err);
    }
  },
);
