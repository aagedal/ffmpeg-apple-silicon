# FFmpeg Build Checklist (Apple Silicon)

Use this checklist to track your build progress manually if needed.

**Target:** Apple Silicon (ARM64) Macs only

## Pre-Build Setup

- [ ] Verify you're on an Apple Silicon Mac: `uname -m` should show `arm64`
- [ ] Install Homebrew (if not already installed)
- [ ] Install build dependencies: `brew install cmake meson ninja pkg-config git`
- [ ] Install Xcode Command Line Tools: `xcode-select --install`
- [ ] Verify all tools are available: run `./build.sh` and check for errors

## Build Components (Automatic via ./build.sh)

The build script will automatically build these in order. You can also check progress with `./status.sh`.

### Core Tools
- [ ] **01-nasm** - Assembler (required for optimized builds)

### Video Encoders/Decoders
- [ ] **02-x264** - H.264/AVC encoder
- [ ] **03-x265** - HEVC/H.265 encoder (high bit depth)
- [ ] **04-libvpx** - VP8/VP9 encoder/decoder
- [ ] **05-libaom** - AV1 reference implementation
- [ ] **06-svt-av1** - SVT-AV1 fast encoder
- [ ] **07-vvenc** - VVC (H.266) encoder
- [ ] **08-vvdec** - VVC (H.266) decoder
- [ ] **09-libjxl** - JPEG XL codec (includes brotli, highway dependencies)

### Audio Codecs
- [ ] **10-audio** - Opus, Vorbis, LAME MP3 (includes libogg)

### Additional Libraries
- [ ] **11-extras** - libass, FDK-AAC, freetype, harfbuzz, fribidi, libpng

### Final Application
- [ ] **12-ffmpeg** - FFmpeg with all codecs + VideoToolbox/AudioToolbox

## Post-Build Verification

- [ ] Check binaries exist: `ls -lh ffmpeg ffprobe`
- [ ] Test FFmpeg version: `./ffmpeg -version`
- [ ] Verify JPEG XL support: `./ffmpeg -codecs | grep jxl`
- [ ] Verify VideoToolbox: `./ffmpeg -encoders | grep videotoolbox`
- [ ] Test encoding with JPEG XL: `./ffmpeg -i test.png test.jxl`
- [ ] Test hardware encoding: `./ffmpeg -i test.mp4 -c:v h264_videotoolbox out.mp4`

## Component Details & Estimated Build Times

Times are approximate on a modern Mac (M1/M2 or recent Intel):

| Component | Time | Notes |
|-----------|------|-------|
| NASM | 2-5 min | Required for optimized assembly |
| x264 | 5-10 min | Fast to compile |
| x265 | 15-30 min | Slower, complex codebase |
| libvpx | 10-20 min | Medium complexity |
| libaom | 20-40 min | Large codebase |
| SVT-AV1 | 15-25 min | Medium build time |
| VVenC | 10-20 min | Newer codec |
| VVdeC | 5-10 min | Decoder only |
| libjxl | 15-30 min | Includes dependencies |
| Audio | 10-20 min | Multiple libraries |
| Extras | 15-30 min | Multiple libraries |
| FFmpeg | 10-20 min | Final linking |

**Total estimated time: 2-4 hours** (varies by CPU)

## Troubleshooting Checklist

If a build fails:

- [ ] Read the error message carefully
- [ ] Check which component failed (shown in build output)
- [ ] Verify that component's dependencies are available
- [ ] Check internet connection (for downloads)
- [ ] Ensure enough disk space (~10GB needed)
- [ ] Try building just that component: `./scripts/XX-component.sh`
- [ ] Check the README.md troubleshooting section
- [ ] If needed, clean and rebuild that component

## Customization Options

Want to customize your build?

- [ ] Change library versions in `config.sh`
- [ ] Modify compiler flags in `config.sh`
- [ ] Add custom FFmpeg configure options in `scripts/12-ffmpeg.sh`
- [ ] Add new codecs by creating new scripts in `scripts/`

## Distribution Checklist

Ready to distribute or use your binaries?

- [ ] Test binaries on your machine
- [ ] Copy to desired location: `cp ffmpeg ffprobe /usr/local/bin/`
- [ ] Or add to PATH: `export PATH="$(pwd):$PATH"`
- [ ] Verify static linking: `otool -L ffmpeg` (should show minimal system libs)
- [ ] Document any license requirements for your use case
- [ ] Verify ARM64 architecture: `file ffmpeg` and `lipo -info ffmpeg`
- [ ] Test on another Apple Silicon Mac (macOS 11.0+)
- [ ] Note: Binaries will NOT work on Intel Macs

## Notes

- All builds are static - binaries include all dependencies
- VideoToolbox/AudioToolbox require macOS system frameworks (always available)
- Progress is tracked in `.build-progress` file
- Build artifacts stored in `sources/`, `build/`, `compiled/` directories
- Re-running `./build.sh` safely skips completed components

## Build Status Command

Quick status check anytime:
```bash
./status.sh
```

Shows which components are complete and which are pending.
