#!/bin/sh
# Move the overlay to a newer upstream commit, re-apply the patch series with a
# 3-way merge, regenerate the patch, and verify it. Conflicts are left in
# .upstream for the maintainer to resolve.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM_DIR=${UPSTREAM_DIR:-"$ROOT/.upstream"}
NEW_COMMIT=${1:-}
CONFIG="$ROOT/upstream.json"
PATCH="$ROOT/patches/0001-gameplay-switches.patch"

[ -d "$UPSTREAM_DIR/.git" ] || "$ROOT/scripts/bootstrap.sh"

if [ -n "$NEW_COMMIT" ]; then
    python3 - "$CONFIG" "$NEW_COMMIT" <<'PY'
import json, sys
path, commit = sys.argv[1], sys.argv[2]
data = json.load(open(path))
data["commit"] = commit
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
fi

"$ROOT/scripts/bootstrap.sh"
echo "sync-upstream: applying the current series with a 3-way merge"
if ! git -C "$UPSTREAM_DIR" apply --3way "$PATCH"; then
    echo "sync-upstream: conflicts; resolve them in $UPSTREAM_DIR, then run:" >&2
    echo "  git -C \"$UPSTREAM_DIR\" diff HEAD > \"$PATCH\"" >&2
    echo "  $ROOT/scripts/verify.sh" >&2
    exit 1
fi
git -C "$UPSTREAM_DIR" diff HEAD > "$PATCH"
"$ROOT/scripts/verify.sh"
echo "sync-upstream: patch regenerated and verified"
