import 'dart:io';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../core/router/app_router.dart';
import '../utils/constants.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handled silently
}

/// NotificationService
///
/// Handles push notifications and local notifications for:
/// - Daily photo reminders during cruise
/// - Tribe updates and matches
/// - Pod activity notifications
/// - Hangout reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Set during [initialize] if the app was cold-launched by tapping a
  /// Sea Ya prompt notification (as opposed to a warm/backgrounded tap,
  /// which `_onLocalNotificationTap` handles directly) — SplashScreen
  /// checks this once, alongside its normal auth-gate routing, since the
  /// GoRouter isn't necessarily ready to accept a push this early.
  bool launchedFromSeaYaPrompt = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Check whether a local notification (e.g. a Sea Ya prompt) is what
    // launched the app from fully closed — flutter_local_notifications'
    // own tap callback doesn't fire for this case until after the
    // Flutter engine is already up, which can be too early for GoRouter.
    final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      launchedFromSeaYaPrompt =
          launchDetails?.notificationResponse?.payload == 'sea_ya_prompt';
    }

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _isInitialized = true;
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'driftly_memories',
          'Cruise Memories',
          description: 'Daily photo reminders during your cruise',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'driftly_social',
          'Social Updates',
          description: 'Tribe matches, messages, and hangout reminders',
          importance: Importance.high,
        ),
      );
    }
  }

  /// Request notification permissions
  /// Returns true if permission was granted
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Also request local notification permissions on iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    // Request exact alarm permission on Android 12+
    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Get the FCM token for this device
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Save the FCM token to user's document in Firestore
  Future<void> saveTokenToFirestore(String userId) async {
    final token = await getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Remove FCM token from user's document (on logout)
  Future<void> removeTokenFromFirestore(String userId) async {
    final token = await getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _showLocalNotification(
      title: notification.title ?? 'Driftly',
      body: notification.body ?? '',
      payload: message.data['type'] ?? '',
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on notification type
    // TODO: Implement deep linking based on message.data['type']
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == 'sea_ya_prompt') {
      // App was already running (foreground or backgrounded) — navigate
      // directly on the static router, no BuildContext/navigator key
      // needed. The cold-start case (app fully closed) is handled
      // separately via launchedFromSeaYaPrompt, since GoRouter may not be
      // ready to accept a push this early in that scenario.
      AppRouter.router.push('/sea-ya');
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'driftly_social',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'driftly_memories' ? 'Cruise Memories' : 'Social Updates',
      channelDescription: channelId == 'driftly_memories'
          ? 'Daily photo reminders'
          : 'Social notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      Random().nextInt(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ==================== Scheduled Notifications ====================

  /// Convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Schedule daily photo reminder
  Future<void> scheduleDailyPhotoReminder({
    required int dayNumber,
    required DateTime reminderTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'driftly_memories',
      'Cruise Memories',
      channelDescription: 'Daily photo reminders during your cruise',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = 1000 + dayNumber;

    await _localNotifications.zonedSchedule(
      notificationId,
      'Capture Today\'s Memory! 📸',
      dayNumber == 0
          ? 'Take your boarding photo to start your cruise memories!'
          : 'Day $dayNumber - Don\'t forget to capture a moment from today!',
      _convertToTZDateTime(reminderTime),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'daily_photo_$dayNumber',
    );
  }

  /// Schedule boarding photo reminder
  Future<void> scheduleBoardingReminder(DateTime boardingDate) async {
    final reminderTime = DateTime(
      boardingDate.year,
      boardingDate.month,
      boardingDate.day,
      10,
      0,
    );

    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleDailyPhotoReminder(
        dayNumber: 0,
        reminderTime: reminderTime,
      );
    }
  }

  /// Schedule disembark photo reminder
  Future<void> scheduleDisembarkReminder(DateTime disembarkDate) async {
    final reminderTime = DateTime(
      disembarkDate.year,
      disembarkDate.month,
      disembarkDate.day,
      8,
      0,
    );

    if (reminderTime.isAfter(DateTime.now())) {
      const androidDetails = AndroidNotificationDetails(
        'driftly_memories',
        'Cruise Memories',
        channelDescription: 'Photo reminders for your cruise journey',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        2000,
        'Last Day! 🚢',
        'Take your disembarking photo before you leave the ship!',
        _convertToTZDateTime(reminderTime),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'disembark_photo',
      );
    }
  }

  /// Schedule "back home" photo reminder (24 hours after disembark)
  Future<void> scheduleBackHomeReminder(DateTime disembarkDate) async {
    final reminderTime = disembarkDate.add(const Duration(hours: 24));

    if (reminderTime.isAfter(DateTime.now())) {
      const androidDetails = AndroidNotificationDetails(
        'driftly_memories',
        'Cruise Memories',
        channelDescription: 'Photo reminders for your cruise journey',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        2001,
        'Back Home? 🏠',
        'Share your "back to reality" photo with your tribe!',
        _convertToTZDateTime(reminderTime),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'back_home_photo',
      );
    }
  }

  /// Schedule all cruise reminders based on sailing dates
  Future<void> scheduleAllCruiseReminders({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await cancelAllScheduledNotifications();

    await scheduleBoardingReminder(startDate);

    final cruiseDays = endDate.difference(startDate).inDays;
    for (int day = 1; day <= cruiseDays && day <= 7; day++) {
      final reminderDate = startDate.add(Duration(days: day));
      final reminderTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        14, // 2 PM
        0,
      );

      if (reminderTime.isAfter(DateTime.now())) {
        await scheduleDailyPhotoReminder(
          dayNumber: day,
          reminderTime: reminderTime,
        );
      }
    }

    await scheduleDisembarkReminder(endDate);
    await scheduleBackHomeReminder(endDate);
  }

  /// Schedule the Sea Ya "BeReal for cruises" daily prompt — one random
  /// time per cruise day, between AppConstants.seaYaStartHour and
  /// seaYaEndHour, so it's a surprise rather than a predictable fixed
  /// time. Doesn't call cancelAllScheduledNotifications itself — call
  /// this *after* scheduleAllCruiseReminders if scheduling both, since
  /// that method does clear everything first.
  Future<void> scheduleSeaYaPrompts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final random = Random();
    final cruiseDays = endDate.difference(startDate).inDays;

    const androidDetails = AndroidNotificationDetails(
      'driftly_social',
      'Social Updates',
      channelDescription: 'Sea Ya daily photo prompts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    for (int day = 0; day <= cruiseDays && day <= 7; day++) {
      final dayDate = startDate.add(Duration(days: day));
      final hourRange = AppConstants.seaYaEndHour - AppConstants.seaYaStartHour;
      final promptTime = DateTime(
        dayDate.year,
        dayDate.month,
        dayDate.day,
        AppConstants.seaYaStartHour + random.nextInt(hourRange),
        random.nextInt(60),
      );

      if (promptTime.isAfter(DateTime.now())) {
        await _localNotifications.zonedSchedule(
          3000 + day,
          'Sea Ya! 📸',
          'Time for today\'s surprise tribe photo — tap to join in!',
          _convertToTZDateTime(promptTime),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'sea_ya_prompt',
        );
      }
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // ==================== Immediate Notifications ====================

  /// Send tribe match notification
  Future<void> showTribeMatchNotification({
    required String tribeName,
    required int memberCount,
  }) async {
    await _showLocalNotification(
      title: 'You\'ve Been Matched! 🎉',
      body: 'Welcome to $tribeName! Meet your $memberCount cruise companions.',
      payload: 'tribe_match',
    );
  }

  /// Send new message notification
  Future<void> showNewMessageNotification({
    required String senderName,
    required String podName,
  }) async {
    await _showLocalNotification(
      title: podName,
      body: '$senderName sent a message',
      payload: 'new_message',
    );
  }

  /// Send hangout reminder notification
  Future<void> showHangoutReminder({
    required String location,
    required int minutesUntilStart,
  }) async {
    await _showLocalNotification(
      title: 'Hangout Starting Soon! 📍',
      body: '$location hangout starts in $minutesUntilStart minutes',
      payload: 'hangout_reminder',
    );
  }
}
