#:___________________________________________________________
#  henka-nimconf-26  |  WebGPU Cubes demo  |  MIT             :
#:___________________________________________________________
# Renders a grid of cube instances with WebGPU.               |
# Geometry lives in real vertex/index buffers; per-cube world |
# offsets come from a per-instance vertex buffer. No rotation. |
#                                                             |
# Runs in two modes from the same source:                    |
#   * Native : GLFW window + wgpu  (blocking adapter/device)  |
#   * Web    : -d:emscripten, surface bound to an HTML canvas |
#             (async adapter/device, emscripten main loop)    |
#_____________________________________________________________|
# @deps std
import std/strformat
# @deps wgpu
import wgpu

when defined(emscripten):
  # The browser provides WebGPU and drives the render loop for us.
  proc emscripten_set_main_loop(
    f                 :proc() {.cdecl.};
    fps               :cint;
    simulateInfinite  :cint;
    ) {.importc, header:"<emscripten.h>".}
else:
  # @deps external
  from nglfw as glfw import nil


#_______________________________________
# @section Cube Shader
#  Geometry arrives through vertex buffers now; the shader only places each
#  cube (per-instance @location(2) offset) and applies the perspective camera.
#_____________________________
const shaderCode = """
struct Uniforms {
  aspect : f32,
};
@group(0) @binding(0) var<uniform> u : Uniforms;

struct VSIn {
  @location(0) position : vec3<f32>,
  @location(1) color    : vec3<f32>,
  @location(2) offset   : vec3<f32>,   // per-instance world position
};
struct VSOut {
  @builtin(position) pos   : vec4<f32>,
  @location(0)       color : vec3<f32>,
};

@vertex
fn vs_main(in :VSIn) ->VSOut {
  let world   = in.position + in.offset;
  let viewPos = vec3<f32>(world.x, world.y, world.z - 10.0);  // push away from camera

  // Right-handed perspective mapping depth to [0, 1] (WebGPU convention)
  let fovy = 1.0;
  let f    = 1.0 / tan(fovy * 0.5);
  let near = 0.1;
  let far  = 100.0;
  let nf   = 1.0 / (near - far);
  let proj = mat4x4<f32>(
    f / u.aspect, 0.0, 0.0,            0.0,
    0.0,          f,   0.0,            0.0,
    0.0,          0.0, far * nf,      -1.0,
    0.0,          0.0, far * near * nf, 0.0,
  );

  var out :VSOut;
  out.pos   = proj * vec4<f32>(viewPos, 1.0);
  out.color = in.color;
  return out;
}

@fragment
fn fs_main(in :VSOut) ->@location(0) vec4<f32> {
  return vec4<f32>(in.color, 1.0);
}
"""


#_______________________________________
# @section Geometry
#  8 corners (scaled), colored by corner. 36 indices = 12 triangles.
#_____________________________
type Vertex = object
  pos   :array[3, float32]
  color :array[3, float32]

const s = 0.7'f32
let cubeVertices = [
  Vertex(pos: [-s, -s, -s], color: [0.0, 0.0, 0.0]),
  Vertex(pos: [ s, -s, -s], color: [1.0, 0.0, 0.0]),
  Vertex(pos: [ s,  s, -s], color: [1.0, 1.0, 0.0]),
  Vertex(pos: [-s,  s, -s], color: [0.0, 1.0, 0.0]),
  Vertex(pos: [-s, -s,  s], color: [0.0, 0.0, 1.0]),
  Vertex(pos: [ s, -s,  s], color: [1.0, 0.0, 1.0]),
  Vertex(pos: [ s,  s,  s], color: [1.0, 1.0, 1.0]),
  Vertex(pos: [-s,  s,  s], color: [0.0, 1.0, 1.0]),
]

const cubeIndices = [
  0'u16, 1, 2,  0, 2, 3,   # back   (-z)
  4,     6, 5,  4, 7, 6,   # front  (+z)
  0,     4, 5,  0, 5, 1,   # bottom (-y)
  3,     2, 6,  3, 6, 7,   # top    (+y)
  0,     3, 7,  0, 7, 4,   # left   (-x)
  1,     5, 6,  1, 6, 2,   # right  (+x)
]

