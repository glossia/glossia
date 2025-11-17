#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building Wasm handlers...${NC}"

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HANDLERS_DIR="$SCRIPT_DIR/handlers"
BUILD_DIR="$SCRIPT_DIR/build"

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Check if zig is installed
if ! command -v zig &> /dev/null; then
    echo "Error: zig is not installed"
    echo "Install from: https://ziglang.org/download/"
    exit 1
fi

echo "Zig version: $(zig version)"

# Compile each .zig file in handlers/
for handler in "$HANDLERS_DIR"/*.zig; do
    if [ -f "$handler" ]; then
        filename=$(basename "$handler" .zig)
        output="$BUILD_DIR/${filename}.wasm"

        echo -e "${BLUE}Compiling ${filename}.zig...${NC}"

        zig build-lib "$handler" \
            -target wasm32-freestanding \
            -dynamic \
            -rdynamic \
            -O ReleaseSmall \
            -femit-bin="$output"

        # Get file size
        size=$(wc -c < "$output" | tr -d ' ')
        size_kb=$((size / 1024))

        echo -e "${GREEN}✓ Built ${filename}.wasm (${size_kb}KB)${NC}"
    fi
done

echo -e "${GREEN}Done!${NC}"
