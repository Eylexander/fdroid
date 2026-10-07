#!/usr/bin/env bash
# Creates the repo signing key (once, ever) and prints the two GitHub secrets to set.
# Losing this key means every phone has to remove and re-add the repo: back up .secrets/.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KEYTOOL=${JAVA_HOME:+$JAVA_HOME/bin/}keytool
cd "$ROOT"

[ -f keystore.p12 ] && { echo "keystore.p12 already exists; not overwriting it." >&2; exit 1; }

mkdir -p .secrets
pass=$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
"$KEYTOOL" -genkeypair -storetype PKCS12 -keystore keystore.p12 -alias fdroid-repo \
  -keyalg RSA -keysize 4096 -validity 10000 -storepass "$pass" -keypass "$pass" \
  -dname "CN=Eylexander F-Droid repo, OU=F-Droid" >/dev/null 2>&1

fingerprint=$("$KEYTOOL" -list -v -keystore keystore.p12 -storepass "$pass" -alias fdroid-repo |
  sed -nE 's/.*SHA ?256: *//p' | tr -d ':[:space:]')

cp keystore.p12 .secrets/keystore.p12
echo "$pass" > .secrets/FDROID_KEYSTORE_PASS.txt
base64 -w0 keystore.p12 > .secrets/FDROID_KEYSTORE_B64.txt
echo "$fingerprint" > .secrets/fingerprint.txt

cat <<EOF
Key created. Add these repository secrets on GitHub (Settings > Secrets and variables > Actions):
  FDROID_KEYSTORE_B64   = contents of .secrets/FDROID_KEYSTORE_B64.txt
  FDROID_KEYSTORE_PASS  = contents of .secrets/FDROID_KEYSTORE_PASS.txt
Repo fingerprint: $fingerprint
Back up the .secrets/ folder somewhere safe.
EOF
