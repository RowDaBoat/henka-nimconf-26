import std/[strutils, os]

# WebGPU bindings: define pragmas are buggy on macOS, so set -d:wgpu here.
switch("define", "wgpu")
# This demo must be built with the C++ backend.
switch("backend", "cpp")

when defined(emscripten):
  --os:linux
  --cpu:wasm32
  --cc:clang

  let emscriptenSdk = gorge("em-config EMSCRIPTEN_ROOT").strip()

  switch("clang.exe", emscriptenSdk / "emcc")
  switch("clang.linkerexe", emscriptenSdk / "emcc")
  switch("clang.cpp.exe", emscriptenSdk / "em++")
  switch("clang.cpp.linkerexe", emscriptenSdk / "em++")

  # Emit cubes.js + cubes.wasm into build/, loaded by index.html.
  switch("passL", "-o build/cubes.js")
  --d:wasm
  --gc:orc
  --d:useMalloc
else:
  when defined(windows):
    switch("cc", "vcc")
  when defined(macosx):
    switch("passL", "-rpath @executable_path")
