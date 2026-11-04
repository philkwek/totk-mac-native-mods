#!/bin/sh
# Apply patches/series to .upstream/. --check only tests the series; --reset
# returns .upstream to its pinned commit first.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM_DIR=${UPSTREAM_DIR:-"$ROOT/.upstream"}
SERIES="$ROOT/patches/series"
CHECK=0
RESET=0

for arg in "$@"; do
    case "$arg" in
        --check) CHECK=1 ;;
        --reset) RESET=1 ;;
        *) echo "usage: $0 [--check] [--reset]" >&2; exit 2 ;;
    esac
done

[ -d "$UPSTREAM_DIR/.git" ] || { echo "apply: run scripts/bootstrap.sh first" >&2; exit 1; }
[ -f "$SERIES" ] || { echo "apply: missing $SERIES" >&2; exit 1; }

if [ "$RESET" = 1 ]; then
    git -C "$UPSTREAM_DIR" reset --hard -q HEAD
    git -C "$UPSTREAM_DIR" clean -fdq
    if [ "$CHECK" = 0 ]; then
        echo "apply: reset to the pinned commit in $UPSTREAM_DIR"
        exit 0
    fi
fi

count=0
while IFS= read -r patch || [ -n "$patch" ]; do
    case "$patch" in
        ''|\#*) continue ;;
    esac
    file="$ROOT/patches/$patch"
    [ -f "$file" ] || { echo "apply: missing patch $file" >&2; exit 1; }
    if [ "$CHECK" = 1 ]; then
        git -C "$UPSTREAM_DIR" apply --check "$file"
        echo "apply: OK  $patch"
    else
        git -C "$UPSTREAM_DIR" apply "$file"
        echo "apply: applied  $patch"
    fi
    count=$((count + 1))
done < "$SERIES"

[ "$count" -gt 0 ] || { echo "apply: patches/series is empty" >&2; exit 1; }
[ "$CHECK" = 1 ] || echo "apply: $count patch(es) applied in $UPSTREAM_DIR"
