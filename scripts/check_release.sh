#!/bin/sh
set -eu
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
firebase emulators:exec --project demo-vaultboard --only auth,firestore 'npm test'
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
shasum -a 256 build/app/outputs/flutter-apk/app-release.apk
