#!/bin/bash

# Build VVdeC (VVC decoder)

source "$(dirname "$0")/../config.sh"

COMPONENT="vvdec"

if is_complete "${COMPONENT}"; then
    echo "[SKIP] ${COMPONENT} already built"
    exit 0
fi

echo "Building VVdeC (from git master)..."

cd "${SOURCE_DIR}"

# Use git clone for more reliable builds
if [ ! -d "vvdec" ]; then
    git clone --depth 1 https://github.com/fraunhoferhhi/vvdec.git
fi

mkdir -p "vvdec/build"
cd "vvdec/build"

cmake \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DBUILD_SHARED_LIBS=OFF \
    ..

make ${MAKEFLAGS}
make install

mark_complete "${COMPONENT}"
