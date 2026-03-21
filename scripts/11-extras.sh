#!/bin/bash

# Build extra useful libraries (libass for subtitles, fdk-aac for AAC)

source "$(dirname "$0")/../config.sh"

COMPONENT="extras"

if is_complete "${COMPONENT}"; then
    echo "[SKIP] ${COMPONENT} already built"
    exit 0
fi

echo "Building extra libraries..."

cd "${SOURCE_DIR}"

# Build libpng (required for freetype)
echo "  Building libpng ${LIBPNG_VERSION}..."
if [ ! -d "libpng-${LIBPNG_VERSION}" ]; then
    curl -L -O "https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.xz"
    tar xf "libpng-${LIBPNG_VERSION}.tar.xz"
    
    cd "libpng-${LIBPNG_VERSION}"
    ./configure \
        --prefix="${INSTALL_DIR}" \
        --disable-shared \
        --enable-static
    
    make ${MAKEFLAGS}
    make install
    cd "${SOURCE_DIR}"
fi

# Build freetype (required for libass)
echo "  Building freetype ${FREETYPE_VERSION}..."
if [ ! -d "freetype-${FREETYPE_VERSION}" ]; then
    curl -L -O "https://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.xz"
    tar xf "freetype-${FREETYPE_VERSION}.tar.xz"
    
    cd "freetype-${FREETYPE_VERSION}"
    ./configure \
        --prefix="${INSTALL_DIR}" \
        --disable-shared \
        --enable-static \
        --without-harfbuzz
    
    make ${MAKEFLAGS}
    make install
    cd "${SOURCE_DIR}"
fi

# Build fribidi (required for libass)
echo "  Building fribidi ${FRIBIDI_VERSION}..."
if [ ! -d "fribidi-${FRIBIDI_VERSION}" ]; then
    curl -L -O "https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz"
    tar xf "fribidi-${FRIBIDI_VERSION}.tar.xz"
    
    cd "fribidi-${FRIBIDI_VERSION}"
    ./configure \
        --prefix="${INSTALL_DIR}" \
        --disable-shared \
        --enable-static
    
    make ${MAKEFLAGS}
    make install
    cd "${SOURCE_DIR}"
fi

# Harfbuzz is optional - libass works without it for basic subtitle rendering
# Skipping harfbuzz to avoid build complexity

# Build libass (subtitle rendering)
echo "  Building libass ${LIBASS_VERSION}..."
if [ ! -d "libass-${LIBASS_VERSION}" ]; then
    curl -L -O "https://github.com/libass/libass/releases/download/${LIBASS_VERSION}/libass-${LIBASS_VERSION}.tar.xz"
    tar xf "libass-${LIBASS_VERSION}.tar.xz"
    
    cd "libass-${LIBASS_VERSION}"
    ./configure \
        --prefix="${INSTALL_DIR}" \
        --disable-shared \
        --enable-static
    
    make ${MAKEFLAGS}
    make install
    cd "${SOURCE_DIR}"
fi

# Build fdk-aac (high-quality AAC encoder)
echo "  Building fdk-aac ${FDK_AAC_VERSION}..."
if [ ! -d "fdk-aac-${FDK_AAC_VERSION}" ]; then
    curl -L -O "https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-${FDK_AAC_VERSION}.tar.gz"
    tar xf "fdk-aac-${FDK_AAC_VERSION}.tar.gz"
    
    cd "fdk-aac-${FDK_AAC_VERSION}"
    ./configure \
        --prefix="${INSTALL_DIR}" \
        --disable-shared \
        --enable-static
    
    make ${MAKEFLAGS}
    make install
    cd "${SOURCE_DIR}"
fi

mark_complete "${COMPONENT}"
