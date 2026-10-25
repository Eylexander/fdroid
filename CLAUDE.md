# F-Droid repo

The user's personal F-Droid repository. It distributes their own Android apps so phones get updates through
F-Droid (or Droid-ify / Neo Store). Hosted on GitHub Pages at `https://eylexander.github.io/fdroid/repo`. Apps
(each source has its own CLAUDE.md):

- Audio Cutter (`com.eylexander.audio_cutter`): source `../fossify`, GitHub `Eylexander/audio_player`. Listing in
  `en-US`.
- LLLearner (`com.eylexander.lllearner`, Taiwan Mandarin for French speakers): source `../lllearner`, GitHub
  `Eylexander/lllearner`. Listing in `en-US` and `fr-FR`; keep its figures in sync with the app's README.
- Pangea (`com.eylexander.pangea`, geography game): source `../pangea`, GitHub `Eylexander/pangea`. Listing in `en-US`
  and `fr-FR`, category Games. Same release key (`db171ead…`). Added 2026-10-25 with v1.0.0.
- Re-TCAT (`com.eylexander.retcat`, live TCAT buses in Troyes): source `../re-tcat`, GitHub `Eylexander/re-tcat`.
  Listing in `en-US` and `fr-FR`. AntiFeature `NonFreeDep` (geolocator bundles the unused Play services client).
- Sablier (`com.eylexander.sablier`, limits apps to a few minutes per hour): source `../sablier`, GitHub
  `Eylexander/sablier`. Listing in `en-US` and `fr-FR`. Same release key as the others (`db171ead…`).

All are Flutter apps, released by the same workflow and listed the same way:

- **Listing**: `metadata/<package>.yml` holds only the fields (Categories, AuthorName, SourceCode). The text and icon
  are in `metadata/<package>/<locale>/` with fastlane names: `title.txt` (≤ 30 characters), `short_description.txt`
  (≤ 80), `full_description.txt` (≤ 4000, HTML) and `images/icon.png` (512 px, rendered from the app's
  `tool/icon.svg` with `rsvg-convert -w 512`). `en-US` is required: the landing page reads it. The launcher icons are
  vector-only, so `fdroid update` can't take an icon from the APK. Don't put `Name:`/`Summary:` back in the `.yml`.
- **Release**: each app's `.github/workflows/release.yml` only calls `.github/workflows/flutter-apk.yml` from this
  repo (`@main`, so this repo must stay public) with its APK name and Flutter version, and passes its
  `RELEASE_KEYSTORE_*` secrets. A change to `flutter-apk.yml` applies to every app's next release.

## How it works

- No APK is committed. `scripts/fetch-releases.sh` downloads the APK of the last `KEEP` (3) GitHub releases of each
  app (repo taken from `SourceCode:` in its metadata) into `repo/<package>_<tag>.apk`. Nothing is built here.
- `.github/workflows/publish.yml` runs on push to `main`, every 6 hours and on demand. Its `check` job lists the
  release APKs; on scheduled runs it stops if the list equals the deployed `releases.txt`. Otherwise `build`
  installs fdroidserver (pip), restores the signing key from secrets, downloads the APKs, runs `fdroid update`, then
  deploys `site/` to Pages: the generated `repo/`, `releases.txt`, and `site.html` turned into `index.html` (the
  `@ADD_URL@`, `@REPO_URL@`, `@FINGERPRINT@`, `@SOURCE_URL@` placeholders are filled by `sed`; the `@APPS@` line
  is replaced by app cards built from the `en-US` title and short description, `releases.txt` and the icons of
  `fdroid update`).
- Before that, the `Check listings` step fails the build if an app lacks an `en-US` file or a text is over its limit.
- Everything `fdroid update` generates (`repo/index*`, `repo/entry*`, icons, `tmp/`, `archive/`) is git-ignored and
  exists only in CI.

| Path | Role |
| --- | --- |
| `config.yml` | fdroidserver config. Passwords are `{env: FDROID_KEYSTORE_PASS}`, never in the file |
| `metadata/<package>.yml` | Each app's fields: Categories, AuthorName, SourceCode (its GitHub repository) |
| `metadata/<package>/<locale>/` | Each app's title, descriptions and `images/icon.png` (fastlane names) |
| `.github/workflows/flutter-apk.yml` | Shared release build (`workflow_call`), called by each app's `release.yml` |
| `scripts/fetch-releases.sh` | Lists (`--list`) or downloads the release APKs into `repo/`. Needs curl and jq |
| `scripts/new-keystore.sh` | Created the repo signing key once. Refuses to overwrite it |
| `site.html` | Landing page template (add link, QR code via qrcodejs from cdnjs, app cards, GitHub link) |

