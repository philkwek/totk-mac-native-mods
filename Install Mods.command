#!/bin/bash
# Double-click this file in Finder to install the gameplay mods into your
# existing Tears of the Kingdom 1.0.0 app. It needs no game file or keys.
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
bash "$ROOT/scripts/install.sh" "$@"
status=$?
if [ "$status" -ne 0 ]; then
    echo
    read -r -p "Press Return to close this window..." _
fi
exit "$status"
