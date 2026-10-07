#!/usr/bin/env bash
# Adds release APKs to the repo, keeps the last $KEEP versions of each app, and commits.
#   scripts/publish.sh path/to/app-arm64-v8a-release.apk [more.apk ...]
# Then `git push`: GitHub Actions rebuilds the index and publishes it.
set -euo pipefail

KEEP=${KEEP:-3}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SDK=${ANDROID_HOME:-${LOCALAPPDATA:-$HOME/AppData/Local}/Android/Sdk}
AAPT2=$(ls -d "$SDK"/build-tools/*/ 2>/dev/null | sort -V | tail -1)aapt2
[ -x "$AAPT2" ] || [ -x "$AAPT2.exe" ] || { echo "aapt2 not found under $SDK/build-tools" >&2; exit 1; }

[ $# -gt 0 ] || { echo "usage: $0 app.apk [...]" >&2; exit 1; }

added=()
for apk in "$@"; do
  badging=$("$AAPT2" dump badging "$apk" | head -1)
  pkg=$(sed -E "s/.*package: name='([^']+)'.*/\1/" <<<"$badging")
  code=$(sed -E "s/.*versionCode='([^']+)'.*/\1/" <<<"$badging")
  name=$(sed -E "s/.*versionName='([^']*)'.*/\1/" <<<"$badging")
  [ -n "$pkg" ] && [ -n "$code" ] || { echo "can't read $apk" >&2; exit 1; }

  if "$AAPT2" dump badging "$apk" | grep -q "application-debuggable"; then
    echo "$apk is a debug build; F-Droid rejects those. Use a release APK." >&2; exit 1
  fi
  [ -f "$ROOT/metadata/$pkg.yml" ] || {
    echo "No metadata/$pkg.yml yet. Copy metadata/com.eylexander.audio_cutter.yml and edit it." >&2; exit 1; }

  dest="$ROOT/repo/${pkg}_${code}.apk"
  if [ -f "$dest" ]; then
    echo "$pkg versionCode $code is already published. Bump the version first." >&2; exit 1
  fi
  cp "$apk" "$dest"
  echo "Added $pkg $name ($code)"
  added+=("$pkg $name")

  # Prune older versions of this app.
  ls "$ROOT/repo/${pkg}"_*.apk | sed -E 's/.*_([0-9]+)\.apk$/\1 &/' | sort -n | head -n -"$KEEP" |
    while read -r _ old; do echo "Removed $(basename "$old")"; rm -f "$old"; done
done

git -C "$ROOT" add -A repo
git -C "$ROOT" commit -q -m "Publish $(IFS=,; echo "${added[*]}" | sed 's/,/, /g')"
echo "Committed. Run 'git push' to publish."
