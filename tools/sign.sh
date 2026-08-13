#!/bin/bash

# Codesign the built binaries with Developer ID + hardened runtime + timestamp
# Run after every rebuild (rebuilding replaces the signature with an ad-hoc one)

set -e

if [ -z "${SIGN_IDENTITY:-}" ]; then
    echo "ERROR: SIGN_IDENTITY must name a certificate or its SHA-1 hash." >&2
    echo "Available identities:" >&2
    security find-identity -v -p codesigning >&2
    echo "" >&2
    echo "Usage:" >&2
    echo "  SIGN_IDENTITY='<Developer ID identity>' $0 [ffmpeg-version]" >&2
    exit 2
fi

source "$(dirname "$0")/../config.sh"

IDENTITY="${SIGN_IDENTITY}"
ID_PREFIX="${SIGN_ID_PREFIX:-ffmpeg}"
VERSION="${1:-${FFMPEG_VERSION}}"

cd "$(dirname "$0")/.."

# Refuse to sign stale or non-portable binaries. Signing can make a binary
# look release-ready, so validate its version, architecture, and linkage first.
validate_binary() {
    local binary="$1"
    local name version_line

    name="$(basename "${binary}")"
    version_line="$(${binary} -version | sed -n '1p')"
    case "${version_line}" in
        "${name} version ${VERSION} "*) ;;
        *)
            echo "ERROR: ${binary} does not report exact version ${VERSION}: ${version_line}" >&2
            return 1
            ;;
    esac

    if ! file "${binary}" | grep -q "Mach-O 64-bit executable arm64"; then
        echo "ERROR: ${binary} is not a native ARM64 Mach-O executable" >&2
        return 1
    fi

    if otool -L "${binary}" | grep -Eq '/opt/homebrew|/usr/local|/compiled/'; then
        echo "ERROR: ${binary} links a non-system build dependency:" >&2
        otool -L "${binary}" | grep -E '/opt/homebrew|/usr/local|/compiled/' >&2
        return 1
    fi
}

if ! security find-identity -v -p codesigning | grep -Fq "${IDENTITY}"; then
    echo "ERROR: signing identity not found in the keychain: ${IDENTITY}" >&2
    exit 1
fi

# Sign every binary under dist/<requested-version>/<variant>/.
# Identifier becomes <prefix>.<variant>.<name>, e.g. ffmpeg.photo.ffmpeg.
found=0
for b in "dist/${VERSION}"/*/ffmpeg "dist/${VERSION}"/*/ffprobe; do
    [ -f "$b" ] || continue
    found=1
    variant="$(basename "$(dirname "$b")")"
    name="$(basename "$b")"

    validate_binary "$b"
    codesign --force --sign "${IDENTITY}" --options runtime --timestamp \
        --identifier "${ID_PREFIX}.${variant}.${name}" "$b"
    codesign --verify --strict --verbose=2 "$b"
    echo "[✓] signed and verified: $b"
done

if [ "$found" -eq 0 ]; then
    echo "No binaries found under dist/${VERSION}/ — run ./build.sh first" >&2
    exit 1
fi
