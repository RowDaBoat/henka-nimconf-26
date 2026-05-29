#!/usr/bin/env bash
set -e

nim cpp -d:emscripten triangle.nim
open http://localhost:8080
python3 -m http.server 8000
