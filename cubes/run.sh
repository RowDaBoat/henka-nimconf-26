#!/usr/bin/env bash
set -e

nim cpp -d:emscripten cubes.nim
open http://localhost:8000
python3 -m http.server 8000
