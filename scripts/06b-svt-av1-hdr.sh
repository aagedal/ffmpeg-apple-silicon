#!/bin/bash

# Build SVT-AV1-HDR (drop-in replacement for SVT-AV1 with HDR/psychovisual enhancements)
# This overwrites the mainline SVT-AV1 libraries so FFmpeg can be rebuilt against it

source "$(dirname "$0")/../config.sh"

COMPONENT="svt-av1-hdr"

if is_complete "${COMPONENT}"; then
    echo "[SKIP] ${COMPONENT} already built"
    exit 0
fi

echo "Building SVT-AV1-HDR ${SVT_AV1_HDR_VERSION}..."

cd "${SOURCE_DIR}"

if [ ! -d "svt-av1-hdr-${SVT_AV1_HDR_VERSION}" ]; then
    curl -L -o "svt-av1-hdr-${SVT_AV1_HDR_VERSION}.tar.gz" \
        "https://github.com/juliobbv-p/svt-av1-hdr/archive/refs/tags/v${SVT_AV1_HDR_VERSION}.tar.gz"
    tar xf "svt-av1-hdr-${SVT_AV1_HDR_VERSION}.tar.gz"
fi

mkdir -p "svt-av1-hdr-${SVT_AV1_HDR_VERSION}/build"
cd "svt-av1-hdr-${SVT_AV1_HDR_VERSION}/build"

cmake \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_APPS=OFF \
    -DBUILD_DEC=ON \
    ..

make ${MAKEFLAGS}
make install

mark_complete "${COMPONENT}"
