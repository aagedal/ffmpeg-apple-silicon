#!/bin/bash

# Build FFmpeg with all codecs and macOS VideoToolbox/AudioToolbox support

source "$(dirname "$0")/../config.sh"

COMPONENT="ffmpeg"

if is_complete "${COMPONENT}"; then
    echo "[SKIP] ${COMPONENT} already built"
    exit 0
fi

echo "Building FFmpeg ${FFMPEG_VERSION}..."

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
    --enable-pic \
    \
    --disable-libxcb \
    --disable-libxcb-shm \
    --disable-libxcb-xfixes \
    --disable-libxcb-shape \
    --disable-sdl2 \
    --disable-libass \
    --disable-xlib \
    --disable-libharfbuzz \
    --disable-libharfbuzz \
    --disable-libfontconfig \
    --disable-libfreetype \
    --disable-libfribidi \
    \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libaom \
    --enable-libsvtav1 \
    --enable-libvvenc \
    --enable-libjxl \
    --enable-libwebp \
    --enable-libopus \
    --enable-libvorbis \
    --enable-libmp3lame \
    --enable-libfdk-aac \
    --enable-libtheora \
    --enable-whisper \
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
    --enable-encoder=libjxl \
    --enable-encoder=libwebp \
    --enable-encoder=libwebp_anim \
    --enable-encoder=libopus \
    --enable-encoder=libvorbis \
    --enable-encoder=libmp3lame \
    --enable-encoder=libfdk_aac \
    --enable-encoder=flac \
    --enable-encoder=libtheora \
    --enable-encoder=h264_videotoolbox \
    --enable-encoder=hevc_videotoolbox \
    --enable-encoder=prores_videotoolbox \
    \
    --enable-decoder=libjxl \
    --enable-decoder=libfdk_aac \
    --enable-decoder=flac \
    --enable-decoder=vvc \
    --enable-decoder=theora \
    \
    --enable-filter=scale \
    --enable-filter=overlay \
    --enable-filter=whisper

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
