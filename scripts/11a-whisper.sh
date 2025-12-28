#!/bin/bash

# Build whisper.cpp (OpenAI Whisper speech recognition)

source "$(dirname "$0")/../config.sh"

COMPONENT="whisper"

if is_complete "${COMPONENT}"; then
    echo "[SKIP] ${COMPONENT} already built"
    exit 0
fi

echo "Building whisper.cpp ${WHISPER_VERSION}..."

cd "${SOURCE_DIR}"

# Download and extract whisper.cpp
if [ ! -d "whisper.cpp-${WHISPER_VERSION}" ]; then
    curl -L -o "whisper.cpp-${WHISPER_VERSION}.tar.gz" \
        "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v${WHISPER_VERSION}.tar.gz"
    tar xf "whisper.cpp-${WHISPER_VERSION}.tar.gz"
fi

mkdir -p "whisper.cpp-${WHISPER_VERSION}/build"
cd "whisper.cpp-${WHISPER_VERSION}/build"

# Build whisper.cpp with static library and Apple Silicon optimizations
# Disable OpenMP to simplify static linking with FFmpeg
cmake \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_EXAMPLES=OFF \
    -DGGML_METAL=ON \
    -DGGML_ACCELERATE=ON \
    -DGGML_BLAS=ON \
    -DGGML_BLAS_VENDOR=Apple \
    -DGGML_OPENMP=OFF \
    ..

make ${MAKEFLAGS}
make install

# Fix pkg-config file to include all required libraries for static linking
mkdir -p "${LIB_DIR}/pkgconfig"
cat > "${LIB_DIR}/pkgconfig/whisper.pc" << EOF
prefix=${INSTALL_DIR}
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: whisper
Description: OpenAI Whisper speech recognition library (whisper.cpp)
Version: ${WHISPER_VERSION}
Libs: -L\${libdir} -lwhisper -lggml -lggml-base -lggml-cpu -lggml-metal -lggml-blas
Libs.private: -framework Accelerate -framework Metal -framework Foundation -lc++
Cflags: -I\${includedir}
EOF

echo ""
echo "whisper.cpp ${WHISPER_VERSION} installed successfully"
echo "Note: You'll need to download Whisper models separately to use the filter."
echo "Example: cd ${SOURCE_DIR}/whisper.cpp-${WHISPER_VERSION} && ./models/download-ggml-model.sh base.en"

mark_complete "${COMPONENT}"
