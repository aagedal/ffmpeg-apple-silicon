# FFmpeg Codec Testing Suite

Comprehensive testing scripts to compare encoding performance across multiple codecs.

## Quick Start

1. **Create test folder and add videos:**
   ```bash
   mkdir test_videos
   # Copy your test video files into test_videos/
   ```

2. **Run encoding tests:**
   ```bash
   ./test_encode.sh
   ```

3. **Analyze results:**
   ```bash
   ./analyze_results.sh
   ```

## Scripts Overview

### `test_encode.sh`
Encodes the first 10 seconds of all videos into multiple codec formats.

**Usage:**
```bash
./test_encode.sh [input_folder] [ffmpeg_path]
```

**Arguments:**
- `input_folder` - Folder with test videos (default: `./test_videos`)
- `ffmpeg_path` - Path to ffmpeg binary (default: `./ffmpeg`)

**Tested Codecs:**

*Video Encoders:*
- **libx264** - H.264 software encoder (CRF 23, medium preset)
- **libx265** - H.265/HEVC software encoder (CRF 28, medium preset)
- **h264_videotoolbox** - H.264 hardware encoder (5 Mbps)
- **hevc_videotoolbox** - HEVC hardware encoder 10-bit (5 Mbps)
- **hevc_videotoolbox_422** - HEVC hardware 4:2:2 10-bit (10 Mbps)
- **libsvtav1** - AV1 encoder (CRF 35, preset 6)
- **prores_videotoolbox** - ProRes 422 hardware encoder

*Image Encoders (extracts single frame at 5 seconds):*
- **jpeg** - JPEG still image (quality 2) → `.jpg`
- **jpeg_xl** - JPEG XL still image (distance 1.0) → `.jxl`
- **avif** - AVIF still image (CRF 25) → `.avif`

### `analyze_results.sh`
Generates detailed comparison reports with file sizes, bitrates, and quality metrics.

**Usage:**
```bash
./analyze_results.sh [output_folder] [ffprobe_path]
```

**Arguments:**
- `output_folder` - Test results folder (default: `./test_output`)
- `ffprobe_path` - Path to ffprobe binary (default: `./ffprobe`)

## Output Structure

```
test_output/
├── libx264/
│   ├── video1.mp4
│   └── video2.mp4
├── libx265/
│   ├── video1.mp4
│   └── video2.mp4
├── hevc_videotoolbox/
│   ├── video1.mp4
│   └── video2.mp4
├── jpeg/              # Still images
│   ├── video1.jpg
│   └── video2.jpg
├── jpeg_xl/           # Still images
│   ├── video1.jxl
│   └── video2.jxl
├── avif/              # Still images
│   ├── video1.avif
│   └── video2.avif
└── ...
```

## Portability

Both scripts are fully portable! You can:

1. **Move to any folder:**
   ```bash
   cp test_encode.sh /path/to/your/project/
   cp analyze_results.sh /path/to/your/project/
   ```

2. **Specify custom paths:**
   ```bash
   ./test_encode.sh /path/to/videos /path/to/ffmpeg
   ./analyze_results.sh /path/to/output /path/to/ffprobe
   ```

3. **Use with any FFmpeg binary:**
   ```bash
   # System FFmpeg
   ./test_encode.sh test_videos /usr/local/bin/ffmpeg
   
   # Homebrew FFmpeg
   ./test_encode.sh test_videos /opt/homebrew/bin/ffmpeg
   
   # Custom build
   ./test_encode.sh test_videos ./my_custom_ffmpeg
   ```

## Example Workflow

### 1. Prepare Test Videos
```bash
mkdir test_videos
cp ~/Movies/sample1.mp4 test_videos/
cp ~/Movies/sample2.mov test_videos/
```

### 2. Run Encoding Tests
```bash
./test_encode.sh
```

