#!/bin/bash

################################################################################
# FFmpeg Codec Test Script
# 
# Portable script to encode the first 10 seconds of all video files in a folder
# into multiple codec formats for comparison.
#
# Usage:
#   ./test_encode.sh [input_folder] [ffmpeg_path]
#
# Arguments:
#   input_folder  - Folder containing test video files (default: ./test_videos)
#   ffmpeg_path   - Path to ffmpeg binary (default: ./ffmpeg)
#
# Output:
#   Creates subdirectories for each codec with encoded test files
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory (for portability)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
INPUT_FOLDER="${1:-${SCRIPT_DIR}/test_videos}"
FFMPEG="${2:-${SCRIPT_DIR}/ffmpeg}"
OUTPUT_BASE="${SCRIPT_DIR}/test_output"
DURATION=10  # Encode first 10 seconds

# Validate inputs
if [ ! -d "$INPUT_FOLDER" ]; then
    echo -e "${RED}Error: Input folder does not exist: ${INPUT_FOLDER}${NC}"
    echo "Creating test_videos folder..."
    mkdir -p "${SCRIPT_DIR}/test_videos"
    echo -e "${YELLOW}Please add test video files to: ${SCRIPT_DIR}/test_videos${NC}"
    exit 1
fi

if [ ! -x "$FFMPEG" ]; then
    echo -e "${RED}Error: FFmpeg not found or not executable: ${FFMPEG}${NC}"
    exit 1
fi

# Print configuration
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}FFmpeg Codec Test Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "Input folder:  ${GREEN}${INPUT_FOLDER}${NC}"
echo -e "FFmpeg binary: ${GREEN}${FFMPEG}${NC}"
echo -e "Output folder: ${GREEN}${OUTPUT_BASE}${NC}"
echo -e "Duration:      ${GREEN}${DURATION} seconds${NC}"
echo ""

# Create output base directory
mkdir -p "$OUTPUT_BASE"

# Define codec configurations
# Format: "codec_name|encoder|extension|extra_options|description|type|output_pix_fmt"
# type: "video" or "image"
# output_pix_fmt: optional, output pixel format for encoder (e.g., "yuv420p10le" for 10-bit)
# NOTE: All HEVC encoders use 10-bit for better quality and HDR support
declare -a CODECS=(
    "libx264|libx264|mp4|-preset medium -crf 23|H.264 (libx264) 8-bit|video|"
    "libx265|libx265|mp4|-preset medium -crf 28 -tag:v hvc1|H.265/HEVC (libx265) 10-bit|video|yuv420p10le"
    "h264_videotoolbox|h264_videotoolbox|mp4|-b:v 5M -tag:v avc1|H.264 VideoToolbox (Hardware) 8-bit|video|"
    "hevc_videotoolbox|hevc_videotoolbox|mp4|-b:v 5M -profile:v main10 -tag:v hvc1|HEVC VideoToolbox 10-bit (Hardware)|video|yuv420p10le"
    "hevc_videotoolbox_422|hevc_videotoolbox|mov|-b:v 10M -profile:v main42210 -tag:v hvc1|HEVC VideoToolbox 4:2:2 10-bit (Hardware)|video|yuv422p10le"
    "libsvtav1|libsvtav1|mp4|-crf 35 -preset 6|AV1 (SVT-AV1)|video|"
    "prores_videotoolbox|prores_videotoolbox|mov|-profile:v 2|ProRes 422 VideoToolbox (Hardware)|video|"
    "jpeg|mjpeg|jpg|-q:v 2|JPEG (Still Image)|image|"
    "jpeg_xl|libjxl|jxl|-distance 1.0|JPEG XL (Still Image)|image|"
    "avif|libsvtav1|avif|-still-picture 1 -crf 25|AVIF (Still Image)|image|"
)

# Find all video files
echo -e "${YELLOW}Searching for video files...${NC}"
VIDEO_FILES=()
while IFS= read -r -d '' file; do
    VIDEO_FILES+=("$file")
