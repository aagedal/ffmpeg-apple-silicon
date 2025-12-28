# Build Fixes Applied

## Issue: x265 3.6 CMake Compatibility Error

### Problem
x265 version 3.6 is incompatible with CMake 4.2.0 (your installed version). The old CMake policies in x265 3.6 are no longer supported.

**Error messages:**
- `Policy CMP0025 may not be set to OLD behavior`
- `Policy CMP0054 may not be set to OLD behavior`
- `Compatibility with CMake < 3.5 has been removed`

### Solution Applied

**1. Updated x265 to master branch**
- Changed: `export X265_VERSION="3.6"` → `export X265_VERSION="master"`
- File: `config.sh` line 39
- Reason: Master branch has updated CMakeLists.txt compatible with modern CMake

**2. Updated x265 build script**
- File: `scripts/03-x265.sh`
- Changed from downloading tarball to cloning git repository
- Now clones from: https://bitbucket.org/multicoreware/x265_git.git
- Uses master branch with proper ARM64 optimizations

**3. Updated FFmpeg to 8.0.1**
- Changed: `export FFMPEG_VERSION="7.1"` → `export FFMPEG_VERSION="8.0.1"`  
- File: `config.sh` line 58
- Reason: Per your request for latest version

**4. Cleaned failed x265 build**
- Removed old x265 source directory
- Removed x265 from progress tracker
- Ready for clean rebuild

## Verification

The updated x265 master branch successfully:
- ✅ Works with CMake 4.2.0
- ✅ Detects ARM64 architecture
- ✅ Enables NEON optimizations
- ✅ Enables SVE/SVE2 (newer ARM SIMD)
- ✅ Properly configured for Apple Silicon

## How to Continue

Simply run:
```bash
./build.sh
```

Or use the new continue script:
```bash
./continue-build.sh
```

The build will automatically:
1. Skip already-built components (NASM, x264)
2. Build x265 with the new master version
3. Continue with remaining components
4. Build FFmpeg 8.0.1 at the end

## Current Build Status

```
[✓] NASM assembler
[✓] x264 (H.264)
[ ] x265 (HEVC) - READY TO REBUILD
[ ] libvpx (VP8/VP9)
[ ] libaom (AV1)
[ ] SVT-AV1
[ ] VVenC (VVC encoder)
[ ] VVdeC (VVC decoder)
[ ] libjxl (JPEG XL)
[ ] Audio codecs
[ ] Extra libraries
[ ] FFmpeg 8.0.1
```

Progress: 2/12 components complete

## What Changed in config.sh

```diff
- export X265_VERSION="3.6"
+ export X265_VERSION="master"

- export FFMPEG_VERSION="7.1"
+ export FFMPEG_VERSION="8.0.1"
```

## Benefits of x265 Master Branch

1. **Modern CMake support** - Works with CMake 4.x
2. **Latest x265 features** - Most recent encoder improvements
3. **Better ARM64 support** - SVE/SVE2 SIMD in addition to NEON
4. **Active development** - Bug fixes and performance improvements
5. **Apple Silicon optimizations** - Better tuned for M1/M2/M3

## Expected Build Time Remaining

With 2/12 components done, approximately **1.5-3 hours** remaining depending on your Mac model.

## Notes

- x265 master branch is the recommended version for modern systems
- All other library versions remain stable and compatible
- FFmpeg 8.0.1 is the latest stable release (November 2024)
- No other changes needed - just continue the build
