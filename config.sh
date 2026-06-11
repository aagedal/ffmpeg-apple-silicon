#!/bin/bash

# FFmpeg Build Configuration
# This file contains shared configuration used by all build scripts

set -e

# Build directories
export WORKSPACE="${WORKSPACE:-$(pwd)}"
export BUILD_DIR="${WORKSPACE}/build"
export SOURCE_DIR="${WORKSPACE}/sources"
export INSTALL_DIR="${WORKSPACE}/compiled"
export BIN_DIR="${INSTALL_DIR}/bin"
export LIB_DIR="${INSTALL_DIR}/lib"
export INCLUDE_DIR="${INSTALL_DIR}/include"

# Final binaries land in dist/<ffmpeg-version>/<variant>/ (full, photo, minimal)
# so every variant keeps the plain names ffmpeg/ffprobe and versions can coexist
export DIST_DIR="${WORKSPACE}/dist"

# Create directories if they don't exist
mkdir -p "${BUILD_DIR}" "${SOURCE_DIR}" "${INSTALL_DIR}" "${BIN_DIR}" "${LIB_DIR}" "${INCLUDE_DIR}"

# Number of CPU cores for parallel builds
export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"

# Apple Silicon (ARM64) specific settings
export ARCH="arm64"
export MACOSX_DEPLOYMENT_TARGET="11.0"  # macOS 11.0 Big Sur minimum for Apple Silicon

# Compiler flags for static builds on macOS (Apple Silicon optimized)
export CFLAGS="-arch arm64 -I${INCLUDE_DIR} -O3 -fPIC -mcpu=apple-m1"
export CXXFLAGS="-arch arm64 -I${INCLUDE_DIR} -O3 -fPIC -mcpu=apple-m1"
export LDFLAGS="-arch arm64 -L${LIB_DIR}"
export PKG_CONFIG_PATH="${LIB_DIR}/pkgconfig"

# Clean up libtool .la files and -uninstalled.pc files that can cause linking issues
find "${LIB_DIR}" -name "*.la" -delete 2>/dev/null || true
find "${LIB_DIR}/pkgconfig" -name "*-uninstalled.pc" -delete 2>/dev/null || true

# macOS SDK path (for VideoToolbox support)
export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)

# Library versions
export NASM_VERSION="3.01"
export X264_VERSION="stable"
export X265_VERSION="master"
export LIBVPX_VERSION="1.16.0"
export LIBAOM_VERSION="3.14.1"
export SVT_AV1_VERSION="4.1.0"
export VVENC_VERSION="1.14.0"
export VVDEC_VERSION="3.1.0"
export LIBJXL_VERSION="0.11.2"
export OPUS_VERSION="1.6.1"
export VORBIS_VERSION="1.3.7"
export OGG_VERSION="1.3.6"
export LAME_VERSION="3.100"
export LIBASS_VERSION="0.17.4"
export FREETYPE_VERSION="2.14.3"
export FRIBIDI_VERSION="1.0.16"
export HARFBUZZ_VERSION="14.2.1"
export LIBPNG_VERSION="1.6.58"
export BROTLI_VERSION="1.2.0"
export HIGHWAY_VERSION="1.4.0"
export LIBWEBP_VERSION="1.6.0"
export FLAC_VERSION="1.5.0"
export THEORA_VERSION="1.2.0"
export LIBBLURAY_VERSION="1.4.1"
export WHISPER_VERSION="1.8.6"
export OPENJPEG_VERSION="2.5.4"
export VMAF_VERSION="3.1.0"
export FFMPEG_VERSION="8.1.1"

# Progress tracking
export PROGRESS_FILE="${WORKSPACE}/.build-progress"

# Helper function to mark component as complete
mark_complete() {
    local component="$1"
    echo "${component}" >> "${PROGRESS_FILE}"
    echo "[✓] ${component} completed"
}

