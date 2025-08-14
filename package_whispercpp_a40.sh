#!/bin/bash
set -e

# Paths
WHISPER_DIR="$HOME/ai_stack_server/tools/whisper.cpp"
OUTPUT_DIR="$WHISPER_DIR/whispercpp-a40-prebuilt"
ARCHIVE_NAME="whispercpp-a40-prebuilt.tar.gz"

# Clean old package if exists
rm -rf "$OUTPUT_DIR" "$ARCHIVE_NAME"

echo "[*] Creating prebuilt package directory structure..."
mkdir -p "$OUTPUT_DIR/bin"
mkdir -p "$OUTPUT_DIR/lib"
mkdir -p "$OUTPUT_DIR/include"
mkdir -p "$OUTPUT_DIR/models"   # empty placeholder so default path works

echo "[*] Copying executables..."
cp "$WHISPER_DIR/build/bin/whisper"* "$OUTPUT_DIR/bin/"

echo "[*] Copying shared libraries..."
# libraries may be in build root or deep in ggml/src depending on CMake
find "$WHISPER_DIR/build" -maxdepth 2 -type f -name "libggml*.so" -exec cp {} "$OUTPUT_DIR/lib/" \;

echo "[*] Copying public headers (optional but useful for dev linking)..."
cp "$WHISPER_DIR/include/"*.h "$OUTPUT_DIR/include/" || true
# ggml headers location may differ:
if [ -d "$WHISPER_DIR/ggml/include" ]; then
    cp "$WHISPER_DIR/ggml/include/"*.h "$OUTPUT_DIR/include/" || true
fi

echo "[*] Creating BUILD_INFO.txt..."
cat << EOF > "$OUTPUT_DIR/BUILD_INFO.txt"
whisper.cpp commit: $(cd "$WHISPER_DIR" && git rev-parse HEAD)
Built for: NVIDIA A40 (sm_80)
CMake flags:
    -DGGML_CUDA=ON
    -DGGML_CUDA_ARCH=80
    -DGGML_CCACHE=ON
    -DWHISPER_BUILD_EXAMPLES=ON
CUDA toolkit: $(nvcc --version | grep release | awk '{print $6}' | sed 's/,//')
GCC: $(gcc --version | head -n1)
OS: $(lsb_release -d | awk -F'\t' '{print $2}')
Note: No model binaries are included. Download at runtime into models/.
EOF

echo "[*] Creating tarball..."
tar czvf "$ARCHIVE_NAME" -C "$WHISPER_DIR" "whispercpp-a40-prebuilt"

echo "[+] Done!"
echo "Created archive: $ARCHIVE_NAME"
echo "Upload this to your GitHub Release and future Runpod deployments can download + extract directly."
