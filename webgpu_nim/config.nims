import std/[strutils, os]

# WebGPU bindings: define pragmas are buggy on macOS, so set -d:wgpu here.
switch("define", "wgpu")
# This demo must be built with the C++ backend.
switch("backend", "cpp")

when defined(emscripten):
  --os:linux
  --cpu:wasm32
  --cc:clang
  # Single-threaded wasm. Nim defaults to threads:on, which makes Emscripten emit
  # -pthread and pull the shared-memory (SharedArrayBuffer) toolchain. Jolt is
  # built single-threaded to match, and dropping pthreads here also frees the page
  # from needing crossOriginIsolation (COOP/COEP) to instantiate.
  --threads:off

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

  # --- Jolt physics (prebuilt wasm static lib) ---------------------------------
  # Header include path + the exact compile defines the wasm libJolt.a was built
  # with (build via `jolt_nim/build_jolt.sh wasm`); these must match or the Jolt
  # struct layouts won't line up. No -msimd128 here, matching the lib.
  let joltRoot = thisDir() / ".." / "jolt_nim"
  switch("passC", "-I" & (joltRoot / "JoltPhysics"))
  switch("passC", "-DJPH_OBJECT_STREAM")
  switch("passC", "-DJPH_USE_CPU_COMPUTE")
  switch("passC", "-DNDEBUG")
  switch("passC", "-std=c++17")
  switch("passL", joltRoot / "build" / "wasm" / "libJolt.a")
  # Jolt's allocators push past the default 16 MB heap; let it grow.
  switch("passL", "-sALLOW_MEMORY_GROWTH=1")
  # With 0 worker threads Jolt runs every Update job inline on the calling
  # thread's stack, which overflows the 64 KB Emscripten default. Give it room.
  switch("passL", "-sSTACK_SIZE=4194304")

  # --- debug build: symbols + runtime memory checks --------------------------
  switch("passC", "-g")
  switch("passL", "-g")                       # DWARF + keep function names in traces
  switch("passL", "-gsource-map")             # map wasm back to the generated .cpp
  switch("passL", "-sASSERTIONS=2")           # verbose runtime asserts
  switch("passL", "-sSAFE_HEAP=1")            # traps the exact OOB access, with a message
  switch("passL", "-sSTACK_OVERFLOW_CHECK=2") # catches stack overflow specifically
else:
  when defined(windows):
    switch("cc", "vcc")
  when defined(macosx):
    switch("passL", "-rpath @executable_path")

  # --- Jolt physics (native static lib) ----------------------------------------
  # Mirrors the wasm wiring above for desktop builds. The native libJolt.a carries
  # arch-specific SIMD/ABI flags (SSE/AVX on x86, NEON on arm, Metal/Vulkan), so we
  # reuse the exact flags it was compiled with instead of hardcoding them — the same
  # extraction jolt_nim/build.sh does. Only activates once `build_jolt.sh native`
  # has produced the lib + compile_commands.json.
  let joltRoot = thisDir() / ".." / "jolt_nim"
  let joltLib  = joltRoot / "build" / "native" / "libJolt.a"
  let joltCCDB = joltRoot / "build" / "native" / "compile_commands.json"
  if fileExists(joltLib) and fileExists(joltCCDB):
    switch("passC", "-I" & (joltRoot / "JoltPhysics"))
    let extract = "import json,shlex,sys\n" &
      "db=json.load(open(sys.argv[1]))\n" &
      "e=next(x for x in db if '/Jolt/' in x['file'] and x['file'].endswith('.cpp'))\n" &
      "a=shlex.split(e['command']) if 'command' in e else e['arguments']\n" &
      "k=[f for f in a if f.startswith(('-D','-std=','-march','-mtune')) or " &
      "(f.startswith('-m') and any(s in f for s in ('sse','avx','f16c','fma','lzcnt','bmi','popcnt','neon')))]\n" &
      "print(' '.join(k))"
    let flags = gorge("python3 -c " & quoteShell(extract) & " " & quoteShell(joltCCDB)).strip()
    for f in flags.splitWhitespace():
      # Skip -std=: Nim already sets the C++ standard, and these flags are passed
      # to every unit including GLFW's .m and wgvk's .c, which reject -std=c++17.
      if not f.startsWith("-std="):
        switch("passC", f)
    switch("passL", joltLib)
