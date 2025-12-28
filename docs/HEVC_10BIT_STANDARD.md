# HEVC 10-bit Standardization

## Decision
**All HEVC encoders now output 10-bit by default** for maximum quality and future compatibility.

## Affected Encoders

| Encoder | Profile | Pixel Format | Codec Tag | Output |
|---------|---------|--------------|-----------|--------|
| **libx265** | Main 10 | `yuv420p10le` | `hvc1` | 10-bit 4:2:0 |
| **hevc_videotoolbox** | Main 10 | `yuv420p10le` | `hvc1` | 10-bit 4:2:0 |
| **hevc_videotoolbox_422** | Main 4:2:2 10 | `yuv422p10le` | `hvc1` | 10-bit 4:2:2 |

## Why 10-bit for All HEVC?

### Quality Benefits
- **Better gradients**: Eliminates banding in smooth color transitions (sky, skin tones)
- **More efficient**: 5-10% better quality at same bitrate vs 8-bit
- **HDR support**: Required for HDR10, Dolby Vision, HLG
- **Professional workflows**: Better for editing and color grading

### Compatibility
- ✅ **QuickTime Player** - Plays with `hvc1` tag
- ✅ **Modern devices** - iPhone 7+ (2016), iPad Air 2+, Apple TV 4K
- ✅ **Web browsers** - Safari, Chrome (with hardware support)
- ✅ **Video players** - VLC, IINA, mpv all support 10-bit

### File Size
- Only ~5-10% larger than 8-bit HEVC
- Still much smaller than H.264 8-bit
- Worth the quality improvement

## Technical Details

### libx265 Configuration
```bash
-c:v libx265 -preset medium -crf 28 \
-pix_fmt yuv420p10le \
-tag:v hvc1
```

**Notes:**
- Our x265 build defaults to 10-bit internally
- `-pix_fmt yuv420p10le` ensures proper output format
- `-tag:v hvc1` for QuickTime compatibility

### VideoToolbox Configuration

**Main 10 (4:2:0):**
```bash
-c:v hevc_videotoolbox -profile:v main10 -b:v 5M \
-pix_fmt yuv420p10le \
-tag:v hvc1
```

**Main 4:2:2 10:**
```bash
-c:v hevc_videotoolbox -profile:v main42210 -b:v 10M \
-pix_fmt yuv422p10le \
-tag:v hvc1
```

## Comparison: 8-bit vs 10-bit

### Visual Quality
| Scenario | 8-bit HEVC | 10-bit HEVC |
|----------|------------|-------------|
| Sky gradients | Visible banding | Smooth |
| Skin tones | Color posterization | Natural |
| Dark scenes | Crushed blacks | Detail preserved |
| Compression artifacts | More visible | Less visible |

### Technical Specs
| Aspect | 8-bit | 10-bit |
|--------|-------|--------|
| Colors | 16.7 million | 1.07 billion |
| Bits per channel | 8 bits | 10 bits |
| Levels per channel | 256 | 1024 |
| File size (relative) | 100% | 105-110% |
| Quality (same bitrate) | Baseline | +5-10% better |

## When to Use Each Format

### 10-bit HEVC (Default - All use cases)
- ✅ All modern content creation
- ✅ Archival and preservation
- ✅ Web streaming (YouTube, Vimeo)
- ✅ HDR content
- ✅ Professional editing

### 8-bit H.264 (Legacy compatibility)
- ✅ Maximum compatibility (older devices)
- ✅ Live streaming to older platforms
- ✅ Email/messaging (universal playback)

## Device Compatibility

### Apple Devices Supporting 10-bit HEVC
- **iPhone**: 7 and newer (2016+)
- **iPad**: Air 2 and newer (2014+)
- **Mac**: 2016+ with hardware decoding
- **Apple TV**: 4K and newer (2017+)

### Verification
Check if device supports Main 10 profile:
```bash
# On macOS
system_profiler SPDisplaysDataType | grep -i "metal\|hevc"
```

## Script Configuration

Our test_encode.sh now standardizes on 10-bit:

```bash
declare -a CODECS=(
    "libx264|...|H.264 (libx264) 8-bit|video|"
    "libx265|...|H.265/HEVC (libx265) 10-bit|video|yuv420p10le"
    "h264_videotoolbox|...|H.264 VideoToolbox 8-bit|video|"
    "hevc_videotoolbox|...|HEVC VideoToolbox 10-bit|video|yuv420p10le"
    "hevc_videotoolbox_422|...|HEVC VideoToolbox 4:2:2 10-bit|video|yuv422p10le"
)
```

## Validation

### Check Output is 10-bit
```bash
ffprobe -v error -select_streams v:0 \
    -show_entries stream=profile,pix_fmt \
    -of default=noprint_wrappers=1 output.mp4
```

**Expected output:**
```
profile=Main 10
pix_fmt=yuv420p10le
```

### Check QuickTime Compatibility
```bash
ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_tag_string \
    -of default=noprint_wrappers=1 output.mp4
```

**Expected output:**
```
codec_tag_string=hvc1
```

### Test Playback
```bash
# Should play in QuickTime
open output.mp4
```

## Bitrate Recommendations

For 10-bit HEVC encoding:

| Resolution | CRF (x265) | Bitrate (VT) | Use Case |
|------------|------------|--------------|----------|
| 1280x720   | 26-30      | 3-5 Mbps     | HD streaming |
| 1920x1080  | 24-28      | 5-8 Mbps     | Full HD |
| 2560x1440  | 24-28      | 8-12 Mbps    | 2K |
| 3840x2160  | 22-26      | 15-25 Mbps   | 4K |
| 3840x2160 HDR | 20-24   | 20-35 Mbps   | 4K HDR |

**Note:** 10-bit encoding needs ~10-15% higher bitrate than 8-bit for same perceived quality.

## Color Space for HDR

For HDR content, add color metadata:
```bash
-c:v libx265 -pix_fmt yuv420p10le -tag:v hvc1 \
-color_primaries bt2020 \
-color_trc smpte2084 \
-colorspace bt2020nc \
-master_display "G(13250,34500)B(7500,3000)R(34000,16000)WP(15635,16450)L(10000000,1)"
```

## Testing

Verify all HEVC encoders produce 10-bit output:
```bash
./test_hevc_10bit_all.sh
```

All files should show:
- Profile: `Main 10` or `Rext`
- Pixel format: `yuv420p10le` or `yuv422p10le`
- Codec tag: `hvc1`
- QuickTime: ✅ Plays

## Migration Notes

If you need 8-bit HEVC for legacy compatibility:
```bash
# Use H.264 instead (better 8-bit compatibility)
-c:v libx264 -preset medium -crf 23
-c:v h264_videotoolbox -b:v 5M
```

Or force 8-bit x265 (not recommended):
```bash
# May not work with our 10-bit-only build
-c:v libx265 -pix_fmt yuv420p
```

## References

- ITU-T H.265 (HEVC) Specification
- Apple VideoToolbox Programming Guide
- x265 Documentation
- "The benefits of 10-bit video" - BBC R&D

---

**Status:** ✅ All HEVC encoders standardized on 10-bit with QuickTime compatibility
