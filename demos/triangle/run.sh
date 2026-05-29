#!/usr/bin/env bash
set -e

nim cpp -d:emscripten triangle.nim
open http://localhost:8000
python3 -m http.server 8000
