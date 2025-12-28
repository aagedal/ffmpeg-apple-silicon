#!/bin/bash

################################################################################
# Create Portable Test Kit
#
# Packages the testing scripts and FFmpeg binaries into a portable folder
# that can be moved to any location
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${1:-${SCRIPT_DIR}/portable_ffmpeg_test_kit}"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Creating Portable FFmpeg Test Kit${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Create output directory
if [ -d "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}Warning: Directory exists: ${OUTPUT_DIR}${NC}"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    rm -rf "$OUTPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"

echo -e "${YELLOW}Copying files...${NC}"

# Copy FFmpeg binaries
if [ -f "$SCRIPT_DIR/ffmpeg" ]; then
    cp "$SCRIPT_DIR/ffmpeg" "$OUTPUT_DIR/"
    echo -e "  ${GREEN}✓${NC} ffmpeg binary"
else
    echo -e "  ${RED}✗${NC} ffmpeg binary not found"
    exit 1
fi

if [ -f "$SCRIPT_DIR/ffprobe" ]; then
    cp "$SCRIPT_DIR/ffprobe" "$OUTPUT_DIR/"
    echo -e "  ${GREEN}✓${NC} ffprobe binary"
else
    echo -e "  ${RED}✗${NC} ffprobe binary not found"
    exit 1
fi

# Copy test scripts
for script in test_encode.sh analyze_results.sh quick_test.sh; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        cp "$SCRIPT_DIR/$script" "$OUTPUT_DIR/"
        chmod +x "$OUTPUT_DIR/$script"
        echo -e "  ${GREEN}✓${NC} $script"
    fi
done

# Copy documentation
if [ -f "$SCRIPT_DIR/TESTING_README.md" ]; then
    cp "$SCRIPT_DIR/TESTING_README.md" "$OUTPUT_DIR/"
    echo -e "  ${GREEN}✓${NC} TESTING_README.md"
fi

# Create test_videos directory
mkdir -p "$OUTPUT_DIR/test_videos"
echo -e "  ${GREEN}✓${NC} test_videos/ directory"

# Create a README
cat > "$OUTPUT_DIR/README.txt" << 'EOF'
FFmpeg Codec Test Kit
====================

This is a portable FFmpeg testing suite. You can move this entire folder
to any location on your Mac.

QUICK START:
------------
1. Add your test videos to the test_videos/ folder
2. Run: ./test_encode.sh
3. Analyze: ./analyze_results.sh

Or run the automated demo:
   ./quick_test.sh

WHAT'S INCLUDED:
----------------
- ffmpeg          Custom-built FFmpeg with JPEG XL, hardware acceleration
- ffprobe         Video analysis tool
- test_encode.sh  Encode videos with multiple codecs
- analyze_results.sh  Compare encoding results
- quick_test.sh   Run automated demo with test pattern
- TESTING_README.md  Detailed documentation

TESTED CODECS:
--------------
- H.264 (libx264, VideoToolbox hardware)
- H.265/HEVC (libx265, VideoToolbox hardware, 10-bit, 4:2:2)
- AV1 (SVT-AV1)
- ProRes 422 (VideoToolbox hardware)
- JPEG/MJPEG
- JPEG XL

REQUIREMENTS:
-------------
- macOS (for hardware VideoToolbox encoders)
- Apple Silicon or Intel Mac
- No installation required - everything is self-contained!

USAGE EXAMPLES:
---------------
# Use current directory
./test_encode.sh

# Specify custom input folder
./test_encode.sh /path/to/my/videos

# Use with system FFmpeg instead
./test_encode.sh test_videos /usr/local/bin/ffmpeg

# Analyze existing results
./analyze_results.sh test_output

For detailed documentation, see: TESTING_README.md

EOF

echo -e "  ${GREEN}✓${NC} README.txt"

# Get total size
TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Portable test kit created!${NC}"
echo ""
echo -e "Location: ${YELLOW}${OUTPUT_DIR}${NC}"
echo -e "Size:     ${YELLOW}${TOTAL_SIZE}${NC}"
echo ""
echo -e "You can now:"
echo -e "  1. Move this folder anywhere: ${YELLOW}mv \"$OUTPUT_DIR\" ~/Desktop/${NC}"
echo -e "  2. Copy to another Mac: ${YELLOW}scp -r \"$OUTPUT_DIR\" user@host:~/${NC}"
echo -e "  3. Share via USB drive or cloud storage"
echo ""
echo -e "To use:"
echo -e "  ${YELLOW}cd \"$OUTPUT_DIR\"${NC}"
echo -e "  ${YELLOW}./quick_test.sh${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
