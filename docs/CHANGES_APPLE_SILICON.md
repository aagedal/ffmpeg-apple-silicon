# Apple Silicon Configuration Changes

## Summary

The build system has been updated to **exclusively target Apple Silicon (ARM64)** architecture. All builds will produce ARM64-native binaries optimized for M1/M2/M3 Macs.

## Modified Files

### 1. `config.sh` - Main Configuration
**Changes:**
- Added `export ARCH="arm64"`
- Set `MACOSX_DEPLOYMENT_TARGET="11.0"` (Big Sur minimum)
- Updated `CFLAGS` with `-arch arm64 -mcpu=apple-m1`
- Updated `CXXFLAGS` with `-arch arm64 -mcpu=apple-m1`
- Updated `LDFLAGS` with `-arch arm64`
- Added architecture info to startup message

**Impact:** All components now compile with ARM64-specific optimizations.

### 2. `build.sh` - Master Build Script
**Changes:**
- Added architecture check: verifies `uname -m` returns `arm64`
- Updated title to show "Apple Silicon (ARM64) Build"
- Added error message if run on non-ARM64 system

**Impact:** Prevents accidental builds on Intel Macs.

### 3. Component Build Scripts

#### `scripts/02-x264.sh`
- Added `--host=aarch64-apple-darwin` to configure

#### `scripts/03-x265.sh`
- Added `-DCMAKE_OSX_ARCHITECTURES=arm64`
- Added `-DENABLE_ASSEMBLY=ON` for ARM assembly

#### `scripts/04-libvpx.sh`
- Added `--target=arm64-darwin20-gcc`

#### `scripts/05-libaom.sh`
- Added `-DCMAKE_OSX_ARCHITECTURES=arm64`

#### `scripts/06-svt-av1.sh`
- Added `-DCMAKE_OSX_ARCHITECTURES=arm64`

#### `scripts/07-vvenc.sh`
- Added `-DCMAKE_OSX_ARCHITECTURES=arm64`

#### `scripts/08-vvdec.sh`
- Added `-DCMAKE_OSX_ARCHITECTURES=arm64`

#### `scripts/09-libjxl.sh`
- Added `-DCMAKE_OSX_ARCHITECTURES=arm64` to brotli build
- Added `-DCMAKE_OSX_ARCHITECTURES=arm64` to highway build
- Added `-DCMAKE_OSX_ARCHITECTURES=arm64` to libjxl build

#### `scripts/12-ffmpeg.sh`
- Added `--arch=arm64`
- Added `--target-os=darwin`
- Added `--enable-neon` for ARM SIMD instructions

**Impact:** All components explicitly target ARM64 architecture.

### 4. Documentation Updates

#### `README.md`
- Updated title to include "(Apple Silicon)"
- Added "Target Architecture: ARM64" notice
- Added system requirements section
- Added NEON optimizations to features
- Updated binary distribution section with architecture verification
- Added `file` and `lipo` commands for verification

#### `QUICKSTART.md`
- Added Apple Silicon notice at top
- Updated distribution section with architecture info
- Added verification commands

#### `BUILD_CHECKLIST.md`
- Added architecture verification step
- Updated distribution checklist with ARM64 notes

### 5. New Files

#### `APPLE_SILICON.md`
Complete documentation of Apple Silicon optimizations including:
- Compiler flags explanation
- Component-specific configurations
- Performance benefits
- Verification commands
- Compatibility matrix
- NEON vs x86 SIMD comparison
- Build time estimates
- VideoToolbox details

#### `verify.sh`
Comprehensive verification script that checks:
- Binary existence
- Architecture (ARM64)
- File details
- Dependencies
- JPEG XL support
- VideoToolbox support
- Available codecs
- Provides summary and test commands

## Technical Details

### Compiler Optimizations
```bash
-arch arm64           # Target ARM64 architecture
-mcpu=apple-m1        # Optimize for Apple M1 CPU family
-O3                   # Maximum optimization level
-fPIC                 # Position independent code
```

### FFmpeg ARM64 Features
- `--arch=arm64` - Target architecture
- `--enable-neon` - Enable ARM NEON SIMD instructions
- `--enable-videotoolbox` - Hardware acceleration
- `--enable-audiotoolbox` - Audio processing

### Build Requirements
- Must run on ARM64 Mac (M1/M2/M3)
- macOS 11.0 Big Sur or later
- Native ARM64 toolchain

## Verification

After building, verify with:

```bash
# Run verification script
./verify.sh

# Or manually check:
file ./ffmpeg
# Should show: Mach-O 64-bit executable arm64

lipo -info ./ffmpeg
# Should show: Non-fat file: ./ffmpeg is architecture: arm64
```

## Benefits

1. **Performance:** Native ARM64 code, no Rosetta translation
2. **Optimization:** Apple M1-specific CPU tuning
3. **SIMD:** NEON instructions for parallel processing
4. **Hardware Acceleration:** Full VideoToolbox/AudioToolbox support
5. **Power Efficiency:** Native code uses less power

## Compatibility

✅ **Works on:**
- Apple Silicon Macs (M1, M2, M3+)
- macOS 11.0 Big Sur or later

❌ **Does NOT work on:**
- Intel Macs
- macOS 10.x or earlier

## Migration Notes

If you previously built for Intel or Universal:
1. Clean all build artifacts: `rm -rf sources/ build/ compiled/ .build-progress`
2. Run the new build: `./build.sh`
3. Result will be ARM64-only binary

To create Universal Binary (if needed):
1. Build ARM64 version on Apple Silicon Mac
2. Build x86_64 version on Intel Mac
3. Combine with: `lipo -create ffmpeg-arm64 ffmpeg-x86_64 -output ffmpeg`

## Testing

The build system has been configured to:
1. Detect architecture at build time
2. Fail gracefully if run on wrong architecture
3. Produce optimized ARM64-native binaries
4. Enable all available ARM-specific features
5. Verify JPEG XL and VideoToolbox support

Run `./verify.sh` after building to confirm all features.