# One offset per cube: a 3x3 grid in the XY plane.
let instanceOffsets = block:
  var offs :seq[array[3, float32]]
  for gy in -1 .. 1:
    for gx in -1 .. 1:
      offs.add [gx.float32 * 3.0'f32, gy.float32 * 3.0'f32, 0.0'f32]
  offs


#_______________________________________
# @section State
#  HTML canvas selector must match the <canvas id> in index.html.
#_____________________________
const
  canvasSelector       = "#triangle-canvas"
  title                = "WebGPU Cubes"
  initialW :int32      = 960
  initialH :int32      = 540
  depthFormat          = TextureFormat.Depth24Plus

type Uniforms = object
  aspect :float32

var
  instance   :Instance
  surface    :Surface
  adapter    :Adapter
  device     :Device
  pipeline   :RenderPipeline
  config     :SurfaceConfiguration
  uniforms   :Uniforms
  uniformBuf :Buffer
  bindGroup  :BindGroup
  depthView  :TextureView
  vertexBuf  :Buffer
  indexBuf   :Buffer
  instanceBuf:Buffer

when not defined(emscripten):
  var window :glfw.Window


#_______________________________________
# @section WGPU Callbacks
#_____________________________
proc adapterRequestCB *(status :RequestAdapterStatus; got :Adapter; message :StringView; userdata1, userdata2 :pointer) :void {.cdecl.}
proc deviceRequestCB  *(status :RequestDeviceStatus;  got :Device;  message :StringView; userdata1, userdata2 :pointer) :void {.cdecl.}
#__________________
proc errorCB *(device :ptr Device; typ :ErrorType; message :StringView; userdata1, userdata2 :pointer) :void {.cdecl.}=
  echo &"UNCAPTURED ERROR ({$typ}): {$message}"
#__________________
proc deviceLostCB *(device :ptr Device; reason :DeviceLostReason; message :StringView; userdata1, userdata2 :pointer) :void {.cdecl.}=
  echo &"DEVICE LOST ({$reason}): {$message}"


#_______________________________________
# @section Forward Declarations
#  These continue the init chain on the web, where everything is async.
#_____________________________
proc requestDevice ()
proc onDeviceReady ()
proc drawFrame     () {.cdecl.}


#_______________________________________
# @section Pipeline + Surface Setup
#  Called once the Device is ready, on both platforms.
#_____________________________
proc onDeviceReady=
  echo ":: Device ready. Building buffers and the render pipeline."
  let queue = device.getQueue()

  # Surface capabilities decide the color format we render into
  let caps          = surface.capabilities(adapter)
  let surfaceFormat = caps.formats[0]
  let surfaceAlpha  = caps.alphaModes[0]

  let shaderDesc = wgsl.toDescriptor(shaderCode, label = "CubeShader")
  let shader     = device.create(shaderDesc.addr)
  doAssert shader != nil, "Failed to create the shader module"

  # --- Geometry + instance buffers ---
  let vertexBytes   = (cubeVertices.len    * sizeof(Vertex)).uint64
  let indexBytes    = (cubeIndices.len     * sizeof(uint16)).uint64
  let instanceBytes = (instanceOffsets.len * sizeof(array[3, float32])).uint64

  vertexBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Cube Vertices".toStringView(),
    usage: BufferUsage_Vertex or BufferUsage_CopyDst, size: vertexBytes, mappedAtCreation: false.uint32))
  indexBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Cube Indices".toStringView(),
    usage: BufferUsage_Index or BufferUsage_CopyDst, size: indexBytes, mappedAtCreation: false.uint32))
  instanceBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Instance Offsets".toStringView(),
    usage: BufferUsage_Vertex or BufferUsage_CopyDst, size: instanceBytes, mappedAtCreation: false.uint32))

  queue.write(vertexBuf,   0, cubeVertices[0].addr,    vertexBytes.csize_t)
  queue.write(indexBuf,    0, cubeIndices[0].unsafeAddr, indexBytes.csize_t)
  queue.write(instanceBuf, 0, instanceOffsets[0].addr, instanceBytes.csize_t)

  # --- Uniform buffer (aspect ratio), bound to the vertex stage ---
  uniformBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Uniforms".toStringView(),
    usage: BufferUsage_Uniform or BufferUsage_CopyDst, size: sizeof(Uniforms).uint64, mappedAtCreation: false.uint32))

  let bindGroupLayout = device.createLayout(vaddr BindGroupLayoutDescriptor(
    nextInChain : nil,
    label       : "Uniforms Layout".toStringView(),
    entryCount  : 1,
    entries     : vaddr BindGroupLayoutEntry(
      nextInChain : nil,
      binding     : 0,
      visibility  : ShaderStage_Vertex,
      buffer      : BufferBindingLayout(`type`: BufferBindingType.Uniform),
      ),
    ))

  bindGroup = device.create(vaddr BindGroupDescriptor(
    nextInChain : nil,
    label       : "Uniforms Bind Group".toStringView(),
    layout      : bindGroupLayout,
    entryCount  : 1,
    entries     : vaddr BindGroupEntry(
      nextInChain : nil,
      binding     : 0,
      buffer      : uniformBuf,
      offset      : 0,
      size        : sizeof(Uniforms).uint64,
      ),
    ))

  let pipelineLayout = device.create(vaddr PipelineLayoutDescriptor(
    nextInChain          : nil,
    label                : "Cube Pipeline Layout".toStringView(),
    bindGroupLayoutCount : 1,
    bindGroupLayouts     : vaddr bindGroupLayout,
    ))

  # --- Vertex layout: buffer 0 = per-vertex (pos, color), buffer 1 = per-instance (offset) ---
  var vertexAttrs = [
    VertexAttribute(format: VertexFormat.Float32x3, offset:  0, shaderLocation: 0),  # position
    VertexAttribute(format: VertexFormat.Float32x3, offset: 12, shaderLocation: 1),  # color
  ]
  var instanceAttrs = [
    VertexAttribute(format: VertexFormat.Float32x3, offset: 0, shaderLocation: 2),   # offset
  ]
  var vertexLayouts = [
    VertexBufferLayout(stepMode: VertexStepMode.Vertex,   arrayStride: sizeof(Vertex).uint64,           attributeCount: 2, attributes: vertexAttrs[0].addr),
    VertexBufferLayout(stepMode: VertexStepMode.Instance, arrayStride: sizeof(array[3,float32]).uint64, attributeCount: 1, attributes: instanceAttrs[0].addr),
  ]

  pipeline = device.create(vaddr RenderPipelineDescriptor(
    nextInChain               : nil,
    label                     : "Cube Pipeline".toStringView(),
    layout                    : pipelineLayout,
    vertex                    : VertexState(
      module                  : shader,
      entryPoint              : "vs_main".toStringView(),
      constantCount           : 0,
      constants               : nil,
      bufferCount             : 2,
      buffers                 : vertexLayouts[0].addr,
      ), #:: vertex
    primitive                 : PrimitiveState(
      nextInChain             : nil,
      topology                : PrimitiveTopology.TriangleList,
      stripIndexFormat        : IndexFormat.Undefined,
      frontFace               : FrontFace.CCW,
      cullMode                : CullMode.None,  # depth test handles occlusion, so winding is irrelevant
      ), #:: primitive
    depthStencil              : vaddr DepthStencilState(
      nextInChain             : nil,
      format                  : depthFormat,
      depthWriteEnabled       : OptionalBool.True,
      depthCompare            : CompareFunction.Less,
      stencilFront            : StencilFaceState(compare: CompareFunction.Always, failOp: StencilOperation.Keep, depthFailOp: StencilOperation.Keep, passOp: StencilOperation.Keep),
      stencilBack             : StencilFaceState(compare: CompareFunction.Always, failOp: StencilOperation.Keep, depthFailOp: StencilOperation.Keep, passOp: StencilOperation.Keep),
      stencilReadMask         : 0,
      stencilWriteMask        : 0,
      ), #:: depthStencil
    multisample               : MultisampleState(
      nextInChain             : nil,
      count                   : 1,
      mask                    : uint32.high,
      alphaToCoverageEnabled  : false.uint32,
      ), #:: multisample
    fragment                  : vaddr FragmentState(
      nextInChain             : nil,
      module                  : shader,
      entryPoint              : "fs_main".toStringView(),
      constantCount           : 0,
      constants               : nil,
      targetCount             : 1,
      targets                 : vaddr ColorTargetState(
        nextInChain           : nil,
        format                : surfaceFormat,
        blend                 : vaddr BlendState(
          alpha               : BlendComponent(
            operation         : BlendOperation.Add,
            srcFactor         : BlendFactor.One,
            dstFactor         : BlendFactor.Zero,
            ), #:: alpha
          color               : BlendComponent(
            operation         : BlendOperation.Add,
            srcFactor         : BlendFactor.One,
            dstFactor         : BlendFactor.Zero,
            ), #:: color
          ), #:: blend
        writeMask             : ColorWrite.All,
        ), #:: targets
      ), #:: fragment
    )) #:: pipeline
  doAssert pipeline != nil, "Failed to create the render pipeline"

  # Configure the surface (the equivalent of an OpenGL swapchain)
  config = SurfaceConfiguration(
    nextInChain     : nil,
    device          : device,
    format          : surfaceFormat,
    usage           : wgpu.extras.TextureUsage.RenderAttachment,
    width           : initialW.uint32,
    height          : initialH.uint32,
    viewFormatCount : 0,
    viewFormats     : nil,
    alphaMode       : surfaceAlpha,
    presentMode     : Fifo,
    ) #:: SurfaceConfiguration
  when not defined(emscripten):
    glfw.getWindowSize(window, config.width.iaddr, config.height.iaddr)
  surface.configure(config.addr)

  # Depth buffer, sized to the surface (canvas is fixed-size on the web)
  let depthTex = device.create(vaddr TextureDescriptor(
    nextInChain     : nil,
    label           : "Depth Texture".toStringView(),
    usage           : wgpu.extras.TextureUsage.RenderAttachment,
    dimension       : TextureDimension.D2D,
    size            : Extent3D(width: config.width, height: config.height, depthOrArrayLayers: 1),
    format          : depthFormat,
    mipLevelCount   : 1,
    sampleCount     : 1,
    viewFormatCount : 0,
    viewFormats     : nil,
    ))
  depthView = depthTex.create(nil)
  echo &":: Surface configured at {config.width} x {config.height}. Rendering {instanceOffsets.len} cubes."

  when defined(emscripten):
    # Hand the render loop over to the browser (fps 0 = use requestAnimationFrame)
    emscripten_set_main_loop(drawFrame, 0.cint, 1.cint)


