#:___________________________________________________________
#  henka-nimconf-26  |  WebGPU "Hello Triangle" demo  |  MIT  :
#:___________________________________________________________
# Renders a single hardcoded triangle with WebGPU.            |
# Vertices live in the shader, so there are no vertex buffers.|
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
#  The 8 corners and 36 indices (12 triangles) are hardcoded, so there are
#  still no vertex/index buffers. A small uniform feeds time + aspect ratio,
#  and the model/view/projection matrix is built right here in WGSL.
#_____________________________
const shaderCode = """
struct Uniforms {
  time   : f32,
  aspect : f32,
};
@group(0) @binding(0) var<uniform> u : Uniforms;

struct VSOut {
  @builtin(position) pos   : vec4<f32>,
  @location(0)       color : vec3<f32>,
};

fn rotateY(a :f32) ->mat3x3<f32> {
  let c = cos(a); let s = sin(a);
  return mat3x3<f32>(c, 0.0, -s,  0.0, 1.0, 0.0,  s, 0.0, c);
}
fn rotateX(a :f32) ->mat3x3<f32> {
  let c = cos(a); let s = sin(a);
  return mat3x3<f32>(1.0, 0.0, 0.0,  0.0, c, s,  0.0, -s, c);
}

@vertex
fn vs_main(@builtin(vertex_index) vid :u32) ->VSOut {
  var corners = array<vec3<f32>, 8>(
    vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>( 1.0, -1.0, -1.0),
    vec3<f32>( 1.0,  1.0, -1.0), vec3<f32>(-1.0,  1.0, -1.0),
    vec3<f32>(-1.0, -1.0,  1.0), vec3<f32>( 1.0, -1.0,  1.0),
    vec3<f32>( 1.0,  1.0,  1.0), vec3<f32>(-1.0,  1.0,  1.0),
  );
  var idx = array<u32, 36>(
    0u, 1u, 2u,  0u, 2u, 3u,   // back   (-z)
    4u, 6u, 5u,  4u, 7u, 6u,   // front  (+z)
    0u, 4u, 5u,  0u, 5u, 1u,   // bottom (-y)
    3u, 2u, 6u,  3u, 6u, 7u,   // top    (+y)
    0u, 3u, 7u,  0u, 7u, 4u,   // left   (-x)
    1u, 5u, 6u,  1u, 6u, 2u,   // right  (+x)
  );
  let p = corners[idx[vid]];

  // Model: spin around two axes. View: push the cube away from the camera.
  let world   = rotateY(u.time * 0.9) * rotateX(u.time * 0.6) * (p * 0.8);
  let viewPos = vec3<f32>(world.x, world.y, world.z - 4.0);

  // Right-handed perspective mapping depth to [0, 1] (WebGPU convention)
  let fovy = 1.0;
  let f    = 1.0 / tan(fovy * 0.5);
  let near = 0.1;
  let far  = 100.0;
  let nf   = 1.0 / (near - far);
  let proj = mat4x4<f32>(
    f / u.aspect, 0.0,        0.0,            0.0,
    0.0,          f,          0.0,            0.0,
    0.0,          0.0,        far * nf,      -1.0,
    0.0,          0.0,        far * near * nf, 0.0,
  );

  var out :VSOut;
  out.pos   = proj * vec4<f32>(viewPos, 1.0);
  out.color = p * 0.5 + vec3<f32>(0.5, 0.5, 0.5);  // color by corner
  return out;
}

@fragment
fn fs_main(in :VSOut) ->@location(0) vec4<f32> {
  return vec4<f32>(in.color, 1.0);
}
"""


#_______________________________________
# @section State
#  HTML canvas selector must match the <canvas id> in index.html.
#_____________________________
const
  canvasSelector       = "#triangle-canvas"
  title                = "WebGPU Cube"
  initialW :int32      = 960
  initialH :int32      = 540
  depthFormat          = TextureFormat.Depth24Plus

type Uniforms = object
  time   :float32
  aspect :float32

var
  instance  :Instance
  surface   :Surface
  adapter   :Adapter
  device    :Device
  pipeline  :RenderPipeline
  config    :SurfaceConfiguration
  uniforms  :Uniforms
  uniformBuf:Buffer
  bindGroup :BindGroup
  depthView :TextureView

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
  echo ":: Device ready. Building the render pipeline."

  # Surface capabilities decide the color format we render into
  let caps          = surface.capabilities(adapter)
  let surfaceFormat = caps.formats[0]
  let surfaceAlpha  = caps.alphaModes[0]

  let shaderDesc = wgsl.toDescriptor(shaderCode, label = "CubeShader")
  let shader     = device.create(shaderDesc.addr)
  doAssert shader != nil, "Failed to create the shader module"

  # Uniform buffer (time + aspect), bound to the vertex stage
  uniformBuf = device.create(vaddr BufferDescriptor(
    nextInChain      : nil,
    label            : "Uniforms".toStringView(),
    usage            : BufferUsage_Uniform or BufferUsage_CopyDst,
    size             : sizeof(Uniforms).uint64,
    mappedAtCreation : false.uint32,
    ))

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

  pipeline = device.create(vaddr RenderPipelineDescriptor(
    nextInChain               : nil,
    label                     : "Cube Pipeline".toStringView(),
    layout                    : pipelineLayout,
    vertex                    : VertexState(
      module                  : shader,
      entryPoint              : "vs_main".toStringView(),
      constantCount           : 0,
      constants               : nil,
      bufferCount             : 0,
      buffers                 : nil,
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
  echo &":: Surface configured at {config.width} x {config.height}. Rendering."

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

  # Advance the animation and upload the uniforms
  uniforms.time   += 0.016'f32
  uniforms.aspect  = config.width.float32 / config.height.float32
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
  renderPass.draw(36, 1, 0, 0)  # vertexCount, instanceCount, firstVertex, firstInstance
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
      label                       : "Triangle Device".toStringView(),
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
  echo "Hello WebGPU Triangle"

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
