#!/bin/bash

################################################################################
# Make FFmpeg Sandboxable for macOS App Distribution
#
# This script fixes FFmpeg binaries to work in sandboxed macOS apps by:
# 1. Copying required Homebrew dylibs into the app bundle
# 2. Fixing install paths using install_name_tool
# 3. Creating a self-contained binary package
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FFMPEG_BIN="${SCRIPT_DIR}/ffmpeg"
FFPROBE_BIN="${SCRIPT_DIR}/ffprobe"
OUTPUT_DIR="${SCRIPT_DIR}/sandboxable_ffmpeg"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Creating Sandboxable FFmpeg Package${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Create output directory structure
mkdir -p "${OUTPUT_DIR}/bin"
mkdir -p "${OUTPUT_DIR}/lib"

echo -e "${YELLOW}Analyzing dependencies...${NC}"
echo ""

# Function to copy library and fix paths
copy_and_fix_lib() {
    local lib_path="$1"
    local lib_name=$(basename "$lib_path")
    local dest="${OUTPUT_DIR}/lib/${lib_name}"
    
    if [ -f "$lib_path" ]; then
        if [ ! -f "$dest" ]; then
            echo "  Copying: $lib_name"
            cp "$lib_path" "$dest"
            chmod 644 "$dest"
        fi
    else
        echo -e "  ${RED}✗ Missing: $lib_path${NC}"
        return 1
    fi
}

# Find all Homebrew dependencies
echo -e "${BLUE}Finding Homebrew dependencies...${NC}"
HOMEBREW_LIBS=$(otool -L "$FFMPEG_BIN" | grep "/opt/homebrew" | awk '{print $1}')

if [ -z "$HOMEBREW_LIBS" ]; then
    echo -e "${GREEN}✓ No Homebrew dependencies found!${NC}"
    echo "Binary is already sandboxable."
    exit 0
fi

echo "Found Homebrew dependencies:"
for lib in $HOMEBREW_LIBS; do
    echo "  - $lib"
    copy_and_fix_lib "$lib"
done
echo ""

# Copy FFmpeg binaries
echo -e "${BLUE}Copying FFmpeg binaries...${NC}"
cp "$FFMPEG_BIN" "${OUTPUT_DIR}/bin/ffmpeg"
cp "$FFPROBE_BIN" "${OUTPUT_DIR}/bin/ffprobe"
chmod 755 "${OUTPUT_DIR}/bin/ffmpeg"
chmod 755 "${OUTPUT_DIR}/bin/ffprobe"
echo ""

# Fix install paths
echo -e "${BLUE}Fixing library paths...${NC}"
for binary in "${OUTPUT_DIR}/bin/ffmpeg" "${OUTPUT_DIR}/bin/ffprobe"; do
    echo "Processing $(basename $binary)..."
    
    for lib in $HOMEBREW_LIBS; do
        lib_name=$(basename "$lib")
        echo "  Fixing: $lib_name"
        install_name_tool -change "$lib" "@executable_path/../lib/$lib_name" "$binary"
    done
done
echo ""

# Fix inter-library dependencies
echo -e "${BLUE}Fixing inter-library dependencies...${NC}"
for dylib in "${OUTPUT_DIR}/lib"/*.dylib; do
    if [ -f "$dylib" ]; then
        echo "Processing $(basename $dylib)..."
        
        # Fix library ID
        lib_name=$(basename "$dylib")
        install_name_tool -id "@executable_path/../lib/$lib_name" "$dylib"
        
        # Fix dependencies
        DYLIB_DEPS=$(otool -L "$dylib" | grep "/opt/homebrew" | awk '{print $1}')
        for dep in $DYLIB_DEPS; do
            dep_name=$(basename "$dep")
            if [ -f "${OUTPUT_DIR}/lib/$dep_name" ]; then
                install_name_tool -change "$dep" "@executable_path/../lib/$dep_name" "$dylib"
            fi
        done
    fi
done
echo ""

# Verify
echo -e "${BLUE}Verifying fixed binaries...${NC}"
for binary in "${OUTPUT_DIR}/bin/ffmpeg" "${OUTPUT_DIR}/bin/ffprobe"; do
    echo "Checking $(basename $binary):"
    REMAINING_HOMEBREW=$(otool -L "$binary" | grep "/opt/homebrew" || true)
    if [ -z "$REMAINING_HOMEBREW" ]; then
        echo -e "  ${GREEN}✓ No Homebrew paths remaining${NC}"
    else
        echo -e "  ${RED}✗ Still has Homebrew paths:${NC}"
        echo "$REMAINING_HOMEBREW"
    fi
done
echo ""

# Create usage instructions
cat > "${OUTPUT_DIR}/README.txt" << 'EOREADME'
Sandboxable FFmpeg Package
===========================

This package contains FFmpeg binaries with bundled dependencies
for use in sandboxed macOS applications.

STRUCTURE:
----------
bin/
  ffmpeg     - Main FFmpeg binary
  ffprobe    - Probe utility
lib/
  *.dylib    - Required dynamic libraries

USAGE IN XCODE:
---------------
1. Add both bin/ and lib/ folders to your Xcode project

2. In Build Phases, add a "Copy Files" phase:
   - Destination: Resources
   - Add the bin/ and lib/ folders

3. In your code, reference the binary:
   let ffmpegURL = Bundle.main.url(forResource: "ffmpeg", withExtension: nil, subdirectory: "bin")!

4. When executing, ensure lib/ folder is accessible:
   @executable_path/../lib will resolve to Resources/lib/

ALTERNATIVE - BUNDLE IN FRAMEWORKS:
------------------------------------
Copy lib/*.dylib to your app's Frameworks folder and update paths:
   install_name_tool -change @executable_path/../lib/libxcb.1.dylib \
       @executable_path/../Frameworks/libxcb.1.dylib bin/ffmpeg

VERIFICATION:
-------------
Check that binaries don't reference /opt/homebrew:
   otool -L bin/ffmpeg | grep homebrew

Should return nothing if properly fixed.

TROUBLESHOOTING:
----------------
If you get "Library not loaded" errors:
1. Verify lib/*.dylib files are in your app bundle
2. Check entitlements allow loading libraries
3. Verify codesigning doesn't break library loading

For sandboxed apps, you may need:
   com.apple.security.cs.allow-dyld-environment-variables
   com.apple.security.cs.disable-library-validation
EOREADME

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Sandboxable package created!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Location: ${OUTPUT_DIR}"
echo ""
echo "Copied files:"
ls -lh "${OUTPUT_DIR}/bin/"
echo ""
echo "Bundled libraries:"
ls -lh "${OUTPUT_DIR}/lib/"
echo ""
echo "Next steps:"
echo "1. Copy ${OUTPUT_DIR}/bin and ${OUTPUT_DIR}/lib to your Xcode project"
echo "2. Add to your app bundle as Resources"
echo "3. See README.txt for detailed instructions"
echo ""
