#!/bin/sh
# Build a macOS app from the patched upstream source and the user's own game.
# The app contains the user's game data; it must not be shared.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM_DIR=${UPSTREAM_DIR:-"$ROOT/.upstream"}
ROM=${TOTK_ROM:-}
KEYS=${TOTK_KEYS:-}
OUT=${TOTK_OUT:-"$ROOT/.build/Tears of the Kingdom.app"}
WORK=${TOTK_WORK:-"$ROOT/.build/work"}

usage() {
    echo "usage: $0 --rom <game.xci|game.nsp> --keys <prod.keys> [--out <app>] [--work <folder>]" >&2
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --rom) ROM=${2:-}; shift 2 ;;
        --keys) KEYS=${2:-}; shift 2 ;;
        --out) OUT=${2:-}; shift 2 ;;
        --work) WORK=${2:-}; shift 2 ;;
        -h|--help) usage ;;
        *) echo "build: unknown argument: $1" >&2; usage ;;
    esac
done

[ -n "$ROM" ] || { echo "build: --rom is required (or set TOTK_ROM)" >&2; usage; }
[ -n "$KEYS" ] || { echo "build: --keys is required (or set TOTK_KEYS)" >&2; usage; }
[ -f "$ROM" ] || { echo "build: game file not found: $ROM" >&2; exit 1; }
[ -f "$KEYS" ] || { echo "build: keys file not found: $KEYS" >&2; exit 1; }
[ -d "$UPSTREAM_DIR/.git" ] || { echo "build: run scripts/bootstrap.sh and scripts/apply.sh first" >&2; exit 1; }
grep -q "unlimited arrows" "$UPSTREAM_DIR/games/totk/runtime/game_patches.c" || {
    echo "build: the upstream checkout is not patched; run scripts/apply.sh" >&2
    exit 1
}

mkdir -p "$(dirname "$OUT")" "$WORK"
echo "build: app  $OUT"
echo "build: work $WORK"
python3 "$UPSTREAM_DIR/build_app.py" "$ROM" -k "$KEYS" --platform macos -o "$OUT" --work "$WORK"
echo "build: done: $OUT"
echo "build: this app contains your own game data and keys-derived files. Do not share it."
