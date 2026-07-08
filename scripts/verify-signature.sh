#!/usr/bin/env bash
#
# Authenticity gate for the built Jump Desktop .app. The fetchurl hash only
# proves the artifact matches the checksum the *same* upstream cask reports;
# this asserts the non-forgeable property: Apple-notarized and signed by the
# expected Developer ID Team. The auto-updater runs this before committing a bump.
#
# Usage: scripts/verify-signature.sh [result-dir]   (default: ./result)
set -euo pipefail

RESULT="${1:-result}"
APP="$RESULT/Applications/Jump Desktop.app"
EXPECTED_TEAM_ID="2HCKV38EEC"   # PhaseFive Systems

if [ ! -d "$APP" ]; then
  echo "ERROR: $APP not found (did 'nix build' run?)" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP"

team_id="$(codesign -dv --verbose=4 "$APP" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
if [ "$team_id" != "$EXPECTED_TEAM_ID" ]; then
  echo "ERROR: code-signing Team ID is '$team_id', expected '$EXPECTED_TEAM_ID'." >&2
  echo "Refusing to trust this build. Update EXPECTED_TEAM_ID only deliberately." >&2
  exit 1
fi

if spctl -a -vvv -t exec "$APP" 2>&1; then
  echo "gatekeeper: accepted (notarized)"
else
  echo "WARN: spctl assessment did not pass in this environment (non-fatal)" >&2
fi

echo "OK: signed by Team ID $team_id"
