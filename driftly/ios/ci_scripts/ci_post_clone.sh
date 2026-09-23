#!/bin/sh
set -e

# Xcode Cloud doesn't have Flutter installed — grab the stable SDK.
# This repo's pubspec.yaml only constrains the Dart SDK (>=3.5.0 <4.0.0),
# not an exact Flutter version, so latest stable satisfies it.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter doctor

# Podfile's post-install hook checks that the iOS engine artifact
# (Flutter.xcframework) already exists — `flutter pub get` alone doesn't
# fetch it, so precache explicitly or `pod install` fails below.
# --force bypasses any "already cached, skip" check in case that's why a
# prior attempt exited 0 without actually placing the file.
flutter precache --ios --force

# Diagnostic only (never fails the build) — if pod install still can't
# find Flutter.xcframework after this, this output shows exactly what
# precache actually put on disk instead of leaving us guessing again.
ls -la "$HOME/flutter/bin/cache/artifacts/engine/" || true
ls -la "$HOME/flutter/bin/cache/artifacts/engine/ios/" || true

# $CI_PRIMARY_REPOSITORY_PATH is the Xcode-Cloud-provided repo root;
# the Flutter project itself lives in the driftly/ subdirectory.
cd "$CI_PRIMARY_REPOSITORY_PATH/driftly"
flutter pub get

# Diagnostic only — flutter_install_all_ios_pods (in Podfile) reads this
# file to know which plugin pods to add. If it's missing/empty, pod
# install has nothing to add and silently installs only the bare Flutter
# engine pod, which is exactly what's been happening.
echo "--- .flutter-plugins-dependencies ---"
cat "$CI_PRIMARY_REPOSITORY_PATH/driftly/.flutter-plugins-dependencies" || echo "(file does not exist)"

# Regenerates Generated.xcconfig, then CocoaPods needs a run too since
# the Podfile also depends on Flutter's generated podhelper.rb.
cd ios
pod install

# Diagnostic only (never fails the build) — if the Runner target still
# can't resolve FirebaseCore as a Swift module afterward, this shows
# exactly what pod install actually vendored/generated for it instead of
# guessing blind again.
echo "--- FirebaseCore pod contents ---"
find "$CI_PRIMARY_REPOSITORY_PATH/driftly/ios/Pods" -iname "*FirebaseCore*" -maxdepth 3 || true
echo "--- Pods-Runner.release.xcconfig ---"
cat "$CI_PRIMARY_REPOSITORY_PATH/driftly/ios/Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig" || true
echo "--- Podfile.lock ---"
cat "$CI_PRIMARY_REPOSITORY_PATH/driftly/ios/Podfile.lock" || true
