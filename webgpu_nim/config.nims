#########################################################
## henka-nimconf-26  WebGPU + Jolt Cubes demo           ##
## ISC License                                          ##
## Copyright (c) [2026] Ivan Mar (sOkam!) and RowDaBoat ##
##########################################################

import std/[strutils, os]

switch("define", "wgpu")
switch("backend", "cpp")

when defined(emscripten):
  --os:linux
  --cpu:wasm32
  --cc:clang
  --threads:off

  let emscriptenSdk = gorge("em-config EMSCRIPTEN_ROOT").strip()

  switch("clang.exe", emscriptenSdk / "emcc")
  switch("clang.linkerexe", emscriptenSdk / "emcc")
  switch("clang.cpp.exe", emscriptenSdk / "em++")
  switch("clang.cpp.linkerexe", emscriptenSdk / "em++")
  switch("passL", "-o build/cubes.js")
  --d:wasm
  --gc:orc
  --d:useMalloc

  let joltRoot = thisDir() / ".." / "jolt_nim"
  switch("passC", "-I" & (joltRoot / "src" / "JoltPhysics"))
  switch("passC", "-DJPH_OBJECT_STREAM")
  switch("passC", "-DJPH_USE_CPU_COMPUTE")
  switch("passC", "-DNDEBUG")
  switch("passC", "-std=c++17")
  switch("passL", joltRoot / "build" / "wasm" / "libJolt.a")
  switch("passL", "-sALLOW_MEMORY_GROWTH=1")
  switch("passL", "-sSTACK_SIZE=4194304")
  switch("passC", "-g")
  switch("passL", "-g")
  switch("passL", "-gsource-map")
  switch("passL", "-sASSERTIONS=2")
  switch("passL", "-sSAFE_HEAP=1")
  switch("passL", "-sSTACK_OVERFLOW_CHECK=2")
else:
  when defined(windows):
    switch("cc", "vcc")
  when defined(macosx):
    switch("passL", "-rpath @executable_path")

  let joltRoot = thisDir() / ".." / "jolt_nim"
  let joltLib  = joltRoot / "build" / "native" / "libJolt.a"
  let joltCCDB = joltRoot / "build" / "native" / "compile_commands.json"
  if fileExists(joltLib) and fileExists(joltCCDB):
    switch("passC", "-I" & (joltRoot / "src" / "JoltPhysics"))
    let extract = "import json,shlex,sys\n" &
      "db=json.load(open(sys.argv[1]))\n" &
      "e=next(x for x in db if '/Jolt/' in x['file'] and x['file'].endswith('.cpp'))\n" &
      "a=shlex.split(e['command']) if 'command' in e else e['arguments']\n" &
      "k=[f for f in a if f.startswith(('-D','-std=','-march','-mtune')) or " &
      "(f.startswith('-m') and any(s in f for s in ('sse','avx','f16c','fma','lzcnt','bmi','popcnt','neon')))]\n" &
      "print(' '.join(k))"
    let flags = gorge("python3 -c " & quoteShell(extract) & " " & quoteShell(joltCCDB)).strip()
    for f in flags.splitWhitespace():
      if not f.startsWith("-std="):
        switch("passC", f)
    switch("passL", joltLib)
