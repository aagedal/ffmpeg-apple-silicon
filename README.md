# FFmpeg 9.0.1 Build with JPEG XL Support (Apple Silicon)

This repository contains a modular build system for creating a custom static FFmpeg binary on **Apple Silicon Macs** (M1/M2/M3) with comprehensive codec support, including JPEG XL (libjxl) and macOS hardware acceleration (VideoToolbox/AudioToolbox).

**Target Architecture:** ARM64 (Apple Silicon only)

## Features

The dependency pins below were audited against their upstream stable releases on **2026-08-13**.

### Video Codecs
- **x264** (stable) - H.264/AVC encoding
- **x265** 4.2 - HEVC/H.265 encoding (with high bit depth)
- **libvpx** 1.16.0 - VP8/VP9 encoding/decoding
- **libaom** 3.14.1 - AV1 encoding/decoding
- **SVT-AV1** 4.2.0 - Fast AV1 encoding
- **VVenC** 1.14.0 / **VVdeC** 3.2.0 - VVC (H.266) encoding/decoding
- **libjxl** 0.12.0 - JPEG XL encoding/decoding ✨
- **libwebp** 1.6.0 - WebP image/animation encoding
- **libtheora** 1.2.0 - Theora video codec
- **FLAC** 1.5.0 - Lossless audio codec

### Audio Codecs
- **Opus** 1.6.1 - Modern audio codec
- **Vorbis** 1.3.7 / **libogg** 1.3.6 - Ogg Vorbis
- **LAME** 4.0 - MP3 encoding
- **AAC** - FFmpeg native encoder + AudioToolbox (`aac_at`) hardware-assisted encoding

### Additional Features
- **Whisper** 1.9.2 - Speech recognition/transcription filter
- **libass** 0.17.5 - Advanced subtitle rendering
- **Freetype** 2.14.3 / **Fribidi** 1.0.16 / **HarfBuzz** 14.3.1 - Text shaping and rendering
- **VMAF** 3.2.0 - Perceptual video quality analysis
- **VideoToolbox** - macOS hardware-accelerated encoding (H.264, HEVC, ProRes)
- **AudioToolbox** - macOS audio processing
- **NEON optimizations** - ARM64 SIMD instructions for better performance
- Full static linking for portable binaries

## System Requirements

- **Apple Silicon Mac** (M1, M2, M3, or newer)
- **macOS 11.0 Big Sur** or later
- Xcode Command Line Tools

## Prerequisites

Install required build tools via Homebrew:

```bash
brew install cmake meson ninja pkg-config git
```

You'll also need Xcode Command Line Tools:

```bash
xcode-select --install
```

## Quick Start

Simply run the master build script:

```bash
./build.sh
```

