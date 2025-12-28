#!/bin/bash

################################################################################
# Quick Test Helper
#
# Demonstrates the codec testing workflow with a simple test pattern video
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}FFmpeg Codec Testing - Quick Demo${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if test videos exist
if [ -z "$(ls -A test_videos 2>/dev/null)" ]; then
    echo -e "${YELLOW}No test videos found. Generating a test pattern...${NC}"
    echo ""
    
    # Generate a 10-second test pattern video with audio
    ./ffmpeg -f lavfi -i testsrc=duration=10:size=1920x1080:rate=30 \
             -f lavfi -i sine=frequency=1000:duration=10 \
             -c:v libx264 -preset fast -crf 23 \
             -c:a aac -b:a 128k \
             -movflags +faststart \
             -y test_videos/test_pattern.mp4 \
             2>&1 | grep -E "(Duration|time=)" || true
    
    echo ""
    echo -e "${GREEN}✓ Test pattern created: test_videos/test_pattern.mp4${NC}"
    echo ""
fi

echo -e "${YELLOW}Starting codec encoding tests...${NC}"
echo ""
./test_encode.sh

echo ""
echo -e "${YELLOW}Analyzing results...${NC}"
echo ""
./analyze_results.sh

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Quick test complete!${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Add your own videos to ${YELLOW}test_videos/${NC}"
echo -e "  2. Run ${YELLOW}./test_encode.sh${NC} again"
echo -e "  3. Check results in ${YELLOW}test_output/${NC}"
echo -e "  4. View detailed report with ${YELLOW}./analyze_results.sh${NC}"
echo ""
echo -e "For more info: ${YELLOW}cat TESTING_README.md${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
