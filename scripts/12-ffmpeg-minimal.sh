#!/bin/bash

# Build FFmpeg - MINIMAL STATIC VERSION (No Homebrew dependencies)
# Disables problematic libraries that link to Homebrew: JPEG XL, Vorbis, libass

source "$(dirname "$0")/../config.sh"

COMPONENT="ffmpeg-minimal"

echo "Building FFmpeg ${FFMPEG_VERSION} (Minimal Static)..."

cd "${SOURCE_DIR}"

if [ ! -d "ffmpeg-${FFMPEG_VERSION}" ]; then
    curl -L -O "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz"
    tar xf "ffmpeg-${FFMPEG_VERSION}.tar.xz"
fi

cd "ffmpeg-${FFMPEG_VERSION}"

# Add bin directory to PATH for nasm
export PATH="${BIN_DIR}:${PATH}"

./configure \
    --prefix="${INSTALL_DIR}" \
    --arch=arm64 \
    --target-os=darwin \
    --pkg-config-flags="--static" \
    --extra-cflags="${CFLAGS}" \
    --extra-cxxflags="${CXXFLAGS}" \
    --extra-ldflags="${LDFLAGS}" \
    --extra-libs="-lpthread -lm -lz" \
    --enable-static \
    --disable-shared \
    --enable-gpl \
    --enable-nonfree \
    --enable-version3 \
    --disable-debug \
    --disable-doc \
    --enable-pthreads \
    --enable-runtime-cpudetect \
    --enable-neon \
    \
    --disable-libxcb \
    --disable-libxcb-shm \
    --disable-libxcb-xfixes \
    --disable-libxcb-shape \
    --disable-sdl2 \
    --disable-libass \
    --disable-xlib \
    --disable-libjxl \
    --disable-libvorbis \
    \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libaom \
    --enable-libsvtav1 \
    --enable-libvvenc \
    --enable-libopus \
    --enable-libmp3lame \
    --enable-libfdk-aac \
    \
    --enable-videotoolbox \
    --enable-audiotoolbox \
    \
    --enable-encoder=libx264 \
    --enable-encoder=libx265 \
    --enable-encoder=libvpx_vp8 \
    --enable-encoder=libvpx_vp9 \
    --enable-encoder=libaom_av1 \
    --enable-encoder=libsvtav1 \
    --enable-encoder=libvvenc \
    --enable-encoder=libopus \
    --enable-encoder=libmp3lame \
    --enable-encoder=libfdk_aac \
    --enable-encoder=h264_videotoolbox \
    --enable-encoder=hevc_videotoolbox \
    --enable-encoder=prores_videotoolbox \
    \
    --enable-decoder=libfdk_aac \
    \
    --enable-filter=scale \
    --enable-filter=overlay

make ${MAKEFLAGS}
make install

# Create a standalone binary by copying to workspace
echo "Creating standalone binaries in workspace..."
cp "${BIN_DIR}/ffmpeg" "${WORKSPACE}/ffmpeg"
cp "${BIN_DIR}/ffprobe" "${WORKSPACE}/ffprobe"
chmod +x "${WORKSPACE}/ffmpeg" "${WORKSPACE}/ffprobe"

echo ""
echo "FFmpeg binaries created:"
echo "  ${WORKSPACE}/ffmpeg"
echo "  ${WORKSPACE}/ffprobe"

mark_complete "${COMPONENT}"
