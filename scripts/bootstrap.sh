#!/bin/sh
# Fetch the pinned MacNativeGames commit into .upstream/.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM_DIR=${UPSTREAM_DIR:-"$ROOT/.upstream"}
CONFIG="$ROOT/upstream.json"

command -v git >/dev/null 2>&1 || { echo "bootstrap: git is required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "bootstrap: python3 is required" >&2; exit 1; }

UPSTREAM_URL=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["upstream"])' "$CONFIG")
UPSTREAM_COMMIT=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["commit"])' "$CONFIG")

if [ ! -d "$UPSTREAM_DIR/.git" ]; then
    mkdir -p "$UPSTREAM_DIR"
    git -C "$UPSTREAM_DIR" init -q
    git -C "$UPSTREAM_DIR" remote add origin "$UPSTREAM_URL"
else
    git -C "$UPSTREAM_DIR" remote set-url origin "$UPSTREAM_URL"
fi

echo "bootstrap: fetching $UPSTREAM_URL @ $UPSTREAM_COMMIT"
if ! git -C "$UPSTREAM_DIR" fetch --depth 1 origin "$UPSTREAM_COMMIT"; then
    echo "bootstrap: fetching the full history instead (the server refused a commit-only fetch)"
    git -C "$UPSTREAM_DIR" fetch origin
fi
git -C "$UPSTREAM_DIR" checkout -q --detach "$UPSTREAM_COMMIT"
git -C "$UPSTREAM_DIR" reset --hard -q HEAD
git -C "$UPSTREAM_DIR" clean -fdq
echo "bootstrap: ready in $UPSTREAM_DIR"
