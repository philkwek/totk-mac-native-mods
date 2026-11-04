#!/bin/sh
# Source-level check for the one-click installer. No macOS tools are needed.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

bash -n "$ROOT/scripts/install.sh"
bash -n "$ROOT/Install Mods.command"
bash "$ROOT/scripts/install.sh" --help >/dev/null

echo "test_installer: OK"
