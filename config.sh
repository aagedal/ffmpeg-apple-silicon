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
export LIBVPX_VERSION="1.14.1"
export LIBAOM_VERSION="3.13.1"
export SVT_AV1_VERSION="3.1.2"
export VVENC_VERSION="1.13.1"
export VVDEC_VERSION="3.1.0"
export LIBJXL_VERSION="0.11.1"
export OPUS_VERSION="1.5.2"
export VORBIS_VERSION="1.3.7"
export OGG_VERSION="1.3.5"
export LAME_VERSION="3.100"
export FDK_AAC_VERSION="2.0.3"
export LIBASS_VERSION="0.17.3"
export FREETYPE_VERSION="2.13.3"
export FRIBIDI_VERSION="1.0.15"
export HARFBUZZ_VERSION="9.0.0"
export LIBPNG_VERSION="1.6.44"
export BROTLI_VERSION="1.1.0"
export HIGHWAY_VERSION="1.2.0"
export LIBWEBP_VERSION="1.6.0"
export FLAC_VERSION="1.5.0"
export THEORA_VERSION="1.2.0"
export LIBBLURAY_VERSION="1.4.0"
export WHISPER_VERSION="1.8.2"
export FFMPEG_VERSION="8.0.1"

# Progress tracking
export PROGRESS_FILE="${WORKSPACE}/.build-progress"

# Helper function to mark component as complete
mark_complete() {
    local component="$1"
    echo "${component}" >> "${PROGRESS_FILE}"
    echo "[✓] ${component} completed"
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
