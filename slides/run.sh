#!/bin/bash
set -e

rm -rf cubes_demo
mkdir -p cubes_demo
cp -r ../webgpu_nim/build/. cubes_demo/

rm -rf survivor_demo/node_modules
cp -r ../phaser_nim/public/resources resources
nim js --outdir:survivor_demo ../phaser_nim/src/bullet_heaven.nim

nim r src/index.nim
open http://localhost:8080
python3 -m http.server 8080
