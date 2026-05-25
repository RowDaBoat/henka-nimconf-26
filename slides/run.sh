#!/bin/bash
set -e

nim r index.nim
open http://localhost:8080
python3 -m http.server 8080
