#!/bin/bash

# Build VVenC (VVC encoder)

source "$(dirname "$0")/../config.sh"

COMPONENT="vvenc"

if is_complete "${COMPONENT}"; then
    echo "[SKIP] ${COMPONENT} already built"
    exit 0
fi

echo "Building VVenC (from git master)..."

cd "${SOURCE_DIR}"

# Use git clone for more reliable builds
if [ ! -d "vvenc" ]; then
    git clone --depth 1 https://github.com/fraunhoferhhi/vvenc.git
fi

mkdir -p "vvenc/build"
cd "vvenc/build"

cmake \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DBUILD_SHARED_LIBS=OFF \
    -DVVENC_ENABLE_LINK_TIME_OPT=OFF \
    -DVVENC_INSTALL_FULLFEATURE_APP=OFF \
    -DVVENC_INSTALL_SIMPLE_APP=OFF \
    ..

make ${MAKEFLAGS}
make install

mark_complete "${COMPONENT}"
