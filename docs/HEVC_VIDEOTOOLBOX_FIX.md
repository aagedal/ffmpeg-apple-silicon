# HEVC VideoToolbox Encoding Fix

## Problem
HEVC VideoToolbox encoders were failing with errors like:
```
[hevc_videotoolbox @ 0x...] Invalid main10 profile with 8 bit input
Error while opening encoder - maybe incorrect parameters
```

## Root Cause
VideoToolbox requires **matching pixel formats** for 10-bit encoding profiles:
- **main10** profile requires **10-bit input** (p010le)
- **main42210** profile (4:2:2 10-bit) requires **p210le input**
- Most video sources are 8-bit (yuv420p, nv12, etc.)

## Solution
Add pixel format conversion filter **before** encoding:

### HEVC Main Profile (8-bit) - No conversion needed
```bash
ffmpeg -i input.mp4 \
    -c:v hevc_videotoolbox -b:v 5M -profile:v main \
    output.mp4
```

### HEVC Main10 Profile (10-bit) - Convert to p010le
```bash
ffmpeg -i input.mp4 \
    -vf format=p010le \
    -c:v hevc_videotoolbox -b:v 5M -profile:v main10 \
    output.mp4
```

### HEVC 4:2:2 10-bit - Convert to p210le
```bash
ffmpeg -i input.mp4 \
    -vf format=p210le \
    -c:v hevc_videotoolbox -b:v 10M -profile:v main42210 \
    output.mov
```

## Pixel Format Reference

| Profile      | Bit Depth | Chroma | Pixel Format | Filter            |
|--------------|-----------|--------|--------------|-------------------|
| main         | 8-bit     | 4:2:0  | nv12/yuv420p | (none needed)     |
| main10       | 10-bit    | 4:2:0  | p010le       | `-vf format=p010le` |
| main42210    | 10-bit    | 4:2:2  | p210le       | `-vf format=p210le` |

## Script Implementation

The `test_encode.sh` script now includes pixel format in codec configuration:

```bash
declare -a CODECS=(
    # name|encoder|ext|options|description|type|pixel_format
    "hevc_videotoolbox|hevc_videotoolbox|mp4|-b:v 5M -profile:v main10|HEVC VT 10-bit|video|p010le"
    "hevc_videotoolbox_422|hevc_videotoolbox|mov|-b:v 10M -profile:v main42210|HEVC VT 4:2:2 10-bit|video|p210le"
)
```

The encode function automatically applies the format filter when specified:
```bash
if [ -n "$pixel_format" ]; then
    filter_opts="-vf format=${pixel_format}"
fi
```

## Supported Pixel Formats

VideoToolbox HEVC encoder accepts:
- `videotoolbox_vld` - Hardware frames
- `nv12` - 8-bit 4:2:0
- `yuv420p` - 8-bit 4:2:0
- `bgra` - 8-bit RGBA
- `ayuv` - 8-bit 4:4:4
- **`p010le`** - 10-bit 4:2:0 (little-endian)
- **`p210le`** - 10-bit 4:2:2 (little-endian)

## Performance Notes

- Pixel format conversion is very fast (CPU-based)
- Hardware encoding remains fast even with conversion
- No significant speed penalty for 10-bit encoding
- Main10 files are typically 10-20% larger than main profile

## Quality Comparison

**main profile (8-bit):**
- Standard HD/4K content
- Smaller files
- Compatible with all devices

**main10 profile (10-bit):**
- HDR content (HDR10, Dolby Vision)
- Better gradients (reduced banding)
- ~10-15% larger files
- Requires modern devices (2016+)

**main42210 profile (4:2:2 10-bit):**
- Professional editing/archival
- Better color accuracy
- ~30-50% larger files
- Required for some broadcast standards

## Troubleshooting

### Still getting "Invalid profile" errors
**Check input bit depth:**
```bash
ffprobe -v error -select_streams v:0 \
    -show_entries stream=pix_fmt \
    -of default=noprint_wrappers=1:nokey=1 \
    input.mp4
```

### Output is 8-bit instead of 10-bit
**Verify pixel format in output:**
```bash
ffprobe -v error -select_streams v:0 \
    -show_entries stream=pix_fmt \
    -of default=noprint_wrappers=1:nokey=1 \
    output.mp4
```
Should show: `p010le` (10-bit 4:2:0) or `p210le` (10-bit 4:2:2)

### Encoding is slow
VideoToolbox should be fast. If slow:
- Check Activity Monitor for hardware acceleration
- Try `-allow_sw false` to force hardware
- Verify bitrate isn't too high (causes quality adjustments)

## Testing

Run the test script to verify all profiles work:
```bash
./test_hevc_fix.sh
```

Expected results:
```
✓ HEVC main (8-bit) - ayuv output
✓ HEVC main10 (10-bit) - p010le output  
✓ HEVC 4:2:2 10-bit - p210le output
```

## Additional Notes

- **Profile name change**: `main422-10` → `main42210` (correct VideoToolbox name)
- **Container**: Use `.mov` for 4:2:2 (better compatibility than MP4)
- **Bitrate**: 10-bit needs ~15-20% higher bitrate for same quality
- **Color space**: Pixel format conversion preserves color space metadata

## References

- FFmpeg VideoToolbox documentation
- Apple VideoToolbox Programming Guide
- HEVC/H.265 profile specifications (ITU-T H.265)

---

**Status:** ✅ Fixed and tested on Apple Silicon (M1/M2/M3)
