#!/bin/sh

set -eu

usage() {
	cat <<EOF
Usage: ${0##*/} [Target]
  Target: native (default) or wasm
EOF
}

case "${1:-}" in
-h | --help)
	usage
	exit 0
	;;
esac

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
JOLT_SRC="$SCRIPT_DIR/JoltPhysics/Build"

TARGET=${1:-native}

case "$TARGET" in
native)
	BUILD_DIR="$SCRIPT_DIR/build/native"
	CMAKE="cmake"
	;;
wasm)
	# Single-threaded wasm (no -pthread), matching Jolt's own Emscripten targets
	# and its JobSystemThreadPool WASM path. This also means the consumer must be
	# built without pthreads so the page needs no SharedArrayBuffer / COOP+COEP.
	BUILD_DIR="$SCRIPT_DIR/build/wasm"
	if ! command -v emcmake >/dev/null 2>&1; then
		echo "error: emcmake not found on PATH. Install Emscripten (e.g. 'brew install emscripten')." >&2
		exit 1
	fi
	CMAKE="emcmake cmake"
	;;
*)
	echo "error: unknown target '$TARGET' (expected 'native' or 'wasm')" >&2
	exit 1
	;;
esac

echo "Configuring Jolt ($TARGET) in $BUILD_DIR" >&2
$CMAKE -S "$JOLT_SRC" -B "$BUILD_DIR" -G "Unix Makefiles" \
	-DCMAKE_CXX_FLAGS=-g \
	-DCMAKE_BUILD_TYPE=Distribution \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DTARGET_UNIT_TESTS=OFF \
	-DTARGET_HELLO_WORLD=OFF \
	-DTARGET_PERFORMANCE_TEST=OFF \
	-DTARGET_SAMPLES=OFF \
	-DTARGET_VIEWER=OFF \
	-DENABLE_INSTALL=OFF \
	-DENABLE_ALL_WARNINGS=OFF >&2

JOBS=$( (command -v nproc >/dev/null 2>&1 && nproc) || sysctl -n hw.ncpu 2>/dev/null || echo 4)
echo "Building libJolt.a with $JOBS jobs" >&2
cmake --build "$BUILD_DIR" --target Jolt -j "$JOBS" >&2

echo >&2
echo "Done:" >&2
echo "$(find "$BUILD_DIR" -name 'libJolt.a')"
