#!/bin/sh
# Reject game data, keys, saves, built apps, and oversized files in the repo.
# Local build dependencies (.upstream, .build, dist) are ignored.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

status=0
prune='-path ./.git -prune -o -path ./.upstream -prune -o -path ./.build -prune -o -path ./dist -prune -o'

if [ -e TOTK_build ]; then
    echo "check-repo: forbidden directory: TOTK_build" >&2
    status=1
fi

bad_dirs=$(eval "find . $prune -type d \\( -name '*.app' -o -name 'profile-*' -o -name 'shots-*' -o -name 'extracted' -o -name 'rewritten' \\) -print")
if [ -n "$bad_dirs" ]; then
    echo "check-repo: forbidden directories:" >&2
    echo "$bad_dirs" >&2
    status=1
fi

bad_files=$(eval "find . $prune -type f \\( \
    -name '*.xci' -o -name '*.nsp' -o -name '*.nca' -o -name '*.nsz' -o -name '*.xcz' \
    -o -name '*.keys' -o -name '*.sav' -o -name '*.bfttf' -o -name '*.nso' -o -name '*.elf' \
    -o -name '*.bin' -o -name 'prod.keys' \\) -print")
if [ -n "$bad_files" ]; then
    echo "check-repo: forbidden files:" >&2
    echo "$bad_files" >&2
    status=1
fi

big_files=$(eval "find . $prune -type f -size +25M -print")
if [ -n "$big_files" ]; then
    echo "check-repo: files larger than 25 MB:" >&2
    echo "$big_files" >&2
    status=1
fi

if [ "$status" = 0 ]; then
    echo "check-repo: OK"
fi
exit "$status"
