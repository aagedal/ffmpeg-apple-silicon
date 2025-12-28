#!/bin/bash

################################################################################
# FFmpeg Codec Test Results Analyzer
#
# Analyzes the output from test_encode.sh and generates a detailed comparison
# report with file sizes, bitrates, and quality metrics.
#
# Usage:
#   ./analyze_results.sh [output_folder] [ffprobe_path]
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
OUTPUT_BASE="${1:-${SCRIPT_DIR}/test_output}"
FFPROBE="${2:-${SCRIPT_DIR}/ffprobe}"

# Validate inputs
if [ ! -d "$OUTPUT_BASE" ]; then
    echo -e "${RED}Error: Output folder does not exist: ${OUTPUT_BASE}${NC}"
    echo "Run test_encode.sh first to generate test files."
    exit 1
fi

if [ ! -x "$FFPROBE" ]; then
    echo -e "${RED}Error: FFprobe not found or not executable: ${FFPROBE}${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}FFmpeg Codec Test Results Analysis${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Function to get video/image info
get_video_info() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "N/A|N/A|N/A|N/A|N/A|N/A"
        return
    fi
    
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    local size_mb=$(echo "scale=2; $size / 1048576" | bc)
    local size_kb=$(echo "scale=0; $size / 1024" | bc)
    
    # Get video stream info
    local info=$("$FFPROBE" -v error -select_streams v:0 \
        -show_entries stream=codec_name,width,height,bit_rate,duration,nb_frames \
        -show_entries format=duration,bit_rate \
        -of csv=p=0 "$file" 2>/dev/null)
    
    local codec=$(echo "$info" | cut -d',' -f1)
    local width=$(echo "$info" | cut -d',' -f2)
    local height=$(echo "$info" | cut -d',' -f3)
    local bitrate=$(echo "$info" | cut -d',' -f4)
    local duration=$(echo "$info" | cut -d',' -f5)
    local nb_frames=$(echo "$info" | cut -d',' -f6)
    
    # Check if this is a still image (1 frame or very short duration)
    local is_image=0
    if [ "$nb_frames" = "1" ] || [ -z "$duration" ] || [ "$duration" = "N/A" ]; then
        is_image=1
    fi
    
    # For images, just show size and resolution
    if [ $is_image -eq 1 ]; then
        echo "${size_mb}|${codec}|${width}x${height}|IMAGE|${size_kb} KB|image"
        return
    fi
    
    # If stream bitrate not available, use format bitrate
    if [ -z "$bitrate" ] || [ "$bitrate" = "N/A" ]; then
        bitrate=$(echo "$info" | cut -d',' -f7)
    fi
    
    # Convert bitrate to kbps
    if [ -n "$bitrate" ] && [ "$bitrate" != "N/A" ]; then
        bitrate_kbps=$(echo "scale=0; $bitrate / 1000" | bc)
    else
        # Calculate from file size and duration
        if [ -n "$duration" ] && [ "$duration" != "N/A" ]; then
            bitrate_kbps=$(echo "scale=0; ($size * 8) / ($duration * 1000)" | bc)
        else
            bitrate_kbps="N/A"
        fi
    fi
    
    echo "${size_mb}|${codec}|${width}x${height}|${bitrate_kbps}|${duration}|video"
}

# Function to format table row
format_row() {
    printf "%-30s | %10s | %12s | %15s | %12s\n" "$1" "$2" "$3" "$4" "$5"
}

# Find all codec directories
CODEC_DIRS=()
while IFS= read -r -d '' dir; do
    CODEC_DIRS+=("$(basename "$dir")")