#_______________________________________
# @section Render
#_____________________________
proc drawFrame=
  var surfaceTexture = SurfaceTexture()
  surface.getCurrentTexture(surfaceTexture.addr)
  case surfaceTexture.status
  of SuccessOptimal, SuccessSuboptimal: discard
  of Timeout, Outdated, Lost:
    # Re-configure the surface to the (possibly new) window size, then skip the frame
    if surfaceTexture.texture != nil: surfaceTexture.texture.release()
    when not defined(emscripten):
      glfw.getWindowSize(window, config.width.iaddr, config.height.iaddr)
      surface.configure(config.addr)
    return
  else:
    echo $surfaceTexture.status, ": surface.getCurrentTexture() failed"
    return

  let queue = device.getQueue()

  # Keep the aspect ratio in sync and upload it
  uniforms.aspect = config.width.float32 / config.height.float32
  queue.write(uniformBuf, 0, uniforms.addr, sizeof(Uniforms).csize_t)

  let view = surfaceTexture.texture.create(nil)
  var encoder = device.create(vaddr CommandEncoderDescriptor(
    nextInChain : nil,
    label       : "Cube Command Encoder".toStringView(),
    ))

  var renderPassDesc = RenderPassDescriptor(
    nextInChain            : nil,
    label                  : "Cube Render Pass".toStringView(),
    colorAttachmentCount   : 1,
    colorAttachments       : vaddr RenderPassColorAttachment(
      view                 : view,
      depthSlice           : priv_DEPTH_SLICE_UNDEFINED,  # required by Dawn for non-3D attachments
      resolveTarget        : nil,
      loadOp               : Clear,
      storeOp              : Store,
      clearValue           : Color(r:0.1, g:0.1, b:0.1, a:1.0),
      ), #:: colorAttachments
    depthStencilAttachment : vaddr RenderPassDepthStencilAttachment(
      nextInChain          : nil,
      view                 : depthView,
      depthLoadOp          : Clear,
      depthStoreOp         : Store,
      depthClearValue      : 1.0,
      depthReadOnly        : 0,
      ), #:: depthStencilAttachment
    occlusionQuerySet      : nil,
    timestampWrites        : nil,
    ) #:: renderPassDesc

  var renderPass = encoder.begin(renderPassDesc.addr)
  renderPass.set(pipeline)
  renderPass.set(0, bindGroup, 0, nil)
  renderPass.setVertexBuffer(0, vertexBuf,   0, (cubeVertices.len    * sizeof(Vertex)).uint64)
  renderPass.setVertexBuffer(1, instanceBuf, 0, (instanceOffsets.len * sizeof(array[3, float32])).uint64)
  renderPass.setIndexBuffer(indexBuf, IndexFormat.Uint16, 0, (cubeIndices.len * sizeof(uint16)).uint64)
  renderPass.drawIndexed(cubeIndices.len.uint32, instanceOffsets.len.uint32, 0, 0, 0)
  renderPass.End()
  view.release()

  let cmdBuffer = encoder.finish(vaddr CommandBufferDescriptor(
    nextInChain : nil,
    label       : "Cube Command Buffer".toStringView(),
    ))
  queue.submit(1, cmdBuffer.addr)

  # The browser presents the canvas automatically; only native needs an explicit present.
  when not defined(emscripten):
    let status = surface.present()
    if status != Success: echo "ERR:: Surface.present() failed with: ", $status


