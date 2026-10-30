#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

if [[ -z "${JAVA_HOME:-}" && -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]]; then
  export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
fi
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
if [[ ! -d "$ANDROID_HOME/platforms/android-36" ]]; then
  echo "Android SDK 36 is required. Set ANDROID_HOME to your SDK directory." >&2
  exit 1
fi

opam exec -- scripts/build_site.sh
npx cap sync android
python3 scripts/setup_android_signing.py
cd android
./gradlew assembleDebug assembleRelease bundleRelease
cd "$repository_root"
mkdir -p artifacts
cp android/app/build/outputs/apk/debug/app-debug.apk artifacts/young-blog-debug.apk
cp android/app/build/outputs/apk/release/app-release.apk artifacts/young-blog.apk
cp android/app/build/outputs/bundle/release/app-release.aab artifacts/young-blog.aab
shasum -a 256 artifacts/young-blog.apk > artifacts/young-blog.apk.sha256
echo "Installable APK: $repository_root/artifacts/young-blog.apk"
