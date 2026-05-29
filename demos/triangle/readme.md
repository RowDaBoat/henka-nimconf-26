# WebGPU Triangle

A "Hello Triangle" WebGPU demo in Nim, ported from the `webgpu/examples/e02_hellotriangle`
sample. The same source runs natively (GLFW + wgpu) and on the web (Emscripten + the
browser's WebGPU). Triangle vertices are hardcoded in the shader, so there are no buffers.

Built with the **C++ backend** (`nim cpp`). Dependencies `webgpu` and `nglfw` are resolved
through the workspace-level `nim.cfg`.

## Web (Emscripten)

```sh
nim cpp -d:emscripten triangle.nim      # emits build/triangle.js + build/triangle.wasm
python3 -m http.server                  # serve this folder
```

Then open `http://localhost:8000/index.html` in a WebGPU-capable browser. The surface is
bound to the `#triangle-canvas` element in `index.html`; adapter/device are requested
asynchronously and the render loop is driven by `emscripten_set_main_loop`.

## Native

```sh
nim cpp -o:build/triangle-native triangle.nim
./build/triangle-native
```

Opens a GLFW window. Adapter/device are requested with blocking waits and the render loop
is a plain `while not windowShouldClose` loop.
