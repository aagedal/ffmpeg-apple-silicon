#!/bin/bash

# Build audio codecs (Opus, Vorbis, LAME MP3)

source "$(dirname "$0")/../config.sh"

COMPONENT="audio-codecs"

if is_complete "${COMPONENT}"; then
    echo "[SKIP] ${COMPONENT} already built"
    exit 0
fi

echo "Building audio codecs..."

cd "${SOURCE_DIR}"

# Build libogg (required for Vorbis and Opus)
echo "  Building libogg ${OGG_VERSION}..."
if [ ! -d "libogg-${OGG_VERSION}" ]; then
    curl -L -O "https://downloads.xiph.org/releases/ogg/libogg-${OGG_VERSION}.tar.gz"
    tar xf "libogg-${OGG_VERSION}.tar.gz"
    
    cd "libogg-${OGG_VERSION}"
    ./configure \
        --prefix="${INSTALL_DIR}" \
        --disable-shared \
        --enable-static
    
    make ${MAKEFLAGS}
    make install
    cd "${SOURCE_DIR}"
fi

# Build libvorbis
echo "  Building libvorbis ${VORBIS_VERSION}..."
if [ ! -d "libvorbis-${VORBIS_VERSION}" ]; then
    curl -L -O "https://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS_VERSION}.tar.gz"
    tar xf "libvorbis-${VORBIS_VERSION}.tar.gz"
    
    cd "libvorbis-${VORBIS_VERSION}"
    autoreconf -fiv
    ./configure \
        --prefix="${INSTALL_DIR}" \
        --disable-shared \
        --enable-static \
        --disable-dependency-tracking

    # Fix libtool for Apple Silicon
    sed -i '' 's/-force_cpusubtype_ALL//g' libtool

    make ${MAKEFLAGS} -k || true
    make install || true
    cd "${SOURCE_DIR}"
fi

# Build opus
echo "  Building opus ${OPUS_VERSION}..."
if [ ! -d "opus-${OPUS_VERSION}" ]; then
    curl -L -O "https://downloads.xiph.org/releases/opus/opus-${OPUS_VERSION}.tar.gz"
    tar xf "opus-${OPUS_VERSION}.tar.gz"
    
    cd "opus-${OPUS_VERSION}"
    ./configure \
        --prefix="${INSTALL_DIR}" \
        --disable-shared \
        --enable-static
    
    make ${MAKEFLAGS}
    make install
    cd "${SOURCE_DIR}"
fi

# Build LAME MP3
echo "  Building LAME ${LAME_VERSION}..."
if [ ! -d "lame-${LAME_VERSION}" ]; then
    curl -L -O "https://downloads.sourceforge.net/project/lame/lame/${LAME_VERSION}/lame-${LAME_VERSION}.tar.gz"
    tar xf "lame-${LAME_VERSION}.tar.gz"
    
    cd "lame-${LAME_VERSION}"
    ./configure \
        --prefix="${INSTALL_DIR}" \
        --disable-shared \
        --enable-static \
        --disable-frontend
    
    make ${MAKEFLAGS}
    make install
    cd "${SOURCE_DIR}"
fi

mark_complete "${COMPONENT}"
