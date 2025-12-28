# Quick Start Guide (Apple Silicon)

**Important:** This build system is configured for Apple Silicon Macs (M1/M2/M3) only.

## Prerequisites

```bash
# Install build tools
brew install cmake meson ninja pkg-config git

# Install Xcode Command Line Tools if not already installed
xcode-select --install
```

## Build Everything

```bash
./build.sh
```

**Expected time:** 2-4 hours depending on your Mac's CPU

## Check Build Status

```bash
./status.sh
```

This shows which components are built and which are pending.

## Resume Interrupted Build

Just run the build script again - it automatically skips completed components:

```bash
./build.sh
```

## Build Individual Components

```bash
# Source configuration first
source config.sh

# Build specific component
./scripts/09-libjxl.sh    # Build JPEG XL support
./scripts/02-x264.sh      # Build x264
# etc.
```

## After Build Completes

Your static FFmpeg binaries will be in the project root:
- `./ffmpeg`
- `./ffprobe`

## Test Your Build

```bash
# Check version and features
./ffmpeg -version

# Verify JPEG XL support
./ffmpeg -codecs | grep jxl

# Verify VideoToolbox (macOS hardware acceleration)
./ffmpeg -encoders | grep videotoolbox

# List all available encoders
./ffmpeg -encoders

# List all available decoders
./ffmpeg -decoders
```

## Example Usage

### JPEG XL Encoding
```bash
./ffmpeg -i input.png output.jxl
./ffmpeg -i input.mp4 -c:v libjxl frame_%04d.jxl
```

### Hardware Accelerated Encoding (VideoToolbox)
```bash
# H.264 with hardware acceleration
./ffmpeg -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4

# HEVC with hardware acceleration
./ffmpeg -i input.mp4 -c:v hevc_videotoolbox -b:v 3M output.mp4

# ProRes with hardware acceleration
./ffmpeg -i input.mp4 -c:v prores_videotoolbox output.mov
```

### Modern Codecs
```bash
# AV1 encoding
./ffmpeg -i input.mp4 -c:v libaom-av1 -crf 30 output.mp4
./ffmpeg -i input.mp4 -c:v libsvtav1 -crf 30 output.mp4

# VP9 encoding
./ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 output.webm

# VVC encoding (H.266)
./ffmpeg -i input.mp4 -c:v libvvenc output.266
```

## Troubleshooting

### Build Fails?
1. Check error message to see which component failed
2. Fix the issue (usually missing dependencies)
3. Re-run `./build.sh` to resume

### Clean Rebuild of Specific Component
```bash
# Example: rebuild JPEG XL
rm -rf sources/libjxl* build/libjxl*
grep -v "libjxl" .build-progress > .tmp && mv .tmp .build-progress
./scripts/09-libjxl.sh
```

### Full Clean Start
```bash
rm -rf sources/ build/ compiled/ .build-progress
./build.sh
```

## What Gets Built

1. **NASM** - Assembler for optimized codecs
2. **x264** - H.264 encoder
3. **x265** - HEVC/H.265 encoder
4. **libvpx** - VP8/VP9 encoder/decoder
5. **libaom** - AV1 reference encoder/decoder
6. **SVT-AV1** - Fast AV1 encoder
7. **VVenC** - VVC (H.266) encoder
8. **VVdeC** - VVC (H.266) decoder
9. **libjxl** - JPEG XL encoder/decoder ✨
10. **Audio codecs** - Opus, Vorbis, LAME MP3
11. **Extra libs** - libass (subtitles), FDK-AAC
12. **FFmpeg** - Main application with all codecs + VideoToolbox

## Distribution

The resulting binaries are:
- **ARM64 native** - Optimized for Apple Silicon
- **Statically linked** - No dependencies required
- **Portable to other Apple Silicon Macs** (macOS 11.0+)
- **Not compatible with Intel Macs**

Verify architecture:
```bash
file ./ffmpeg
# Output: Mach-O 64-bit executable arm64

lipo -info ./ffmpeg
# Output: Non-fat file: ./ffmpeg is architecture: arm64
```

Install system-wide:
```bash
# Copy to /usr/local/bin for system-wide use
sudo cp ffmpeg ffprobe /usr/local/bin/

# Or keep in project directory and add to PATH
export PATH="/Users/traag222/Development/ffmpeg_aagedal:$PATH"
```
