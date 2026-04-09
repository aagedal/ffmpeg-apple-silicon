#!/bin/bash

# Master FFmpeg Build Script
# This script orchestrates the entire build process and tracks progress

set -e

echo "=========================================="
echo "FFmpeg Custom Build System"
echo "Apple Silicon (ARM64) Build"
echo "=========================================="
echo ""

# Check if running on Apple Silicon
if [ "$(uname -m)" != "arm64" ]; then
    echo "ERROR: This build is configured for Apple Silicon Macs only"
    echo "Current architecture: $(uname -m)"
    echo "Please run this on an M1, M2, or M3 Mac"
    exit 1
fi

# Load configuration
source "$(dirname "$0")/config.sh"

# Check for required tools
echo "Checking for required build tools..."

if ! command -v git &> /dev/null; then
    echo "ERROR: git is required but not installed"
    exit 1
fi

if ! command -v cmake &> /dev/null; then
    echo "ERROR: cmake is required but not installed"
    echo "Install with: brew install cmake"
    exit 1
fi

if ! command -v meson &> /dev/null; then
    echo "ERROR: meson is required but not installed"
    echo "Install with: brew install meson"
    exit 1
fi

if ! command -v ninja &> /dev/null; then
    echo "ERROR: ninja is required but not installed"
    echo "Install with: brew install ninja"
    exit 1
fi

if ! command -v pkg-config &> /dev/null; then
    echo "ERROR: pkg-config is required but not installed"
    echo "Install with: brew install pkg-config"
    exit 1
fi

echo "All required tools found!"
echo ""

# Build components in order
BUILD_SCRIPTS=(
    "01-nasm.sh"
    "02-x264.sh"
    "03-x265.sh"
    "04-libvpx.sh"
    "05-libaom.sh"
    "06-svt-av1.sh"
    "07-vvenc.sh"
    "08-vvdec.sh"
    "09-libjxl.sh"
    "10-audio.sh"
    "10a-libwebp.sh"
    "10b-flac.sh"
    "10c-theora.sh"
    "10e-openjpeg.sh"
    "11-extras.sh"
    "11a-whisper.sh"
    "11b-vmaf.sh"
    "12-ffmpeg.sh"
    "06b-svt-av1-hdr.sh"
    "12b-ffmpeg-hdr.sh"
)

echo "Build Progress:"
echo "=========================================="

# Show current progress
TOTAL=${#BUILD_SCRIPTS[@]}
COMPLETED=0

for script in "${BUILD_SCRIPTS[@]}"; do
    component_name=$(basename "$script" .sh)
    component_name=${component_name#??-}  # Remove number prefix
    
    if is_complete "$component_name" 2>/dev/null; then
        echo "[✓] $component_name"
        ((COMPLETED++))
    else
        echo "[ ] $component_name"
    fi
done

echo "=========================================="
echo "Progress: ${COMPLETED}/${TOTAL} components built"
echo ""

if [ $COMPLETED -eq $TOTAL ]; then
    echo "All components already built!"
    echo ""
    echo "FFmpeg binaries are located at:"
    echo "  ${WORKSPACE}/ffmpeg          (mainline SVT-AV1)"
    echo "  ${WORKSPACE}/ffprobe"
    echo "  ${WORKSPACE}/ffmpeg-hdr      (SVT-AV1-HDR)"
    echo "  ${WORKSPACE}/ffprobe-hdr"
    echo ""
    exit 0
fi

echo "Starting build process..."
echo "This will take several hours. You can safely interrupt and resume later."
echo ""

read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Execute build scripts
for script in "${BUILD_SCRIPTS[@]}"; do
    script_path="${WORKSPACE}/scripts/${script}"
    
    if [ -f "$script_path" ]; then
        echo ""
        echo "=========================================="
        echo "Running: $script"
        echo "=========================================="
        
        chmod +x "$script_path"
        bash "$script_path"
        
        if [ $? -ne 0 ]; then
            echo "ERROR: Build failed at $script"
            echo "You can fix the issue and re-run this script to continue"
            exit 1
        fi
    else
        echo "WARNING: Script not found: $script_path"
    fi
done

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "FFmpeg binaries with full codec support:"
echo "  ${WORKSPACE}/ffmpeg          (mainline SVT-AV1)"
echo "  ${WORKSPACE}/ffprobe"
echo "  ${WORKSPACE}/ffmpeg-hdr      (SVT-AV1-HDR)"
echo "  ${WORKSPACE}/ffprobe-hdr"
echo ""
echo "Supported features:"
echo "  - x264 (H.264)"
echo "  - x265 (HEVC/H.265)"
echo "  - libvpx (VP8/VP9)"
echo "  - libaom (AV1)"
echo "  - SVT-AV1 (Fast AV1) — mainline and HDR variants"
echo "  - VVenC/VVdeC (VVC)"
echo "  - libjxl (JPEG XL)"
echo "  - Opus, Vorbis, MP3 LAME"
echo "  - FDK-AAC"
echo "  - FLAC (lossless audio)"
echo "  - Theora (video codec)"
echo "  - libwebp (WebP images/animation)"
echo "  - OpenJPEG (JPEG 2000 for DCP)"
echo "  - Whisper (speech recognition/transcription)"
echo "  - VMAF, SSIM, PSNR, MSAD (video quality metrics)"
echo "  - VideoToolbox (macOS hardware acceleration)"
echo "  - AudioToolbox (macOS audio processing)"
echo ""
echo "Test your build:"
echo "  ./ffmpeg -version"
echo "  ./ffmpeg-hdr -version"
echo "  ./ffmpeg -codecs | grep jxl"
echo "  ./ffmpeg -filters | grep whisper"
echo "  ./ffmpeg -encoders | grep videotoolbox"
echo ""
