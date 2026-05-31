#!/bin/sh
set -eu

usage() {
	cat <<EOF
Usage: ${0##*/}

Builds and runs the Jolt init demo natively (Nim C++ backend linked to libJolt.a).
EOF
}

case "${1:-}" in
-h | --help)
	usage
	exit 0
	;;
esac

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

JOLT_LIB=$("$SCRIPT_DIR/build_jolt.sh" native)
JOLT_BUILD=$(dirname "$JOLT_LIB")

JPH_FLAGS=$(python3 - "$JOLT_BUILD/compile_commands.json" <<'PY'
import json, sys, shlex
db = json.load(open(sys.argv[1]))
entry = next(e for e in db if "/Jolt/" in e["file"] and e["file"].endswith(".cpp"))
args = shlex.split(entry["command"]) if "command" in entry else entry["arguments"]
keep = []
for a in args:
    if a.startswith(("-D", "-std=", "-march", "-mtune")):
        keep.append(a)
    elif a.startswith("-m") and any(s in a for s in
            ("sse", "avx", "f16c", "fma", "lzcnt", "bmi", "popcnt", "neon", "fpu", "cpu")):
        keep.append(a)
print("\n".join(keep))
PY
)

PASSC="--passC:-I$SCRIPT_DIR/JoltPhysics"
for f in $JPH_FLAGS; do PASSC="$PASSC --passC:$f"; done

echo "Compiling demo.nim..."

nim cpp \
	-d:release \
	$PASSC \
	--passL:"$JOLT_LIB" \
	--out:"$SCRIPT_DIR/build/demo" \
	demo.nim

echo
echo "Done:"
echo "$SCRIPT_DIR/build/demo"
