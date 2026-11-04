#!/bin/sh
# Verify the overlay against the pinned upstream checkout. No game data or keys
# are needed: this checks that the patch series applies and that the patched
# source reserves the expected sites.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM_DIR=${UPSTREAM_DIR:-"$ROOT/.upstream"}

"$ROOT/scripts/bootstrap.sh"
"$ROOT/scripts/apply.sh" --reset
"$ROOT/scripts/apply.sh" --check
"$ROOT/scripts/apply.sh"

python3 "$ROOT/tests/test_patch_series.py"
python3 "$UPSTREAM_DIR/tests/test_patch_sites.py"
"$ROOT/scripts/check-repo.sh"

echo "verify: OK"
