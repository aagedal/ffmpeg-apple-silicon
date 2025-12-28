# Agent Guidelines for FFmpeg Build System

## Build Commands
- Build all: `./build.sh`
- Build single component: `source config.sh && ./scripts/XX-component.sh`
- Verify build: `./verify.sh`
- Test single codec: `./test_encode.sh` (runs all codecs on videos in test_videos/)
- Quick test: `./quick_test.sh` (generates test pattern and runs all tests)

## Code Style
- Shell scripts: Use `#!/bin/bash`, `set -e` for error handling
- Source config: Always `source "$(dirname "$0")/../config.sh"` or `source config.sh`
- Progress tracking: Use `is_complete "${COMPONENT}"` and `mark_complete "${COMPONENT}"`
- Variables: Use `${VAR}` syntax, export environment vars in config.sh
- Paths: Use absolute paths via `${WORKSPACE}`, `${BUILD_DIR}`, `${SOURCE_DIR}`, `${INSTALL_DIR}`
- Colors: Define `RED='\033[0;31m'`, `GREEN='\033[0;32m'`, `YELLOW='\033[1;33m'`, `BLUE='\033[0;34m'`, `NC='\033[0m'`
- Error messages: Echo errors to stderr with color formatting

## Architecture & Build Constraints
- Target: Apple Silicon (ARM64) only, check with `[ "$(uname -m)" != "arm64" ]` and exit if not matched
- Compiler flags: `-arch arm64 -mcpu=apple-m1` in CFLAGS/CXXFLAGS
- Static linking: Always use `--enable-static`, `--enable-pic`, `--disable-shared` where applicable
- Build system: Use autoconf/cmake/meson based on component, configure with `--prefix="${INSTALL_DIR}"`
- Parallel builds: Use `${MAKEFLAGS}` which is set to `-j$(sysctl -n hw.ncpu)`
