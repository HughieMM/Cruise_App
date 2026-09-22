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
flutter precache --ios

# $CI_PRIMARY_REPOSITORY_PATH is the Xcode-Cloud-provided repo root;
# the Flutter project itself lives in the driftly/ subdirectory.
cd "$CI_PRIMARY_REPOSITORY_PATH/driftly"
flutter pub get

# Regenerates Generated.xcconfig, then CocoaPods needs a run too since
# the Podfile also depends on Flutter's generated podhelper.rb.
cd ios
pod install