The script will:
1. Check for required tools
2. Show build progress (what's already built)
3. Build all components in order
4. Create the binaries under `dist/<ffmpeg-version>/`: `full/ffmpeg` + `full/ffprobe` (full build) and `photo/ffmpeg` + `photo/ffprobe` (image-only build). Every variant keeps the plain `ffmpeg`/`ffprobe` names, and multiple FFmpeg versions can coexist side by side.

**Note:** The build process takes several hours. You can safely interrupt (Ctrl+C) and resume later - the script tracks progress and skips already-built components.

For detailed quick start instructions, see [QUICKSTART.md](docs/QUICKSTART.md).

## Build Progress Tracking

The build system automatically tracks which components have been successfully built in `.build-progress`. If interrupted, simply re-run `./build.sh` to continue where you left off.

Current build order:
1. NASM (assembler)
2. x264
3. x265
4. libvpx
5. libaom
6. SVT-AV1
7. VVenC (VVC encoder)
8. VVdeC (VVC decoder)
9. libjxl (JPEG XL)
10. Audio codecs (Opus, Vorbis, LAME)
11. Extra libraries (libass)
12. FFmpeg

## Manual Building

You can also build individual components:

```bash
# Source the configuration first
source config.sh

# Build a specific component
./scripts/09-libjxl.sh

# Or build everything manually
for script in scripts/*.sh; do
    bash "$script"
done
```

## Directory Structure

```
ffmpeg_aagedal/
├── build.sh              # Master build script
├── config.sh             # Shared configuration
├── scripts/              # Individual component build scripts
│   ├── 01-nasm.sh
│   ├── 02-x264.sh
│   ├── 03-x265.sh
│   ├── 04-libvpx.sh
│   ├── 05-libaom.sh
│   ├── 06-svt-av1.sh
│   ├── 07-vvenc.sh
│   ├── 08-vvdec.sh
│   ├── 09-libjxl.sh
│   ├── 10-audio.sh
│   ├── 11-extras.sh
│   └── 12-ffmpeg.sh
├── tools/                # Utility scripts for testing and verification
│   ├── verify.sh         # Verify build configuration
│   ├── quick_test.sh     # Quick codec testing
│   ├── test_encode.sh    # Comprehensive encoder tests
│   └── status.sh         # Build status checker
├── docs/                 # Additional documentation
├── sources/              # Downloaded source code (created during build)
├── build/                # Build artifacts (created during build)
├── compiled/             # Compiled libraries (created during build)
├── .build-progress       # Build progress tracker
└── dist/                 # Final binaries (created after build)
    └── <version>/        # e.g. 9.0.1/
        ├── full/         # ffmpeg + ffprobe (full build)
        └── photo/        # ffmpeg + ffprobe (image-only build)
```

## Testing Your Build

Use the included verification script:

```bash
./tools/verify.sh
```

Or manually verify JPEG XL support (binaries live under `dist/<version>/<variant>/`):

```bash
./dist/9.0.1/full/ffmpeg -version
./dist/9.0.1/full/ffmpeg -codecs | grep jxl
```

Test macOS hardware acceleration:

```bash
./ffmpeg -encoders | grep videotoolbox
./ffmpeg -encoders | grep audiotoolbox
```

Run comprehensive codec tests:

```bash
./tools/quick_test.sh  # Generates test pattern and runs all codec tests
./tools/test_encode.sh # Tests encoding with all supported codecs
```

Example encoding with JPEG XL:

```bash
./ffmpeg -i input.png output.jxl
./ffmpeg -i input.mp4 -c:v libjxl output.jxl
```

### Photo Edition (`ffmpeg-photo`)

A much smaller image-only binary built by `scripts/12a-ffmpeg-photo.sh`. It decodes most common image formats (PNG, JPEG, JPEG 2000, JPEG XL, WebP, TIFF, BMP, GIF, AVIF, HEIC, PSD, EXR, DPX, TGA, PNM, QOI, and more) and encodes **AVIF** (via SVT-AV1 or libaom) and **JPEG XL** (via libjxl), plus WebP/PNG/JPEG/TIFF/EXR for convenience. No audio codecs, no general video codecs, no network.

```bash
FFP=./dist/9.0.1/photo/ffmpeg

# JPEG XL export (distance 0 = mathematically lossless, 1 ≈ visually lossless)
$FFP -i input.png -c:v libjxl -distance 1 output.jxl

# AVIF export with libaom (best still-image quality, supports lossless via -crf 0)
$FFP -i input.jpg -c:v libaom-av1 -still-picture 1 -crf 28 output.avif

# AVIF export with SVT-AV1 (faster)
$FFP -i input.jpg -c:v libsvtav1 -crf 30 output.avif

# Read HEIC/AVIF input
$FFP -i photo.heic -c:v libjxl -distance 1 photo.jxl
```

Example using VideoToolbox (hardware acceleration):

```bash
./ffmpeg -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4
./ffmpeg -i input.mp4 -c:v hevc_videotoolbox -b:v 3M output.mp4
```

## Customization

### Changing Library Versions

Edit `config.sh` and modify the version variables:

```bash
export LIBJXL_VERSION="0.12.0"
export FFMPEG_VERSION="9.0.1"
# ... etc
```

### Adding More Codecs

1. Create a new script in `scripts/` (e.g., `13-mycodec.sh`)
2. Follow the pattern of existing scripts
3. Add the script to the `BUILD_SCRIPTS` array in `build.sh`
4. Add appropriate `--enable-libmycodec` flags in `scripts/12-ffmpeg.sh`

### Parallel Build Jobs

The build system automatically uses all available CPU cores. To limit this, edit `config.sh`:

```bash
export MAKEFLAGS="-j4"  # Use only 4 cores
```

## Troubleshooting

### Build Fails

1. Check that all prerequisites are installed
2. Review the error message to identify which component failed
3. Fix any issues (missing dependencies, etc.)
4. Re-run `./build.sh` to resume

### Clean Rebuild

To rebuild a specific component:

```bash
# Remove from progress tracker
grep -v "component-name" .build-progress > .build-progress.tmp
mv .build-progress.tmp .build-progress

# Remove source directory
rm -rf sources/component-directory

# Rebuild
./scripts/XX-component.sh
```

To clean everything and start fresh:

```bash
rm -rf sources/ build/ compiled/ .build-progress
./build.sh
```

### macOS SDK Issues

If you encounter SDK-related errors, ensure your Xcode Command Line Tools are up to date:

```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

## Binary Distribution

The resulting `ffmpeg` and `ffprobe` binaries are:
- **Statically linked** - No external dependencies required
- **Apple Silicon native** - Optimized for ARM64 architecture
- **Portable** - Can be copied to other Apple Silicon Macs running macOS 11.0 or later
- **Not compatible with Intel Macs** - This is an ARM64-only build

To verify the architecture:
```bash
file ./ffmpeg
# Should show: Mach-O 64-bit executable arm64
```

## License Notes

This build is configured with `--enable-gpl --enable-version3` and contains **no non-free components**, so the resulting binaries are licensed under the **GPL version 3** and are redistributable under its terms:
- GPL: x264, x265, FFmpeg GPL components
- (L)GPL v3 (the reason for `--enable-version3`): libvmaf and other version3-licensed parts
- LGPL/BSD: most remaining codec libraries

FDK-AAC is intentionally **not** included: it is non-free and GPL-incompatible, and any FFmpeg build with `--enable-nonfree` is not legally redistributable. AAC encoding is provided by FFmpeg's native `aac` encoder and macOS AudioToolbox (`aac_at`) instead.

Ensure you comply with the GPLv3 (source availability, license notice) when redistributing the binaries.

## Credits

This build system compiles the following open-source projects:
- [FFmpeg](https://ffmpeg.org/)
- [x264](https://www.videolan.org/developers/x264.html)
- [x265](https://www.videolan.org/developers/x265.html)
- [libjxl](https://github.com/libjxl/libjxl)
- [libaom](https://aomedia.googlesource.com/aom/)
- [SVT-AV1](https://gitlab.com/AOMediaCodec/SVT-AV1)
- [VVenC/VVdeC](https://github.com/fraunhoferhhi/)
- And many more...

## Additional Documentation

For more detailed information, see the `/docs` directory:
- [Quick Start Guide](docs/QUICKSTART.md) - Detailed quick start with examples
- [Apple Silicon Build Notes](docs/APPLE_SILICON.md)
- [Testing Guide](docs/TESTING_README.md)
- [Build Fixes Applied](docs/BUILD_FIXES.md)
- [HEVC 10-bit Standard](docs/HEVC_10BIT_STANDARD.md)
- [Image Formats Info](docs/IMAGE_FORMATS_INFO.md)

## Support

For issues specific to this build system, check:
1. All prerequisites are installed
2. You're running on a supported macOS version
3. The error messages in the build output

For codec-specific issues, refer to the upstream project documentation.