# Write a README.md next to the dist binaries documenting the build:
# variant, date, license, configure flags (read from the binary itself),
# and the versions of the external libraries that variant links
write_dist_readme() {
    local out_dir="$1"
    local variant="$2"
    local bin="${out_dir}/ffmpeg"
    local conf

    [ -x "${bin}" ] || return 0

    # Guard: the dist binaries must be fully static apart from system libs.
    # A Homebrew dylib reference means a dependency silently failed to build
    # statically (it also crashes under hardened-runtime signing).
    if otool -L "${bin}" "${out_dir}/ffprobe" 2>/dev/null | grep -q "/opt/homebrew"; then
        echo "ERROR: ${out_dir} binaries link Homebrew dylibs — not static:" >&2
        otool -L "${bin}" "${out_dir}/ffprobe" | grep "/opt/homebrew" >&2
        return 1
    fi

    conf="$("${bin}" -buildconf 2>/dev/null)"
    if [ -z "${conf}" ]; then
        echo "ERROR: ${bin} failed to execute — cannot write build manifest" >&2
        return 1
    fi

    {
        echo "# FFmpeg ${FFMPEG_VERSION} — ${variant} build"
        echo ""
        echo "Static arm64 (Apple Silicon) binaries: \`ffmpeg\`, \`ffprobe\`"
        echo ""
        echo "- Built: $(date '+%Y-%m-%d %H:%M %Z') on macOS $(sw_vers -productVersion)"
        echo "- Minimum macOS: ${MACOSX_DEPLOYMENT_TARGET} (Apple Silicon only)"
        echo "- License: GPL version 3 or later (no nonfree components)"
        echo ""
        echo "## External libraries"
        echo ""

        local entry name ver desc
        for entry in \
            "libx264:${X264_VERSION:-}:H.264/AVC encoder" \
            "libx265:${X265_VERSION:-}:HEVC/H.265 encoder" \
            "libvpx:${LIBVPX_VERSION:-}:VP8/VP9" \
            "libaom:${LIBAOM_VERSION:-}:AV1 encoder/decoder" \
            "libsvtav1:${SVT_AV1_VERSION:-}:SVT-AV1 encoder" \
            "libvvenc:${VVENC_VERSION:-}:VVC/H.266 encoder" \
            "libjxl:${LIBJXL_VERSION:-}:JPEG XL (with brotli ${BROTLI_VERSION:-}, highway ${HIGHWAY_VERSION:-})" \
            "libwebp:${LIBWEBP_VERSION:-}:WebP encoder" \
            "libopus:${OPUS_VERSION:-}:Opus audio" \
            "libvorbis:${VORBIS_VERSION:-}:Vorbis audio (with libogg ${OGG_VERSION:-})" \
            "libmp3lame:${LAME_VERSION:-}:MP3 encoder" \
            "libtheora:${THEORA_VERSION:-}:Theora video" \
            "libopenjpeg:${OPENJPEG_VERSION:-}:JPEG 2000" \
            "libvmaf:${VMAF_VERSION:-}:VMAF quality metric" \
            "whisper:${WHISPER_VERSION:-}:whisper.cpp speech recognition"
        do
            name="${entry%%:*}"
            ver="$(echo "${entry}" | cut -d: -f2)"
            desc="${entry#*:*:}"
            if echo "${conf}" | grep -q -- "--enable-${name}"; then
                echo "- ${name} ${ver} — ${desc}"
            fi
        done

        echo ""
        echo "## Configure flags"
        echo ""
        echo '```'
        echo "${conf}"
        echo '```'
    } > "${out_dir}/README.md"

    echo "Build manifest written: ${out_dir}/README.md"
}

# Helper function to check if component is already built
is_complete() {
    local component="$1"
    if [ -f "${PROGRESS_FILE}" ]; then
        grep -q "^${component}$" "${PROGRESS_FILE}" 2>/dev/null
        return $?
    fi
    return 1
}

echo "Build configuration loaded"
echo "Target architecture: Apple Silicon (ARM64)"
echo "Workspace: ${WORKSPACE}"
echo "Install directory: ${INSTALL_DIR}"
echo "CPU cores: $(sysctl -n hw.ncpu)"
