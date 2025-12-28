#!/bin/bash

# Build x265 (H.265/HEVC encoder)

source "$(dirname "$0")/../config.sh"

COMPONENT="x265"

if is_complete "${COMPONENT}"; then
    echo "[SKIP] ${COMPONENT} already built"
    exit 0
fi

echo "Building x265 ${X265_VERSION}..."

cd "${SOURCE_DIR}"

# Clone from git if not exists (more reliable than tarballs for newer versions)
if [ ! -d "x265" ]; then
    git clone --depth 1 --branch ${X265_VERSION} https://bitbucket.org/multicoreware/x265_git.git x265
fi

cd x265

# Create build directory
mkdir -p build
cd build

cmake \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF \
    -DHIGH_BIT_DEPTH=ON \
    -DENABLE_ASSEMBLY=ON \
    ../source

make ${MAKEFLAGS}
make install

mark_complete "${COMPONENT}"
