#!/usr/bin/env bash
# Downloads the APKs of the last $KEEP GitHub releases of every app into repo/.
# The GitHub repository is the SourceCode: of metadata/<package>.yml. Drafts and pre-releases are skipped;
# when a release has several APKs, the arm64 one wins, else the first.
#   scripts/fetch-releases.sh          download, and print one "package tag asset-id url" line per APK
#   scripts/fetch-releases.sh --list   only print the lines
# Needs curl and jq. Set GH_TOKEN to avoid the API rate limit (or to read private repos).
set -euo pipefail

KEEP=${KEEP:-3}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
auth=()
[ -z "${GH_TOKEN:-}" ] || auth=(-H "Authorization: Bearer $GH_TOKEN")

for meta in "$ROOT"/metadata/*.yml; do
  pkg=$(basename "$meta" .yml)
  src=$(sed -n 's/^SourceCode: *//p' "$meta" | tr -d '\r')
  case "$src" in
    https://github.com/*/*) ;;
    *) echo "$pkg: SourceCode '$src' is not a GitHub repository" >&2; exit 1 ;;
  esac
  slug=${src#https://github.com/}; slug=${slug%/}; slug=${slug%.git}

  releases=$(curl -fsSL "${auth[@]}" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$slug/releases?per_page=30" |
    jq -r --argjson keep "$KEEP" '
      [ .[] | select((.draft or .prerelease) | not)
        | {tag: .tag_name, apks: [.assets[] | select(.name | endswith(".apk"))]}
        | select(.apks | length > 0) ][:$keep][]
      | .tag as $tag | (.apks | map(select(.name | test("arm64"))) + .)[0]
      | "\($tag) \(.id) \(.browser_download_url)"')
  [ -n "$releases" ] || { echo "$pkg: no release with an APK in $slug" >&2; exit 1; }

  while read -r tag id url; do
    echo "$pkg $tag $id $url"
    [ "${1:-}" = --list ] || curl -fsSL -o "$ROOT/repo/${pkg}_${tag}.apk" "$url"
  done <<<"$releases"
done