**Output:**
```
═══════════════════════════════════════════════════════════
FFmpeg Codec Test Script
═══════════════════════════════════════════════════════════
Input folder:  /Users/you/ffmpeg_aagedal/test_videos
FFmpeg binary: /Users/you/ffmpeg_aagedal/ffmpeg
Output folder: /Users/you/ffmpeg_aagedal/test_output
Duration:      10 seconds

Found 2 video file(s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Processing: sample1.mp4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[1/18] H.264 (libx264)...  ✓ Done in 00:03 - 4.2M
[2/18] H.265/HEVC (libx265)...  ✓ Done in 00:08 - 2.8M
[3/18] H.264 VideoToolbox (Hardware)...  ✓ Done in 00:01 - 6.1M
...
```

### 3. Analyze Results
```bash
./analyze_results.sh
```

**Output:**
```
═══════════════════════════════════════════════════════════
FFmpeg Codec Test Results Analysis
═══════════════════════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: sample1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Codec                          | Size (MB)  | Resolution   | Bitrate (kbps) | Duration (s)
────────────────────────────────────────────────────────────────────────────
★ libx265                      |       2.80 | 1920x1080    |           2345 |        10.00
  libsvtav1                    |       3.12 | 1920x1080    |           2612 |        10.00
  jpeg_xl                      |       3.85 | 1920x1080    |           3224 |        10.00
  libx264                      |       4.20 | 1920x1080    |           3515 |        10.00
  h264_videotoolbox            |       6.10 | 1920x1080    |           5104 |        10.00
● prores_videotoolbox          |      42.50 | 1920x1080    |          35606 |        10.00

  ★ Smallest: libx265 (2.80 MB)
  ● Largest:  prores_videotoolbox (42.50 MB)
  Size ratio: 15.18x | Savings: 93.4%
```

## Advanced Usage

### Custom Duration
Edit `test_encode.sh` and change:
```bash
DURATION=10  # Change to desired seconds
```

### Custom Codec Parameters
Edit the `CODECS` array in `test_encode.sh`:
```bash
"libx264|libx264|mp4|-preset slow -crf 18|H.264 High Quality"
```

Format: `"name|encoder|extension|ffmpeg_options|description"`

### Filter Specific Files
```bash
# Only encode MP4 files
find test_videos -name "*.mp4" -type f
```

### Batch Processing
```bash
# Process multiple test folders
for folder in test_set_1 test_set_2 test_set_3; do
    ./test_encode.sh "$folder"
    ./analyze_results.sh "test_output_$folder"
done
```

## Codec Recommendations

### Best Compression (Smallest Files)
1. **libx265** - Best compression, slower encoding
2. **libsvtav1** - Good compression, reasonable speed
3. **jpeg_xl** - Excellent for screen content

### Best Speed (Hardware Accelerated)
1. **h264_videotoolbox** - Fast, widely compatible
2. **hevc_videotoolbox** - Fast, better compression than H.264
3. **prores_videotoolbox** - Fastest, largest files (editing)

### Best Quality/Size Balance
1. **libx265** with CRF 23-28
2. **libsvtav1** with CRF 30-35
3. **hevc_videotoolbox** with 5-10 Mbps

### Production Use Cases
- **Web/Streaming**: libx264 or h264_videotoolbox
- **Archive**: libx265 or libsvtav1
- **Editing**: prores_videotoolbox
- **Images/Screenshots**: jpeg_xl

## Troubleshooting

### "No video files found"
Make sure your videos have supported extensions:
- `.mp4`, `.mov`, `.mkv`, `.avi`, `.m4v`, `.webm`

### "Encoder not available"
Check available encoders:
```bash
./ffmpeg -encoders | grep -i "h264\|hevc\|av1\|jxl"
```

### JPEG XL fails
Verify libjxl is enabled:
```bash
./ffmpeg -codecs 2>&1 | grep jpegxl
```

### Hardware encoder fails on non-Mac systems
Hardware encoders (videotoolbox) only work on macOS. The script will skip them automatically.

## Tips

1. **Start with short clips** - 10 seconds is usually enough for testing
2. **Use diverse content** - Test with different types of video (action, animation, screen recording)
3. **Compare bitrates** - Lower bitrate = better compression efficiency
4. **Check visual quality** - Use VLC or other players to compare output quality
5. **Archive original settings** - Document which codec settings work best for your use case

## License

These scripts are provided as-is for testing purposes. FFmpeg is licensed under LGPL/GPL.
