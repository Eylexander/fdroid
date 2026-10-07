# F-Droid repo

The user's personal F-Droid repository. It distributes their own Android apps so phones get updates through
F-Droid (or Droid-ify / Neo Store). Hosted on GitHub Pages at `https://eylexander.github.io/fdroid/repo`. The
only app so far is Audio Cutter (`com.eylexander.audio_cutter`), whose source is `../fossify`
(GitHub `Eylexander/audio_player`; it has its own CLAUDE.md).

## How it works

- Release APKs are **committed** to `repo/` as `<package>_<versionCode>.apk`. Nothing is built from source here.
- On every push to `main`, `.github/workflows/publish.yml` installs fdroidserver (pip), restores the signing key
  from secrets, runs `fdroid update`, then deploys `site/` to Pages: the generated `repo/` plus `site.html` turned
  into `index.html` (the `@ADD_URL@`, `@REPO_URL@`, `@FINGERPRINT@`, `@APPS@` placeholders are filled by `sed`).
- Everything `fdroid update` generates (`repo/index*`, `repo/entry*`, icons, `tmp/`, `archive/`) is git-ignored and
  exists only in CI.

| Path | Role |
| --- | --- |
| `config.yml` | fdroidserver config. Passwords are `{env: FDROID_KEYSTORE_PASS}`, never in the file |
| `metadata/<package>.yml` | Store listing for each app (Name, Summary, Description, Categories, SourceCode) |
| `scripts/publish.sh` | Adds APKs to `repo/`, prunes to the last `KEEP` (3) versions per app, commits |
| `scripts/new-keystore.sh` | Created the repo signing key once. Refuses to overwrite it |
| `site.html` | Landing page template (link + QR code via qrcodejs from cdnjs) |

## Commands

The shell is Git Bash on Windows. JDK: `~/.jdks/jbr-21.0.9`. `aapt2` comes from the newest
`%LOCALAPPDATA%/Android/Sdk/build-tools/*`. There is no `gh` CLI and fdroidserver is not installed locally
(Docker Desktop exists but is usually not running), so `fdroid` commands only run in CI.

```sh
scripts/publish.sh ../fossify/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
git push
```

## Rules

- **Never regenerate or replace the repo signing key.** `keystore.p12` and `.secrets/` (password, base64 keystore,
  fingerprint) are git-ignored and must never be committed. A new key means every phone has to remove and re-add
  the repo. Fingerprint: `A82A40DB36060D3F313871D07E609EDB6CF9314252874F75A48CA2A1F3A8DC08`.
- GitHub secrets: `FDROID_KEYSTORE_B64`, `FDROID_KEYSTORE_PASS` (same password for store and key, alias
  `fdroid-repo`).
- An app must always be signed with the same key, or Android refuses the update. Audio Cutter's release build is
  signed with this PC's debug key (`~/.android/debug.keystore`).
- versionCode must go up for each release. For Flutter apps it's the `+N` of `version:` in `pubspec.yaml`; with
  `--split-per-abi` every ABI gets the **same** versionCode (no ABI offset in this Flutter version), so publish
  only one ABI per app (arm64).
- Debug APKs (`application-debuggable`) are rejected by `publish.sh`, and by F-Droid.
- `archive_older: 0`: old versions are pruned by `publish.sh`, so there is no archive repo to publish.
- Commits carry no Claude/AI attribution lines.

## Gotchas

- `keytool` prints in French on this machine (`SHA 256:` instead of `SHA256:`); the fingerprint parsing uses
  `SHA ?256:` to handle both.
- APKs are binary in `.gitattributes`; text files are forced to LF so the scripts run in CI.
- History grows by ~19 MB per published release. If it gets too big, move APKs to GitHub Releases and have the
  workflow download them.

## Status (2026-10-07)

Created locally with Audio Cutter 1.1.0 (versionCode 2, arm64) in `repo/`. **Not pushed yet, and the workflow
has never run**: the GitHub repo, the two secrets and Pages (source: GitHub Actions) still have to be set up by the
user (steps in README). The first CI run is the first real test of `fdroid update` with this config.
