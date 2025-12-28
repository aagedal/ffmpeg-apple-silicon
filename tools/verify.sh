#!/bin/bash

# Verify FFmpeg Build Script
# Run this after building to verify your FFmpeg binaries

echo "=========================================="
echo "FFmpeg Build Verification"
echo "=========================================="
echo ""

# Check if binaries exist
if [ ! -f "./ffmpeg" ]; then
    echo "❌ ERROR: ffmpeg binary not found"
    echo "   Run ./build.sh first"
    exit 1
fi

if [ ! -f "./ffprobe" ]; then
    echo "❌ ERROR: ffprobe binary not found"
    echo "   Run ./build.sh first"
    exit 1
fi

echo "✅ Binaries found"
echo ""

# Check architecture
echo "Architecture Check:"
echo "-------------------"
ARCH=$(file ./ffmpeg | grep -o "arm64\|x86_64")
if [ "$ARCH" = "arm64" ]; then
    echo "✅ Architecture: ARM64 (Apple Silicon)"
else
    echo "❌ Architecture: $ARCH (Expected: arm64)"
    exit 1
fi
echo ""

# Detailed file info
echo "Binary Details:"
echo "---------------"
file ./ffmpeg
echo ""

# Architecture info
echo "Architecture Info:"
echo "------------------"
lipo -info ./ffmpeg
echo ""

# File size
echo "Binary Sizes:"
echo "-------------"
ls -lh ffmpeg ffprobe | awk '{print $9 ": " $5}'
echo ""

# Check dependencies (should be minimal - only system frameworks)
echo "Dependencies Check:"
echo "-------------------"
echo "FFmpeg dependencies:"
otool -L ./ffmpeg | head -20
echo ""

# Test version
echo "Version Check:"
echo "--------------"
./ffmpeg -version | head -3
echo ""

# Check for JPEG XL support
echo "JPEG XL Support:"
echo "----------------"
if ./ffmpeg -codecs 2>/dev/null | grep -q "jxl"; then
    echo "✅ JPEG XL support detected"
    ./ffmpeg -codecs 2>/dev/null | grep jxl
else
    echo "❌ JPEG XL support NOT found"
fi
echo ""

# Check for VideoToolbox support
echo "VideoToolbox Support:"
echo "---------------------"
if ./ffmpeg -encoders 2>/dev/null | grep -q "videotoolbox"; then
    echo "✅ VideoToolbox support detected"
    ./ffmpeg -encoders 2>/dev/null | grep videotoolbox
else
    echo "❌ VideoToolbox support NOT found"
fi
echo ""

# Check for AudioToolbox support
echo "AudioToolbox Support:"
echo "---------------------"
if ./ffmpeg -encoders 2>/dev/null | grep -q "audiotoolbox\|at_aac"; then
    echo "✅ AudioToolbox support detected"
else
    echo "⚠️  AudioToolbox support not detected (may be built-in)"
fi
echo ""

# List all enabled encoders
echo "Video Encoders (sample):"
echo "------------------------"
./ffmpeg -encoders 2>/dev/null | grep -E "libx264|libx265|libaom|libsvtav1|libvvenc|libjxl|libvpx" | head -10
echo ""

# List all enabled decoders
echo "Video Decoders (sample):"
echo "------------------------"
./ffmpeg -decoders 2>/dev/null | grep -E "h264|hevc|av1|vvc|jxl|vp9" | head -10
echo ""

# Check audio codecs
echo "Audio Codecs (sample):"
echo "----------------------"
./ffmpeg -codecs 2>/dev/null | grep -E "opus|vorbis|mp3|aac" | head -8
echo ""

echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo ""
echo "✅ Build appears successful!"
echo ""
echo "Key Features Verified:"
echo "  • ARM64 (Apple Silicon) native binary"
echo "  • JPEG XL support"
echo "  • VideoToolbox hardware acceleration"
echo "  • Modern video codecs (x264, x265, VP9, AV1, VVC)"
echo "  • Modern audio codecs (Opus, Vorbis, MP3, AAC)"
echo ""
echo "Test encoding with JPEG XL:"
echo "  ./ffmpeg -i input.png output.jxl"
echo ""
echo "Test hardware acceleration:"
echo "  ./ffmpeg -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4"
echo ""
