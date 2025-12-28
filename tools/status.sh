#!/bin/bash

# Show current build status

source "$(dirname "$0")/../config.sh"

echo "=========================================="
echo "FFmpeg Build Status"
echo "=========================================="
echo ""

BUILD_COMPONENTS=(
    "nasm:NASM assembler"
    "x264:x264 (H.264)"
    "x265:x265 (HEVC)"
    "libvpx:libvpx (VP8/VP9)"
    "libaom:libaom (AV1)"
    "svt-av1:SVT-AV1"
    "vvenc:VVenC (VVC encoder)"
    "vvdec:VVdeC (VVC decoder)"
    "libjxl:libjxl (JPEG XL)"
    "audio-codecs:Audio codecs (Opus, Vorbis, LAME)"
    "extras:Extra libraries (libass, FDK-AAC)"
    "ffmpeg:FFmpeg"
)

TOTAL=${#BUILD_COMPONENTS[@]}
COMPLETED=0

for item in "${BUILD_COMPONENTS[@]}"; do
    component="${item%%:*}"
    description="${item#*:}"
    
    if is_complete "$component" 2>/dev/null; then
        echo "[✓] $description"
        ((COMPLETED++))
    else
        echo "[ ] $description"
    fi
done

echo ""
echo "=========================================="
echo "Progress: ${COMPLETED}/${TOTAL} components built"
echo "=========================================="

if [ $COMPLETED -eq $TOTAL ]; then
    echo ""
    echo "Build complete! 🎉"
    echo ""
    if [ -f "${WORKSPACE}/ffmpeg" ]; then
        echo "FFmpeg binary: ${WORKSPACE}/ffmpeg"
        echo "FFprobe binary: ${WORKSPACE}/ffprobe"
        echo ""
        echo "Quick test:"
        echo "  ./ffmpeg -version"
        echo "  ./ffmpeg -codecs | grep jxl"
    fi
elif [ $COMPLETED -gt 0 ]; then
    echo ""
    echo "Build in progress. Run './build.sh' to continue."
else
    echo ""
    echo "Build not started. Run './build.sh' to begin."
fi

echo ""
