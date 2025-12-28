# FFmpeg Static Build - Fixed Issues

## Date: November 28, 2024

## Problem
The original build was linking against Homebrew's dynamic libraries instead of the static libraries built locally:
- `/opt/homebrew/opt/jpeg-xl/lib/libjxl.*.dylib`
- `/opt/homebrew/opt/little-cms2/lib/liblcms2.*.dylib`

## Root Causes Identified

### 1. **Grep Pattern Bug in rebuild_truly_static.sh**
The script used basic regex `^libjxl$\|^ffmpeg$` which didn't work correctly on macOS.
- **Fix**: Changed to extended regex: `grep -E -v "^(libjxl|ffmpeg)$"`

### 2. **JPEG XL linking to lcms2**
libjxl was configured to use external lcms2 from Homebrew instead of built-in skcms.
- **Fix**: Added CMake flags to force skcms usage:
  - `-DJPEGXL_ENABLE_SKCMS=ON`
  - `-DJPEGXL_FORCE_SYSTEM_LCMS2=OFF`
  - `-DCMAKE_DISABLE_FIND_PACKAGE_LCMS2=ON`

### 3. **libjxl_threads.pc missing C++ library**
The pkg-config file for libjxl_threads didn't include `-lc++` which caused linker errors.
- **Fix**: Added automatic patching in `scripts/09-libjxl.sh`:
  ```bash
  sed -i '' 's/Libs\.private: -lm$/Libs.private: -lm -lc++/' \
      "${INSTALL_DIR}/lib/pkgconfig/libjxl_threads.pc"
  ```

### 4. **Libtool .la files with Homebrew paths**
Libtool archive files contained references to Homebrew's libogg instead of local build.
- **Fix**: Added cleanup in `config.sh`:
  ```bash
  find "${LIB_DIR}" -name "*.la" -delete 2>/dev/null || true
  find "${LIB_DIR}/pkgconfig" -name "*-uninstalled.pc" -delete 2>/dev/null || true
  ```

## Files Modified

1. **rebuild_truly_static.sh** - Fixed grep pattern
2. **scripts/09-libjxl.sh** - Added lcms2 disable flags + libjxl_threads.pc patching  
3. **config.sh** - Added .la and -uninstalled.pc cleanup

## Verification

Run to rebuild:
```bash
./rebuild_truly_static.sh
```

Verify no Homebrew dependencies:
```bash
otool -L ./ffmpeg | grep homebrew
# Should return nothing
```

Check codecs:
```bash
./ffmpeg -codecs | grep jxl
./ffmpeg -encoders | grep videotoolbox
```

## Result

✅ FFmpeg binary with **ZERO** Homebrew dependencies  
✅ All codecs statically linked  
✅ JPEG XL working with skcms (no lcms2)  
✅ VideoToolbox hardware acceleration enabled  
✅ Portable to any macOS 11.0+ Apple Silicon Mac  
