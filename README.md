# Eylexander's F-Droid repo

Personal F-Droid repository for my Android apps. Nothing is stored here but the store listings: every 6 hours
(and on every push) GitHub Actions looks for new GitHub releases of each app, downloads their APKs, runs
`fdroid update`, signs the index and publishes it on GitHub Pages:

- Landing page (link + QR code): https://eylexander.github.io/fdroid/
- Repo address: https://eylexander.github.io/fdroid/repo
- Fingerprint: `A82A40DB36060D3F313871D07E609EDB6CF9314252874F75A48CA2A1F3A8DC08`

| App | Package | Source |
| --- | --- | --- |
| Audio Cutter | `com.eylexander.audio_cutter` | [Eylexander/audio_player](https://github.com/Eylexander/audio_player) |

## Publishing an update

Publish a GitHub release with the APK attached in the app's repository (for Audio Cutter: push a `v*` tag). Nothing
to do here: within 6 hours the scheduled run picks it up, or run "Publish F-Droid repo" from the Actions tab to
publish it right away. Phones see the update after their next F-Droid refresh.

`scripts/fetch-releases.sh` reads the GitHub repository from `SourceCode:` in `metadata/<package>.yml` and downloads
the APK of the last 3 releases (drafts and pre-releases are skipped; if a release has several APKs, the `arm64` one
is used). Scheduled runs compare that list with the deployed `releases.txt` and stop there when nothing changed.

## Adding another app

1. Copy `metadata/com.eylexander.audio_cutter.yml` to `metadata/<package>.yml` and edit it
   ([metadata reference](https://f-droid.org/docs/Build_Metadata_Reference/)). Screenshots and icons can go in
   `metadata/<package>/en-US/` (fastlane layout: `images/icon.png`, `images/phoneScreenshots/1.png`…).
   `SourceCode:` must be the app's GitHub repository, which must publish releases with an APK attached.
2. Push.

## Rules worth knowing

- **Each app must always be signed with the same key.** Android refuses an update signed differently. Audio Cutter's
  release workflow signs with the debug key restored from its `DEBUG_KEYSTORE_BASE64` secret; without that secret
  each release gets a throwaway key and can't update the previous one.
- **versionCode must increase** from one release to the next (Audio Cutter's release workflow uses the run number).
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
