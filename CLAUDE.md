# F-Droid repo

The user's personal F-Droid repository. It distributes their own Android apps so phones get updates through
F-Droid (or Droid-ify / Neo Store). Hosted on GitHub Pages at `https://eylexander.github.io/fdroid/repo`. The
only app so far is Audio Cutter (`com.eylexander.audio_cutter`), whose source is `../fossify`
(GitHub `Eylexander/audio_player`; it has its own CLAUDE.md).

## How it works

- No APK is committed. `scripts/fetch-releases.sh` downloads the APK of the last `KEEP` (3) GitHub releases of each
  app (repo taken from `SourceCode:` in its metadata) into `repo/<package>_<tag>.apk`. Nothing is built here.
- `.github/workflows/publish.yml` runs on push to `main`, every 6 hours and on demand. Its `check` job lists the
  release APKs; on scheduled runs it stops if the list equals the deployed `releases.txt`. Otherwise `build`
  installs fdroidserver (pip), restores the signing key from secrets, downloads the APKs, runs `fdroid update`, then
  deploys `site/` to Pages: the generated `repo/`, `releases.txt`, and `site.html` turned into `index.html` (the
  `@ADD_URL@`, `@REPO_URL@`, `@FINGERPRINT@`, `@APPS@` placeholders are filled by `sed`).
- Everything `fdroid update` generates (`repo/index*`, `repo/entry*`, icons, `tmp/`, `archive/`) is git-ignored and
  exists only in CI.

| Path | Role |
| --- | --- |
| `config.yml` | fdroidserver config. Passwords are `{env: FDROID_KEYSTORE_PASS}`, never in the file |
| `metadata/<package>.yml` | Store listing for each app (Name, Summary, Description, Categories, SourceCode) |
| `scripts/fetch-releases.sh` | Lists (`--list`) or downloads the release APKs into `repo/`. Needs curl and jq |
| `scripts/new-keystore.sh` | Created the repo signing key once. Refuses to overwrite it |
| `site.html` | Landing page template (link + QR code via qrcodejs from cdnjs) |

## Commands

The shell is Git Bash on Windows. JDK: `~/.jdks/jbr-21.0.9`. `aapt2` comes from the newest
`%LOCALAPPDATA%/Android/Sdk/build-tools/*`. There is no `gh` CLI and fdroidserver is not installed locally
(Docker Desktop exists but is usually not running), so `fdroid` commands only run in CI. jq isn't installed
either; to test `fetch-releases.sh` locally, put a jq binary on `PATH`.

Publishing an update is done in the app's repository (Audio Cutter: push a `v*` tag, its workflow creates the
release). Then wait for the schedule or run the workflow from the Actions tab.

## Rules

- **Never regenerate or replace the repo signing key.** `keystore.p12` and `.secrets/` (password, base64 keystore,
  fingerprint) are git-ignored and must never be committed. A new key means every phone has to remove and re-add
  the repo. Fingerprint: `A82A40DB36060D3F313871D07E609EDB6CF9314252874F75A48CA2A1F3A8DC08`.
- GitHub secrets: `FDROID_KEYSTORE_B64`, `FDROID_KEYSTORE_PASS` (same password for store and key, alias
  `fdroid-repo`).
- An app must always be signed with the same key, or Android refuses the update. Audio Cutter is signed with its
  release key in `../fossify/.secrets/` (SHA-256 `db171ead…`); its workflow gets it from the
  `RELEASE_KEYSTORE_BASE64` / `RELEASE_KEYSTORE_PASS` secrets and refuses to publish a tag without them.
- versionCode must go up for each release (Audio Cutter's release workflow sets it to the run number).
- Debug APKs (`application-debuggable`) are rejected by F-Droid.
- `archive_older: 0`: only the last 3 releases are downloaded, so there is no archive repo to publish.
- Commits carry no Claude/AI attribution lines.

## Gotchas

- `keytool` prints in French on this machine (`SHA 256:` instead of `SHA256:`); the fingerprint parsing uses
  `SHA ?256:` to handle both.
- Text files are forced to LF in `.gitattributes` so the scripts run in CI.
- If a release has several APKs, `fetch-releases.sh` takes the one with `arm64` in its name, else the first.

## Status (2026-10-08)

Pushed and deployed: the workflow runs green and Pages serves the repo (secrets and Pages are set up).

Audio Cutter's releases v1.0.0 and v1.1.0 were signed with throwaway keys (`c3356b46…`, `b0a8068d…`). They are
being replaced: new release key `db171ead…`, old releases to delete, new tag, phone uninstalls the app once.
