#########################################################
## henka-nimconf-26  WebGPU + Jolt Cubes demo           ##
## ISC License                                          ##
## Copyright (c) [2026] Ivan Mar (sOkam!) and RowDaBoat ##
##########################################################

#!/usr/bin/env bash
set -e

mkdir -p build
nim cpp -d:emscripten src/cubes.nim
open http://localhost:8000
python3 -m http.server 8000
