# Eylexander's F-Droid repo

Personal F-Droid repository for my Android apps. APKs are committed to `repo/`; on every push GitHub Actions
runs `fdroid update`, signs the index and publishes it on GitHub Pages:

- Landing page (link + QR code): https://eylexander.github.io/fdroid/
- Repo address: https://eylexander.github.io/fdroid/repo
- Fingerprint: `A82A40DB36060D3F313871D07E609EDB6CF9314252874F75A48CA2A1F3A8DC08`

| App | Package | Source |
| --- | --- | --- |
| Audio Cutter | `com.eylexander.audio_cutter` | [Eylexander/audio_player](https://github.com/Eylexander/audio_player) |

## Publishing an update

```sh
# in the app's project: bump `version:` in pubspec.yaml (the +build number must go up), then
flutter build apk --release --split-per-abi

# here:
scripts/publish.sh ../fossify/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
git push
```

`publish.sh` reads the package and versionCode with `aapt2`, copies the APK to `repo/<package>_<versionCode>.apk`,
keeps the last 3 versions of each app (`KEEP=5 scripts/publish.sh …` to change that) and commits. Phones see the
update after the next F-Droid refresh.

## Adding another app

1. Copy `metadata/com.eylexander.audio_cutter.yml` to `metadata/<package>.yml` and edit it
   ([metadata reference](https://f-droid.org/docs/Build_Metadata_Reference/)). Screenshots and icons can go in
   `metadata/<package>/en-US/` (fastlane layout: `images/icon.png`, `images/phoneScreenshots/1.png`…).
2. `scripts/publish.sh path/to/release.apk` and push.

## Rules worth knowing

- **Each app must always be signed with the same key.** Android refuses an update signed differently. Audio Cutter
  is signed with the debug key of this PC (`~/.android/debug.keystore`): back that file up, or move the app to a
  real release key before others install it (that change forces one uninstall).
- **versionCode must increase.** `--split-per-abi` builds use `1000 × abi + build number` (arm64 = 2xxx), so only
  publish one ABI per app, or all of them for every release.
- Debug builds are rejected (`android:debuggable`).

## Repo signing key (one-time setup, already done)

`scripts/new-keystore.sh` created `keystore.p12` and `.secrets/` (both git-ignored). **Back up `.secrets/`**: if the
key is lost, every phone has to remove and re-add the repo.

GitHub setup:

1. Create the `fdroid` repository on GitHub (public, so Pages is free) and push this one to it.
2. Settings → Secrets and variables → Actions → add `FDROID_KEYSTORE_B64` and `FDROID_KEYSTORE_PASS` with the
   contents of the matching files in `.secrets/`.
3. Settings → Pages → Source: **GitHub Actions**.
4. Actions → "Publish F-Droid repo" → Run workflow (or push).

Then on the phone: open the landing page and tap "Add to F-Droid", or add the repo address and fingerprint by hand.
