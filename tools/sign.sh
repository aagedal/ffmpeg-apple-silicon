#!/bin/bash

# Codesign the built binaries with Developer ID + hardened runtime + timestamp
# Run after every rebuild (rebuilding replaces the signature with an ad-hoc one)

set -e

IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Truls Aagedal (3R5QGG9DW6)}"
ID_PREFIX="${SIGN_ID_PREFIX:-no.aagedal}"

cd "$(dirname "$0")/.."

# Sign every binary under dist/<version>/<variant>/
# Identifier becomes <prefix>.<variant>.<name>, e.g. no.aagedal.photo.ffmpeg
found=0
for b in dist/*/*/ffmpeg dist/*/*/ffprobe; do
    [ -f "$b" ] || continue
    found=1
    variant="$(basename "$(dirname "$b")")"
    name="$(basename "$b")"
    codesign --force --sign "${IDENTITY}" --options runtime --timestamp \
        --identifier "${ID_PREFIX}.${variant}.${name}" "$b"
    codesign --verify --strict "$b"
    echo "[✓] signed and verified: $b"
done

if [ "$found" -eq 0 ]; then
    echo "No binaries found under dist/ — run ./build.sh first"
    exit 1
fi
