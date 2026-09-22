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

# Regenerates Generated.xcconfig, then CocoaPods needs a run too since
# the Podfile also depends on Flutter's generated podhelper.rb.
cd ios
pod install