#_______________________________________
# @section Device Request
#  Shared descriptor; native blocks on the future, web continues via callback.
#_____________________________
proc requestDevice=
  let deviceFuture = adapter.request(
    options = vaddr DeviceDescriptor(
      nextInChain                 : nil,
      label                       : "Cube Device".toStringView(),
      requiredFeatureCount        : 0,
      requiredFeatures            : nil,
      requiredLimits              : nil,
      defaultQueue                : QueueDescriptor(
        nextInChain               : nil,
        label                     : "Default Queue".toStringView(),
        ), #:: defaultQueue
      deviceLostCallbackInfo      : deviceLostCallbackInfo(
        callback  = deviceLostCB,
        userdata1 = device.addr,
        ), #:: deviceLostCallbackInfo
      uncapturedErrorCallbackInfo : uncapturedErrorCallbackInfo(
        callback  = errorCB,
        userdata1 = device.addr,
        ), #:: uncapturedErrorCallbackInfo
      ), #:: DeviceDescriptor
    callbackInfo                  = RequestDeviceCallbackInfo(
      nextInChain : nil,
      mode        : AllowSpontaneous,
      callback    : deviceRequestCB,
      userdata1   : device.addr,
      userdata2   : nil,
      ), #:: callbackInfo
    ) #:: adapter.request

  when not defined(emscripten):
    var waitInfo = FutureWaitInfo(future: deviceFuture, completed: 0)
    doAssert instance.wait(1, waitInfo.addr, uint64.high) == Success, "Failed to wait for the device request"
    doAssert device != nil, "Failed to get the device"
    onDeviceReady()