## Commands

The shell is Git Bash on Windows. JDK: `~/.jdks/jbr-21.0.9`. `aapt2` comes from the newest
`%LOCALAPPDATA%/Android/Sdk/build-tools/*`. There is no `gh` CLI and fdroidserver is not installed locally
(Docker Desktop exists but is usually not running), so `fdroid` commands only run in CI. jq isn't installed
either; to test `fetch-releases.sh` locally, put a jq binary on `PATH`.

Publishing an update is done in the app's repository (push a `v*` tag; its workflow creates the release). Then wait for the schedule or run the workflow from the Actions tab.

## Rules

- **Never regenerate or replace the repo signing key.** `keystore.p12` and `.secrets/` (password, base64 keystore,
  fingerprint) are git-ignored and must never be committed. A new key means every phone has to remove and re-add
  the repo. Fingerprint: `A82A40DB36060D3F313871D07E609EDB6CF9314252874F75A48CA2A1F3A8DC08`.
- GitHub secrets: `FDROID_KEYSTORE_B64`, `FDROID_KEYSTORE_PASS` (same password for store and key, alias
  `fdroid-repo`).
- An app must always be signed with the same key, or Android refuses the update. Audio Cutter is signed with its
  release key in `../fossify/.secrets/` (SHA-256 `db171ead…`). LLLearner uses the same key (copy in
  `../lllearner/.secrets/`; its v1.0.0 shipped with it, so it can't change). Each app passes it from its repo's
  `RELEASE_KEYSTORE_BASE64` / `RELEASE_KEYSTORE_PASS` secrets to `flutter-apk.yml`, which refuses to publish a tag
  without them.
- versionCode must go up for each release: `flutter-apk.yml` sets it to the run number of the app's `release.yml`,
  so that file must keep its name (a renamed workflow starts counting at 1 again).
- Debug APKs (`application-debuggable`) are rejected by F-Droid.
- `archive_older: 0`: only the last 3 releases are downloaded, so there is no archive repo to publish.
- Commits carry no Claude/AI attribution lines.

## Gotchas

- `keytool` prints in French on this machine (`SHA 256:` instead of `SHA256:`); the fingerprint parsing uses
  `SHA ?256:` to handle both.
- Text files are forced to LF in `.gitattributes` so the scripts run in CI.
- If a release has several APKs, `fetch-releases.sh` takes the one with `arm64` in its name, else the first.
- Changelogs (`metadata/<package>/<locale>/changelogs/<versionCode>.txt`) don't reach the v2 index here: fdroidserver
  2.4 only attaches "What's new" to versions through `Builds:` entries, which this binary-only repo doesn't have, and
  matches the files against `CurrentVersionCode`, which it only fills in after reading them. Don't set
  `CurrentVersionCode` by hand to work around it: a release that forgets to bump it gets marked Beta, and phones
  without beta updates never get it. Pangea keeps its changelog files as history; its release notes are on GitHub.
- `fdroid update` can't extract a PNG from a vector-only launcher icon (both apps), so the landing page's app card
  uses the metadata icon (`repo/<id>/en-US/icon*.png`, copied there by `fdroid update`) before the APK's.

## Status (2026-10-08)

Pushed and deployed: the workflow runs green and Pages serves the repo (secrets and Pages are set up).

Audio Cutter's releases v1.0.0 and v1.1.0 were signed with throwaway keys (`c3356b46…`, `b0a8068d…`). They are
being replaced by v1.1.1, the first release signed with the release key `db171ead…`. Remaining steps, by the user:
add the two `RELEASE_KEYSTORE_*` secrets to `audio_player`, delete the v1.0.0 and v1.1.0 releases, push both repos
and the `v1.1.1` tag, run the publish workflow, then uninstall the app on the phone once and reinstall it from the
repo. Done when `releases.txt` lists only v1.1.1.

LLLearner was added on 2026-10-13 with its v1.0.0 release (versionCode 1, signed `db171ead…`). Not yet checked:
that the published card shows its icon and that `releases.txt` lists `com.eylexander.lllearner v1.0.0`.

Unified on 2026-10-13 (not yet run in CI): the shared `flutter-apk.yml`, and Audio Cutter's listing moved from inline
`Name`/`Summary`/`Description` to `metadata/com.eylexander.audio_cutter/en-US/` with a store icon (it had none: no PNG
mipmaps). Check on the next release of either app that its `Release APK` run calls `flutter-apk.yml` and publishes,
and on the next publish that both cards show their icon.
