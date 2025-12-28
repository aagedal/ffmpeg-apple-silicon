# QuickTime Compatibility Fix for HEVC VideoToolbox

## Problem
HEVC files encoded with VideoToolbox were playable in VLC/IINA but **not in QuickTime Player**.

## Root Causes

### 1. Wrong Codec Tag
- Files had `hev1` tag (ISO/IEC 14496-15 format)
- QuickTime requires `hvc1` tag (Apple's preferred format)

### 2. Incorrect Pixel Format Approach
- **Before**: Used `-vf format=p010le` (filter converts to p010le planar format)
- **After**: Use `-pix_fmt yuv420p10le` (encoder output format)
- VideoToolbox internally works with `p010le` but outputs `yuv420p10le` for container

## Solution

### HEVC 8-bit (Main Profile)
```bash
ffmpeg -i input.mp4 \
    -c:v hevc_videotoolbox -b:v 5M \
    -tag:v hvc1 \
    output.mp4
```
**Output:** `yuv420p` + `hvc1` tag = QuickTime compatible

### HEVC 10-bit (Main10 Profile)  
```bash
ffmpeg -i input.mp4 \
    -c:v hevc_videotoolbox -profile:v main10 -b:v 5M \
    -pix_fmt yuv420p10le \
    -tag:v hvc1 \
    output.mp4
```
**Output:** `yuv420p10le` + `hvc1` tag = QuickTime compatible

### HEVC 4:2:2 10-bit (Main 4:2:2 10 Profile)
```bash
ffmpeg -i input.mp4 \
    -c:v hevc_videotoolbox -profile:v main42210 -b:v 10M \
    -pix_fmt yuv422p10le \
    -tag:v hvc1 \
    output.mov
```
**Output:** `yuv422p10le` + `hvc1` tag = QuickTime compatible

## Key Differences

| Aspect | OLD (Broken) | NEW (Fixed) |
|--------|--------------|-------------|
| Codec Tag | `hev1` (or default) | **`-tag:v hvc1`** |
| Pixel Format Method | `-vf format=p010le` | **`-pix_fmt yuv420p10le`** |
| Output Pix Fmt (10-bit) | `p010le` | **`yuv420p10le`** |
| Output Pix Fmt (422) | `p210le` | **`yuv422p10le`** |
| QuickTime Compatible | ❌ No | ✅ Yes |

## Technical Explanation

### Codec Tags: hvc1 vs hev1
- **`hvc1`**: Parameter sets stored in-band (in each keyframe)
  - Required by QuickTime
  - More compatible with Apple ecosystem
  - Slightly larger files
  
- **`hev1`**: Parameter sets in container header only
  - Standard ISO/IEC format
  - Smaller files
  - Not supported by QuickTime

### Pixel Format Confusion
VideoToolbox internally uses planar 10-bit formats (`p010le`, `p210le`) but can output different formats for container compatibility:

| Internal (VideoToolbox) | Output (Container) | QuickTime |
|------------------------|-------------------|-----------|
| `p010le` | `yuv420p10le` | ✅ Yes |
| `p010le` | `p010le` | ❌ No |
| `p210le` | `yuv422p10le` | ✅ Yes |
| `p210le` | `p210le` | ❌ No |

Using `-pix_fmt yuv420p10le` tells VideoToolbox to:
1. Accept 8-bit input (auto-converts)
2. Process in 10-bit internally
3. Output as `yuv420p10le` (QuickTime-compatible)

Using `-vf format=p010le` forces:
1. CPU-based conversion to planar format
2. Encoder keeps it as `p010le`
3. Container stores `p010le` (QuickTime incompatible)

## Updated Script Configuration

```bash
declare -a CODECS=(
    "h264_videotoolbox|hevc_videotoolbox|mp4|-b:v 5M -tag:v avc1|H.264 VT|video|"
    "hevc_videotoolbox|hevc_videotoolbox|mp4|-b:v 5M -profile:v main10 -tag:v hvc1|HEVC VT 10-bit|video|yuv420p10le"
    "hevc_videotoolbox_422|hevc_videotoolbox|mov|-b:v 10M -profile:v main42210 -tag:v hvc1|HEVC VT 4:2:2|video|yuv422p10le"
)
```

Encoding function now uses:
```bash
if [ -n "$pixel_format" ]; then
    pix_fmt_opt="-pix_fmt ${pixel_format}"
fi

ffmpeg ... -c:v $encoder $extra_opts $pix_fmt_opt ...
```

## Verification

### Check Codec Tag
```bash
ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_tag_string \
    -of default=noprint_wrappers=1:nokey=1 output.mp4
```
**Should show:** `hvc1` (not `hev1`)

### Check Pixel Format
```bash
ffprobe -v error -select_streams v:0 \
    -show_entries stream=pix_fmt \
    -of default=noprint_wrappers=1:nokey=1 output.mp4
```
**Should show:**
- 8-bit: `yuv420p`
- 10-bit: `yuv420p10le`
- 4:2:2: `yuv422p10le`

### Test Playback
```bash
# Should open and play in QuickTime
open output.mp4
```

## Compatibility Matrix

| Encoder Settings | Output Format | QuickTime | VLC | IINA |
|-----------------|---------------|-----------|-----|------|
| `hevc_videotoolbox` + `hvc1` + `yuv420p` | 8-bit 4:2:0 | ✅ | ✅ | ✅ |
| `hevc_videotoolbox` + `hvc1` + `yuv420p10le` | 10-bit 4:2:0 | ✅ | ✅ | ✅ |
| `hevc_videotoolbox` + `hvc1` + `yuv422p10le` | 10-bit 4:2:2 | ✅ | ✅ | ✅ |
| `hevc_videotoolbox` + `hev1` + any | Any | ❌ | ✅ | ✅ |
| `hevc_videotoolbox` + `hvc1` + `p010le` | 10-bit planar | ❌ | ✅ | ✅ |

## Additional Notes

### H.264 VideoToolbox
Also updated to use `avc1` tag for maximum compatibility:
```bash
-c:v h264_videotoolbox -tag:v avc1
```

### Container Choice
- **MP4** (`.mp4`): Best for 8-bit and 10-bit 4:2:0
- **MOV** (`.mov`): Better for 4:2:2 and professional workflows

### Performance
- No performance impact
- VideoToolbox handles conversion internally (hardware-accelerated)
- `-pix_fmt` is just telling encoder which format to output

### HDR Metadata
For HDR content, add color metadata:
```bash
-c:v hevc_videotoolbox -profile:v main10 \
-pix_fmt yuv420p10le -tag:v hvc1 \
-color_primaries bt2020 \
-color_trc smpte2084 \
-colorspace bt2020nc
```

## Testing Script

Run the verification script:
```bash
./test_quicktime_compat.sh
open /tmp/hevc_test_10bit.mp4
```

## References

- Apple VideoToolbox Documentation
- ISO/IEC 14496-15 (HEVC in MP4)
- QuickTime File Format Specification

---

**Status:** ✅ Fixed - All HEVC files now play in QuickTime Player
