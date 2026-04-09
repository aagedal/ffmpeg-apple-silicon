#!/bin/bash

# Rebuild FFmpeg linked against SVT-AV1-HDR
# Produces ffmpeg-hdr and ffprobe-hdr binaries
# Must run after 06b-svt-av1-hdr.sh has replaced the mainline SVT-AV1 libraries

source "$(dirname "$0")/../config.sh"

COMPONENT="ffmpeg-hdr"

if is_complete "${COMPONENT}"; then
    echo "[SKIP] ${COMPONENT} already built"
    exit 0
fi

echo "Rebuilding FFmpeg ${FFMPEG_VERSION} with SVT-AV1-HDR..."

cd "${SOURCE_DIR}/ffmpeg-${FFMPEG_VERSION}"

# Clean previous FFmpeg build so it links against the new SVT-AV1-HDR libraries
make clean 2>/dev/null || true

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
    --enable-libopenjpeg \
    --enable-libvmaf \
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
    --enable-encoder=libopenjpeg \
    --enable-encoder=h264_videotoolbox \
    --enable-encoder=hevc_videotoolbox \
    --enable-encoder=prores_videotoolbox \
    \
    --enable-decoder=libopenjpeg \
    --enable-decoder=libjxl \
    --enable-decoder=libfdk_aac \
    --enable-decoder=flac \
    --enable-decoder=vvc \
    --enable-decoder=theora \
    \
    --enable-filter=scale \
    --enable-filter=overlay \
    --enable-filter=whisper \
    --enable-filter=vmaf \
    --enable-filter=ssim \
    --enable-filter=psnr \
    --enable-filter=xpsnr \
    --enable-filter=msad

make ${MAKEFLAGS}

# Save as ffmpeg-hdr / ffprobe-hdr (separate from mainline build)
echo "Creating SVT-AV1-HDR standalone binaries in workspace..."
cp "ffmpeg" "${WORKSPACE}/ffmpeg-hdr"
cp "ffprobe" "${WORKSPACE}/ffprobe-hdr"
chmod +x "${WORKSPACE}/ffmpeg-hdr" "${WORKSPACE}/ffprobe-hdr"

echo ""
echo "FFmpeg (SVT-AV1-HDR) binaries created:"
echo "  ${WORKSPACE}/ffmpeg-hdr"
echo "  ${WORKSPACE}/ffprobe-hdr"

mark_complete "${COMPONENT}"