done < <(find "$INPUT_FOLDER" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.m4v" -o -iname "*.webm" \) -print0)

if [ ${#VIDEO_FILES[@]} -eq 0 ]; then
    echo -e "${RED}No video files found in: ${INPUT_FOLDER}${NC}"
    echo "Supported formats: mp4, mov, mkv, avi, m4v, webm"
    exit 1
fi

echo -e "${GREEN}Found ${#VIDEO_FILES[@]} video file(s)${NC}"
echo ""

# Function to format time
format_time() {
    local seconds=$1
    printf "%02d:%02d" $((seconds/60)) $((seconds%60))
}

# Function to encode with a specific codec
encode_video() {
    local input_file="$1"
    local codec_name="$2"
    local encoder="$3"
    local extension="$4"
    local extra_opts="$5"
    local description="$6"
    local type="$7"
    local pixel_format="$8"
    
    local basename=$(basename "$input_file")
    local filename="${basename%.*}"
    local output_dir="${OUTPUT_BASE}/${codec_name}"
    local output_file="${output_dir}/${filename}.${extension}"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Skip if already exists
    if [ -f "$output_file" ]; then
        echo -e "  ${YELLOW}⊘${NC} Already exists, skipping"
        return 0
    fi
    
    # Build ffmpeg command
    local start_time=$(date +%s)
    
    # Special handling for JPEG XL encoder check
    if [ "$encoder" = "libjxl" ]; then
        if ! "$FFMPEG" -encoders 2>/dev/null | grep -q "libjxl"; then
            echo -e "  ${RED}✗${NC} libjxl encoder not available"
            return 1
        fi
    fi
    
    # Build pixel format option (output format, not filter)
    local pix_fmt_opt=""
    if [ -n "$pixel_format" ]; then
        pix_fmt_opt="-pix_fmt ${pixel_format}"
    fi
    
    # Image encoding (extract single frame at 5 seconds)
    if [ "$type" = "image" ]; then
        if "$FFMPEG" -hide_banner -loglevel error \
            -ss 5 -i "$input_file" \
            -frames:v 1 \
            -c:v "$encoder" $extra_opts \
            $pix_fmt_opt \
            -y "$output_file" 2>&1; then
            
            local end_time=$(date +%s)
            local elapsed=$((end_time - start_time))
            local file_size=$(du -h "$output_file" | cut -f1)
            
            echo -e "  ${GREEN}✓${NC} Done in $(format_time $elapsed) - ${file_size}"
            return 0
        else
            echo -e "  ${RED}✗${NC} Failed"
            return 1
        fi
    fi
    
    # Standard video encoding
    if "$FFMPEG" -hide_banner -loglevel error -stats \
        -t "$DURATION" -i "$input_file" \
        -c:v "$encoder" $extra_opts \
        $pix_fmt_opt \
        -c:a aac -b:a 128k \
        -movflags +faststart \
        -y "$output_file" 2>&1; then
        
        local end_time=$(date +%s)
        local elapsed=$((end_time - start_time))
        local file_size=$(du -h "$output_file" | cut -f1)
        
        echo -e "  ${GREEN}✓${NC} Done in $(format_time $elapsed) - ${file_size}"
        return 0
    else
        echo -e "  ${RED}✗${NC} Failed"
        return 1
    fi
}

# Main encoding loop
total_files=${#VIDEO_FILES[@]}
total_codecs=${#CODECS[@]}
total_encodes=$((total_files * total_codecs))
current_encode=0
failed_encodes=0

echo -e "${BLUE}Starting encoding tests...${NC}"
echo -e "${BLUE}Total: ${total_encodes} encodes (${total_files} files × ${total_codecs} codecs)${NC}"
echo ""

overall_start=$(date +%s)

for video_file in "${VIDEO_FILES[@]}"; do
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Processing: $(basename "$video_file")${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    for codec_config in "${CODECS[@]}"; do
        current_encode=$((current_encode + 1))
        
        IFS='|' read -r codec_name encoder extension extra_opts description type pixel_format <<< "$codec_config"
        
        echo -ne "${BLUE}[${current_encode}/${total_encodes}]${NC} ${description}..."
        
        if ! encode_video "$video_file" "$codec_name" "$encoder" "$extension" "$extra_opts" "$description" "$type" "$pixel_format"; then
            failed_encodes=$((failed_encodes + 1))
        fi
    done
    echo ""
done

overall_end=$(date +%s)
overall_elapsed=$((overall_end - overall_start))

# Generate summary report
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Encoding Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "Total time:      ${GREEN}$(format_time $overall_elapsed)${NC}"
echo -e "Total encodes:   ${GREEN}${total_encodes}${NC}"
echo -e "Successful:      ${GREEN}$((total_encodes - failed_encodes))${NC}"
echo -e "Failed:          ${RED}${failed_encodes}${NC}"
echo ""
echo -e "Output location: ${GREEN}${OUTPUT_BASE}${NC}"
echo ""

# Generate size comparison report
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}File Size Comparison${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

for codec_config in "${CODECS[@]}"; do
    IFS='|' read -r codec_name encoder extension extra_opts description <<< "$codec_config"
    
    output_dir="${OUTPUT_BASE}/${codec_name}"
    if [ -d "$output_dir" ]; then
        file_count=$(find "$output_dir" -type f | wc -l | tr -d ' ')
        total_size=$(du -sh "$output_dir" 2>/dev/null | cut -f1)
        echo -e "${description}: ${GREEN}${file_count} files${NC} - ${YELLOW}${total_size}${NC}"
    fi
done

echo ""
echo -e "${GREEN}Done! Check the output folders for results.${NC}"