#_______________________________________
# @section Callback Bodies
#_____________________________
proc adapterRequestCB(status :RequestAdapterStatus; got :Adapter; message :StringView; userdata1, userdata2 :pointer) :void=
  doAssert status == Success, &"Adapter request failed ({$status}): {$message}"
  adapter = got
  when defined(emscripten):
    requestDevice()
#__________________
proc deviceRequestCB(status :RequestDeviceStatus; got :Device; message :StringView; userdata1, userdata2 :pointer) :void=
  doAssert status == Success, &"Device request failed ({$status}): {$message}"
  device = got
  when defined(emscripten):
    onDeviceReady()


#_______________________________________
# @section Entry Point
#_____________________________
proc run=
  echo "Hello WebGPU Cubes"

  # Init the instance + surface
  instance = wgpu.create(vaddr InstanceDescriptor(nextInChain: nil))
  doAssert instance != nil, "Could not initialize wgpu"

  when defined(emscripten):
    surface = instance.getSurfaceEmscripten(canvasSelector)
  else:
    doAssert glfw.init().bool, "Failed to initialize GLFW"
    glfw.windowHint(glfw.CLIENT_API, glfw.NO_API)
    window = glfw.createWindow(initialW, initialH, title.cstring, nil, nil)
    doAssert window != nil, "Failed to create the GLFW window"
    surface = instance.getSurface(window)
  doAssert surface != nil, "Failed to create the surface"

  # Request the adapter
  let adapterFuture = instance.request(
    options                = vaddr RequestAdapterOptions(
      nextInChain          : nil,
      featureLevel         : Core,
      powerPreference      : HighPerformance,
      forceFallbackAdapter : false.uint32,
      backendType          : Undefined,
      compatibleSurface    : surface,
      ), #:: RequestAdapterOptions
    callbackInfo           = RequestAdapterCallbackInfo(
      nextInChain : nil,
      mode        : AllowSpontaneous,
      callback    : adapterRequestCB,
      userdata1   : adapter.addr,
      userdata2   : nil,
      ), #:: RequestAdapterCallbackInfo
    ) #:: instance.request

  when defined(emscripten):
    # The adapter -> device -> pipeline chain runs asynchronously from here,
    # driven by the browser event loop. run() simply returns.
    discard adapterFuture
  else:
    var waitInfo = FutureWaitInfo(future: adapterFuture, completed: 0)
    doAssert instance.wait(1, waitInfo.addr, uint64.high) == Success, "Failed to wait for the adapter request"
    doAssert adapter != nil, "Failed to get the adapter"

    let info = adapter.info()
    echo ":: Adapter: ", info.device, " (", $info.backendType, ")"

    requestDevice()  # blocks, then calls onDeviceReady()

    # Native render loop
    while not glfw.windowShouldClose(window).bool:
      glfw.pollEvents()
      drawFrame()

    glfw.destroyWindow(window)
    glfw.terminate()

#__________________
when isMainModule: run()
