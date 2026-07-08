#!/usr/bin/env bash
#
# Regenerate pkgs/jump-desktop/source.json from the upstream Homebrew cask.
# The cask is maintained by the vendor's release pipeline, so it is an
# always-current source of truth for {version, url, sha256}.
#
# The jump-desktop cask stores version as a two-field CSV ("9.1.9,90109") and
# builds its URL from the second field via Ruby interpolation
# (JumpDesktopMac-#{version.csv.second}.zip). The generic parser can't resolve
# that, so this variant splits the CSV and constructs the URL itself.
#
# Prints a final line of either `changed` or `unchanged` for CI to branch on.
set -euo pipefail

cd "$(dirname "$0")/.."

CASK_URL="https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/j/jump-desktop.rb"
SRC_JSON="pkgs/jump-desktop/source.json"

cask="$(curl -fsSL --retry 3 --retry-delay 2 "$CASK_URL")"

stanza() { # first `<keyword> "<value>"` line
  printf '%s\n' "$cask" \
    | grep -oE "^[[:space:]]*$1 \"[^\"]+\"" \
    | head -1 \
    | sed -E "s/^[[:space:]]*$1 \"(.*)\"$/\1/"
}

raw_version="$(stanza version)"   # e.g. "9.1.9,90109"
sha_hex="$(stanza sha256)"

# Split the CSV: display version and build number.
display_version="${raw_version%%,*}"   # 9.1.9
build="${raw_version##*,}"              # 90109

if [ -z "$display_version" ] || [ -z "$build" ] || [ -z "$sha_hex" ] || [ "$display_version" = "$build" ]; then
  echo "ERROR: could not parse a two-field CSV version + sha256 from cask" >&2
  printf '%s\n' "$cask" >&2
  exit 1
fi
if ! printf '%s' "$sha_hex" | grep -qE '^[0-9a-f]{64}$'; then
  echo "ERROR: sha256 is not a 64-char hex digest: $sha_hex" >&2
  exit 1
fi

url="https://mirror.jumpdesktop.com/downloads/jdm/JumpDesktopMac-${build}.zip"

# Homebrew publishes hex; Nix wants SRI.
sri="$(nix hash convert --hash-algo sha256 --to sri "$sha_hex")"

new="$(jq -n --arg version "$display_version" --arg url "$url" --arg sha256 "$sri" \
  '{version: $version, url: $url, sha256: $sha256}')"
old="$(cat "$SRC_JSON" 2>/dev/null || echo '{}')"

if [ "$(jq -S . <<<"$new")" = "$(jq -S . <<<"$old")" ]; then
  echo "already at version $display_version"
  echo "unchanged"
else
  printf '%s\n' "$new" >"$SRC_JSON"
  echo "updated to version $display_version"
  echo "changed"
fi
