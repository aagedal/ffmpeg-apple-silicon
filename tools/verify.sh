#!/bin/bash

# Verify the full FFmpeg build and fail if required features are missing.

set -e

source "$(dirname "$0")/../config.sh"

FULL_DIR="${OUTPUT_DIR}/${FFMPEG_VERSION}/full"
FFMPEG_BIN="${FULL_DIR}/ffmpeg"
FFPROBE_BIN="${FULL_DIR}/ffprobe"
FAILURES=0

pass() {
    echo "✅ $1"
}

fail() {
    echo "❌ $1" >&2
    FAILURES=$((FAILURES + 1))
}

has_entry() {
    local output="$1"
    local name="$2"
    echo "${output}" | grep -Eq "[[:space:]]${name}[[:space:]]"
}

echo "=========================================="
echo "FFmpeg ${FFMPEG_VERSION} Build Verification"
echo "=========================================="
echo ""

if [ ! -x "${FFMPEG_BIN}" ] || [ ! -x "${FFPROBE_BIN}" ]; then
    echo "❌ Binaries not found in ${FULL_DIR}" >&2
    echo "   Run ./build.sh first" >&2
    exit 1
fi

for binary in "${FFMPEG_BIN}" "${FFPROBE_BIN}"; do
    binary_name="$(basename "${binary}")"
    version_line="$(${binary} -version | sed -n '1p')"

    case "${version_line}" in
        "${binary_name} version ${FFMPEG_VERSION} "*)
            pass "${binary_name} reports exact version ${FFMPEG_VERSION}"
            ;;
        *)
            fail "${binary_name} version mismatch: ${version_line}"
            ;;
    esac

    if file "${binary}" | grep -q "Mach-O 64-bit executable arm64"; then
        pass "${binary_name} is a native ARM64 executable"
    else
        fail "${binary_name} is not a native ARM64 executable"
    fi

    if otool -L "${binary}" | grep -Eq '/opt/homebrew|/usr/local|/compiled/'; then
        fail "${binary_name} links to a non-system build dependency"
        otool -L "${binary}" | grep -E '/opt/homebrew|/usr/local|/compiled/' >&2
    else
        pass "${binary_name} has no Homebrew or build-tree library references"
    fi
done

ENCODERS="$(${FFMPEG_BIN} -hide_banner -encoders 2>/dev/null)"
FILTERS="$(${FFMPEG_BIN} -hide_banner -filters 2>/dev/null)"
HWACCELS="$(${FFMPEG_BIN} -hide_banner -hwaccels 2>/dev/null)"

for encoder in \
    libx264 libx265 libvpx libvpx-vp9 libaom-av1 libsvtav1 libvvenc \
    libjxl libwebp libopenjpeg libmp3lame libopus libvorbis; do
    if has_entry "${ENCODERS}" "${encoder}"; then
        pass "Encoder available: ${encoder}"
    else
        fail "Missing required encoder: ${encoder}"
    fi
done

for filter in ass subtitles whisper libvmaf; do
    if has_entry "${FILTERS}" "${filter}"; then
        pass "Filter available: ${filter}"
    else
        fail "Missing required filter: ${filter}"
    fi
done

if echo "${HWACCELS}" | grep -qx 'videotoolbox'; then
    pass "VideoToolbox hardware acceleration is available"
else
    fail "VideoToolbox hardware acceleration is missing"
fi

echo ""
if [ "${FAILURES}" -ne 0 ]; then
    echo "Verification failed with ${FAILURES} error(s)." >&2
    exit 1
fi

echo "All FFmpeg ${FFMPEG_VERSION} verification checks passed."
