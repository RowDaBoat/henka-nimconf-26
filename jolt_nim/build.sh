#!/bin/sh

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
JOLT_SRC="$SCRIPT_DIR/JoltPhysics/Build"

BUILD_TYPE=${1:-Distribution}
BUILD_DIR="$SCRIPT_DIR/build/wasm/$BUILD_TYPE"

if ! command -v emcmake >/dev/null 2>&1; then
	echo "error: emcmake not found on PATH. Install Emscripten (e.g. 'brew install emscripten')." >&2
	exit 1
fi

echo "Configuring Jolt ($BUILD_TYPE) for WASM in $BUILD_DIR"
emcmake cmake -S "$JOLT_SRC" -B "$BUILD_DIR" -G "Unix Makefiles" \
	-DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
	-DTARGET_UNIT_TESTS=OFF \
	-DTARGET_HELLO_WORLD=OFF \
	-DTARGET_PERFORMANCE_TEST=OFF \
	-DTARGET_SAMPLES=OFF \
	-DTARGET_VIEWER=OFF \
	-DENABLE_INSTALL=OFF \
	-DENABLE_ALL_WARNINGS=OFF

JOBS=$( (command -v nproc >/dev/null 2>&1 && nproc) || sysctl -n hw.ncpu 2>/dev/null || echo 4)
echo "Building libJolt.a with $JOBS jobs"
cmake --build "$BUILD_DIR" --target Jolt -j "$JOBS"

echo "Done: $(find "$BUILD_DIR" -name 'libJolt.a')"
