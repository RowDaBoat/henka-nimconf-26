#!/bin/bash
set -e

ln -sf ../phaser_nim/node_modules node_modules
ln -sf ../phaser_nim/public/resources resources
nim js --outdir:bullet_heaven ../phaser_nim/src/bullet_heaven.nim
nim r index.nim
open http://localhost:8080
python3 -m http.server 8080
