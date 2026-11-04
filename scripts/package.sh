#!/bin/sh
# Make the source/patch release archive and its checksum.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=${1:-${GITHUB_REF_NAME:-v0.1.0}}
DIST="$ROOT/dist"
NAME="totk-mac-native-mods-$VERSION"

rm -rf "$DIST"
mkdir -p "$DIST"

tar -czf "$DIST/$NAME.tar.gz" -C "$ROOT" \
    README.md LICENSE NOTICE DISCLAIMER.md CHANGELOG.md upstream.json \
    patches scripts docs tests .github .gitignore

if command -v sha256sum >/dev/null 2>&1; then
    (cd "$DIST" && sha256sum "$NAME.tar.gz" > SHA256SUMS)
else
    (cd "$DIST" && shasum -a 256 "$NAME.tar.gz" > SHA256SUMS)
fi

echo "package: $DIST/$NAME.tar.gz"
cat "$DIST/SHA256SUMS"
