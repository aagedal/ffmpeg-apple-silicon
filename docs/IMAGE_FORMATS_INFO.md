# Image Format Testing - Updated

## Overview

The testing scripts have been updated to properly export **still images** for JPEG, JPEG XL, and AVIF formats instead of video files.

## What Changed

### Image Extraction
- **Before**: Tried to encode as video streams (caused issues)
- **After**: Extracts a single frame at 5 seconds as a still image

### File Extensions
| Format   | Old Extension | New Extension | Encoder       |
|----------|---------------|---------------|---------------|
| JPEG     | `.mov`        | **`.jpg`**    | `mjpeg`       |
| JPEG XL  | `.mkv`        | **`.jxl`**    | `libjxl`      |
| AVIF     | (skipped)     | **`.avif`**   | `libsvtav1`   |

## Technical Implementation

### Image Encoding Command
```bash
ffmpeg -ss 5 -i input.mp4 -frames:v 1 -c:v [encoder] [options] output.[ext]
```

**Parameters:**
- `-ss 5` - Seek to 5 seconds
- `-frames:v 1` - Extract exactly 1 frame
- `-c:v [encoder]` - Use specified image encoder
- No audio encoding (still image)

### Specific Commands

**JPEG:**
```bash
ffmpeg -ss 5 -i input.mp4 -frames:v 1 -c:v mjpeg -q:v 2 output.jpg
```

**JPEG XL:**
```bash
ffmpeg -ss 5 -i input.mp4 -frames:v 1 -c:v libjxl -distance 1.0 output.jxl
```

**AVIF:**
```bash
ffmpeg -ss 5 -i input.mp4 -frames:v 1 -c:v libsvtav1 -still-picture 1 -crf 25 output.avif
```

## Quality Settings

### JPEG
- **Parameter**: `-q:v 2`
- **Range**: 1-31 (lower = better quality)
- **Setting**: 2 (very high quality)

### JPEG XL
- **Parameter**: `-distance 1.0`
- **Range**: 0.0-15.0 (lower = better quality)
- **Setting**: 1.0 (visually lossless)

### AVIF
- **Parameter**: `-crf 25`
- **Range**: 0-63 (lower = better quality)
- **Setting**: 25 (high quality)
- **Flag**: `-still-picture 1` (optimizes for still images)

## Expected File Sizes

For a 1920x1080 frame:
- **JPEG**: ~100-150 KB (quality 2)
- **JPEG XL**: ~80-120 KB (distance 1.0)
- **AVIF**: ~60-90 KB (CRF 25)

*Note: Actual sizes vary based on content complexity*

## Analysis Output

The `analyze_results.sh` script now properly handles images:

```
Codec                          | Size (MB)  | Resolution   | Bitrate        | Duration
────────────────────────────────────────────────────────────────────────────
★ avif                         |       0.08 | 1920x1080    | IMAGE          | STILL IMAGE
  jpeg_xl                       |       0.10 | 1920x1080    | IMAGE          | STILL IMAGE
  jpeg                          |       0.12 | 1920x1080    | IMAGE          | STILL IMAGE
```

**Features:**
- ★ marker shows smallest file
- Size shown in MB (converted from KB for consistency)
- "IMAGE" instead of bitrate
- "STILL IMAGE" instead of duration

## Codec Comparison

### JPEG
**Pros:**
- Universal compatibility
- Fast encoding/decoding
- Widely supported

**Cons:**
- Largest file sizes
- Lossy compression with visible artifacts
- 8-bit color only

**Best for:** Maximum compatibility, web thumbnails

### JPEG XL
**Pros:**
- Excellent compression (20-30% better than JPEG)
- Supports 10-bit+ color depth
- Lossless and lossy modes
- Modern, future-proof

**Cons:**
- Limited browser support (as of 2024)
- Needs newer software

**Best for:** Archive, high-quality stills, HDR content

### AVIF
**Pros:**
- Best compression (30-50% better than JPEG)
- Supports HDR and wide color gamut
- 10-bit+ color depth
- Growing browser support

**Cons:**
- Slower encoding than JPEG
- Still gaining adoption
- Some compatibility issues

**Best for:** Web images, best size/quality ratio

## Usage Examples

### Extract Single Frame from Specific Time
Edit the script or run manually:
```bash
# At 10 seconds
ffmpeg -ss 10 -i input.mp4 -frames:v 1 -c:v libjxl -distance 1.0 output.jxl

# At the beginning
ffmpeg -ss 0 -i input.mp4 -frames:v 1 -c:v mjpeg -q:v 2 output.jpg

# At the end (approximate)
ffmpeg -sseof -5 -i input.mp4 -frames:v 1 -c:v libsvtav1 -still-picture 1 -crf 20 output.avif
```

### Batch Convert Multiple Videos
The script automatically processes all videos in `test_videos/`:
```bash
./test_encode.sh
```

### Compare Image Quality
After encoding, view the images side-by-side:
```bash
open test_output/jpeg/*.jpg
open test_output/jpeg_xl/*.jxl
open test_output/avif/*.avif
```

## Customization

### Change Extraction Point
Edit `test_encode.sh`, line in `encode_video()` function:
```bash
# Change from 5 seconds to 10 seconds
-ss 5    →    -ss 10
```

### Adjust Quality

**Higher quality JPEG XL:**
```bash
"jpeg_xl|libjxl|jxl|-distance 0.5|JPEG XL (Still Image)|image"
```

**Better AVIF compression:**
```bash
"avif|libsvtav1|avif|-still-picture 1 -crf 20|AVIF (Still Image)|image"
```

**Maximum quality JPEG:**
```bash
"jpeg|mjpeg|jpg|-q:v 1|JPEG (Still Image)|image"
```

## Troubleshooting

### JPEG XL encoder not found
```
✗ libjxl encoder not available
```

**Solution:** Verify your FFmpeg build includes JPEG XL:
```bash
./ffmpeg -encoders | grep jxl
```

### AVIF looks poor quality
**Solution:** Lower the CRF value (higher quality, bigger file):
```bash
-crf 25  →  -crf 18  # Much better quality
```

### Want lossless image
**JPEG XL lossless:**
```bash
ffmpeg -ss 5 -i input.mp4 -frames:v 1 -c:v libjxl output.jxl
# (no -distance flag = lossless)
```

## Performance

Encoding times for a single 1920x1080 frame (Apple M1):
- **JPEG**: ~0.1 seconds (very fast)
- **JPEG XL**: ~0.3 seconds (fast)
- **AVIF**: ~1-2 seconds (slower, better compression)

## Future Enhancements

Potential additions:
- **WebP** support (`libwebp`)
- **PNG** for lossless testing
- Multiple frame extraction at different timestamps
- Quality comparison with PSNR/SSIM metrics
- HDR/10-bit specific tests