done < <(find "$OUTPUT_BASE" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

if [ ${#CODEC_DIRS[@]} -eq 0 ]; then
    echo -e "${RED}No codec directories found in: ${OUTPUT_BASE}${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${#CODEC_DIRS[@]} codec(s) to analyze${NC}"
echo ""

# Get list of all unique base filenames
declare -A FILENAMES
for codec_dir in "${CODEC_DIRS[@]}"; do
    while IFS= read -r -d '' file; do
        basename=$(basename "$file")
        filename="${basename%.*}"
        FILENAMES["$filename"]=1
    done < <(find "$OUTPUT_BASE/$codec_dir" -type f -print0)
done

# Generate report for each file
for filename in "${!FILENAMES[@]}"; do
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}File: ${filename}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Print table header
    format_row "Codec" "Size (MB)" "Resolution" "Bitrate (kbps)" "Duration (s)"
    echo "────────────────────────────────────────────────────────────────────────────"
    
    # Collect data for all codecs
    declare -A CODEC_DATA
    declare -a CODEC_SIZES
    
    for codec_dir in "${CODEC_DIRS[@]}"; do
        # Find matching file
        local found_file=""
        for ext in mp4 mov mkv avi avif jpg jxl; do
            local test_file="${OUTPUT_BASE}/${codec_dir}/${filename}.${ext}"
            if [ -f "$test_file" ]; then
                found_file="$test_file"
                break
            fi
        done
        
        if [ -n "$found_file" ]; then
            IFS='|' read -r size codec resolution bitrate duration type <<< "$(get_video_info "$found_file")"
            CODEC_DATA["$codec_dir"]="${size}|${codec}|${resolution}|${bitrate}|${duration}|${type}"
            CODEC_SIZES+=("${size}|${codec_dir}")
        else
            CODEC_DATA["$codec_dir"]="N/A|N/A|N/A|N/A|N/A|N/A"
        fi
    done
    
    # Sort codecs by size (smallest first)
    IFS=$'\n' sorted_sizes=($(sort -t'|' -k1 -n <<<"${CODEC_SIZES[*]}"))
    unset IFS
    
    # Print sorted results
    for entry in "${sorted_sizes[@]}"; do
        IFS='|' read -r size codec_dir <<< "$entry"
        IFS='|' read -r size codec resolution bitrate duration type <<< "${CODEC_DATA[$codec_dir]}"
        
        # Add visual indicator for smallest/largest
        local indicator=""
        if [ "$entry" = "${sorted_sizes[0]}" ]; then
            indicator="${GREEN}★${NC} "  # Smallest
        elif [ "$entry" = "${sorted_sizes[-1]}" ]; then
            indicator="${RED}●${NC} "   # Largest
        else
            indicator="  "
        fi
        
        # Format display based on type
        local display_duration="$duration"
        if [ "$type" = "image" ]; then
            display_duration="STILL IMAGE"
        fi
        
        printf "${indicator}"
        format_row "$codec_dir" "$size" "$resolution" "$bitrate" "$display_duration"
    done
    
    # Calculate size difference
    if [ ${#sorted_sizes[@]} -ge 2 ]; then
        IFS='|' read -r smallest_size smallest_codec <<< "${sorted_sizes[0]}"
        IFS='|' read -r largest_size largest_codec <<< "${sorted_sizes[-1]}"
        
        if [ "$smallest_size" != "N/A" ] && [ "$largest_size" != "N/A" ]; then
            ratio=$(echo "scale=2; $largest_size / $smallest_size" | bc)
            savings=$(echo "scale=1; (($largest_size - $smallest_size) / $largest_size) * 100" | bc)
            
            echo ""
            echo -e "  ${GREEN}★ Smallest:${NC} $smallest_codec (${smallest_size} MB)"
            echo -e "  ${RED}● Largest:${NC}  $largest_codec (${largest_size} MB)"
            echo -e "  ${YELLOW}Size ratio:${NC} ${ratio}x | ${YELLOW}Savings:${NC} ${savings}%"
        fi
    fi
    
    echo ""
done

# Overall statistics
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Overall Statistics${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

for codec_dir in "${CODEC_DIRS[@]}"; do
    dir_path="${OUTPUT_BASE}/${codec_dir}"
    file_count=$(find "$dir_path" -type f | wc -l | tr -d ' ')
    total_size=$(du -sh "$dir_path" 2>/dev/null | cut -f1)
    
    echo -e "${CYAN}${codec_dir}:${NC}"
    echo -e "  Files: ${file_count}"
    echo -e "  Total size: ${total_size}"
    echo ""
done

echo -e "${GREEN}Analysis complete!${NC}"
