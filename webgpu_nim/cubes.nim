##########################################################
## henka-nimconf-26  WebGPU + Jolt Cubes demo           ##
## ISC License                                          ##
## Copyright (c) [2026] Ivan Mar (sOkam!) and RowDaBoat ##
##########################################################

# @deps std
import std/[math, random, strformat]
# @deps wgpu
import wgpu
import jolt, jolt_adhoc
import emscripten_adhoc


{.emit: """/*INCLUDESECTION*/
#include <emscripten.h>
#include <Jolt/Jolt.h>
#include <Jolt/Core/TempAllocator.h>
#include <Jolt/Core/JobSystemThreadPool.h>
#include <Jolt/Physics/PhysicsSystem.h>
#include <Jolt/Physics/Body/BodyCreationSettings.h>
#include <Jolt/Physics/Collision/Shape/BoxShape.h>
#include <Jolt/Physics/Collision/ObjectLayerPairFilterTable.h>
#include <Jolt/Physics/Collision/BroadPhase/BroadPhaseLayerInterfaceTable.h>
#include <Jolt/Physics/Collision/BroadPhase/ObjectVsBroadPhaseLayerFilterTable.h>
""".}


##############################
## Geometry and Render Data ##
##############################
const
  camDist        = 10.0'f32
  fovY           = 1.0'f32
  cubeSize       = 0.8'f32
  lightZ         = 4.0'f32
  initialW       = 960'i32
  initialH       = 540'i32
  renderScale    = 2'i32
  shaderCode     = staticRead("shaders.wgsl")
  canvasSelector = "#cubes-canvas"
  title          = "WebGPU Cubes"
  depthFormat    = TextureFormat.Depth24Plus

type Vertex = object
  pos {.align: 16.} :array[4, float32]

type CubeInstance = object
  transform {.align: 16.} :Mat44

type Uniforms = object
  aspect  : float32
  ambient : float32
  light   {.align: 16.} : array[4, float32]

const
  s = cubeSize
  cubeVertices = [
    Vertex(pos: [-s, -s, -s, 0]), Vertex(pos: [ s, -s, -s, 0]),
    Vertex(pos: [ s,  s, -s, 0]), Vertex(pos: [-s,  s, -s, 0]),
    Vertex(pos: [-s, -s,  s, 0]), Vertex(pos: [ s, -s,  s, 0]),
    Vertex(pos: [ s,  s,  s, 0]), Vertex(pos: [-s,  s,  s, 0]),
  ]
  cubeIndices = [
    0'u16, 1, 2,  0, 2, 3, # back   (-z)
        4, 6, 5,  4, 7, 6, # front  (+z)
        0, 4, 5,  0, 5, 1, # bottom (-y)
        3, 2, 6,  3, 6, 7, # top    (+y)
        0, 3, 7,  0, 7, 4, # left   (-x)
        1, 5, 6,  1, 6, 2, # right  (+x)
  ]

var
  instance    : Instance
  surface     : Surface
  adapter     : Adapter
  device      : Device
  pipeline    : RenderPipeline
  config      : SurfaceConfiguration
  uniforms    : Uniforms
  uniformBuf  : Buffer
  bindGroup   : BindGroup
  depthView   : TextureView
  vertexBuf   : Buffer
  indexBuf    : Buffer
  instanceBuf : Buffer


##################
## Physics Data ##
##################
const
  layerNonMoving = 0.cushort
  layerMoving    = 1.cushort
  bpNonMoving    = 0.uint8
  bpMoving       = 1.uint8
  motionStatic   = 0.cint
  motionDynamic  = 2.cint
  activate       = 0.cint
  dontActivate   = 1.cint

var
  physics       : ptr PhysicsSystem       = nil
  tempAllocator : ptr TempAllocatorImpl   = nil
  jobSystem     : ptr JobSystemThreadPool = nil
  bodies        : ptr BodyInterface       = nil
  cubes         : array[50, BodyID]
  instances     : seq[CubeInstance]


###############
## Time Data ##
###############
const fixedDt = 1.0'f32 / 60.0'f32

var
  lastMs      = 0.0'f32
  accumulator = 0.0'f32
  paused      = true


############################
## Javascript Integration ##
############################
{.emit: """
EM_JS(float, mouse_x, (), { return window.__mx || 0.0; });
EM_JS(float, mouse_y, (), { return window.__my || 0.0; });
EM_JS(int, sim_started, (), {
  if (window.__started === undefined) {
    window.__started = 0;
    window.addEventListener("keydown", function (e) {
      if (e.key === "Enter") window.__started = 1;
    });
  }
  return window.__started;
});
""".}
proc mouse_x() :cfloat {.importc, nodecl.}
proc mouse_y() :cfloat {.importc, nodecl.}
proc sim_started() :cint {.importc, nodecl.}


########################
## Cube Creation Code ##
########################
proc createCubeInstances(): seq[CubeInstance] =
  const gridCols = 10
  const gridRows = 5
  const spacing  = 1.9'f32

  var rng = initRand(20260528)

  template rf(lo, hi :float32): float32 = lo + rng.rand(1.0).float32 * (hi - lo)

  for row in 0 ..< gridRows:
    for col in 0 ..< gridCols:
      let x = (col.float32 - (gridCols.float32 - 1.0'f32) * 0.5'f32) * spacing
      let y = (row.float32 - (gridRows.float32 - 1.0'f32) * 0.5'f32) * spacing + 18.0'f32
      let z = row.float32 * 0.25'f32
      let t = Mat44.sTranslation(cast[Vec3Arg](Vec3_create(x, y, z)))
      let r = Mat44.sRotation(cast[QuatArg](Quat.sEulerAngles(cast[Vec3Arg](Vec3_create(rf(0.0, TAU), rf(0.0, TAU), rf(0.0, TAU))))))
      result.add CubeInstance(transform: t * r)

proc instancesBytes(): uint64 =
  (instances.len * sizeof(CubeInstance)).uint64


##################
## Physics Code ##
##################
proc initJoltPhysics =
  RegisterDefaultAllocator()
  var factory: Factory
  Factory.sInstance = addr factory
  RegisterTypes()

  tempAllocator = newTempAllocator(10 * 1024 * 1024)
  jobSystem = newJobSystem(2048, 8, 2)

  let objectLayerPairFilter = newObjectLayerPairFilterTable(2)
  objectLayerPairFilter.enableCollision(layerMoving, layerNonMoving)
  objectLayerPairFilter.enableCollision(layerMoving, layerMoving)

  let broadPhaseLayerInterface = newBroadPhaseLayerInterfaceTable(2, 2)
  broadPhaseLayerInterface.mapObjectToBroadPhaseLayer(layerNonMoving, bpNonMoving)
  broadPhaseLayerInterface.mapObjectToBroadPhaseLayer(layerMoving, bpMoving)

  let objectVsBroadPhaseLayerFilter = newObjectVsBroadPhaseLayerFilterTable(
    broadPhaseLayerInterface, 2, objectLayerPairFilter, 2
  )

  physics = newPhysicsSystem()
  physics.init(1024, 0, 1024, 1024, broadPhaseLayerInterface, objectVsBroadPhaseLayerFilter, objectLayerPairFilter)
  bodies = physics.getBodyInterface()

  let floorShape = newBoxShape(Vec3_create(50.0, 0.05, 50.0), 0.04)
  let floorSettings = newBodyCreationSettings(
    floorShape, Vec3_create(0.0, -4.0, 0.0), Quat.sIdentity(), motionStatic, layerNonMoving
  )
  discard bodies.createAndAddBody(floorSettings, dontActivate)

  for (id, instance) in instances.pairs:
    let position = instance.transform.GetTranslation()
    let rotation = instance.transform.GetQuaternion()
    let cubeShape = newBoxShape(Vec3_create(cubeSize, cubeSize, cubeSize), 0.05)
    let cubeSettings = newBodyCreationSettings(cubeShape, position, rotation, motionDynamic, layerMoving)
    cubes[id] = bodies.createAndAddBody(cubeSettings, activate)

  physics.optimizeBroadPhase()

proc updatePhysics =
  let now = emscripten_get_now()
  let dt  = float32((now - lastMs) / 1000.0)
  lastMs = now

  if paused:
    if sim_started() != 0: paused = false
    return

  accumulator += dt

  while accumulator >= fixedDt:
    physics.update(fixedDt, 10.cint, tempAllocator, jobSystem)
    accumulator -= fixedDt

    for (id, instance) in instances.mpairs:
      instance.transform = bodies.getCenterOfMassTransform(cubes[id])


###################
## Graphics Code ##
###################
proc adapterRequestCB*(status :RequestAdapterStatus; got :Adapter; message :StringView; userdata1, userdata2 :pointer) :void {.cdecl.}

proc deviceRequestCB*(status :RequestDeviceStatus;  got :Device;  message :StringView; userdata1, userdata2 :pointer) :void {.cdecl.}

proc errorCB*(device :ptr Device; typ :ErrorType; message :StringView; userdata1, userdata2 :pointer) :void {.cdecl.}=
  echo &"UNCAPTURED ERROR ({$typ}): {$message}"

proc deviceLostCB*(device :ptr Device; reason :DeviceLostReason; message :StringView; userdata1, userdata2 :pointer) :void {.cdecl.}=
  echo &"DEVICE LOST ({$reason}): {$message}"

proc drawFrame() {.cdecl.}

proc onDeviceReady=
  echo ":: Device ready. Building buffers and the render pipeline."
  let queue = device.getQueue()

  let caps          = surface.capabilities(adapter)
  let surfaceFormat = caps.formats[0]
  let surfaceAlpha  = caps.alphaModes[0]
  let shaderDesc    = wgsl.toDescriptor(shaderCode, label = "CubeShader")
  let shader        = device.create(shaderDesc.addr)
  doAssert shader != nil, "Failed to create the shader module"
  let vertexBytes   = (cubeVertices.len * sizeof(Vertex)).uint64
  let indexBytes    = (cubeIndices.len  * sizeof(uint16)).uint64

  vertexBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Cube Vertices".toStringView(),
    usage: BufferUsage_Vertex or BufferUsage_CopyDst, size: vertexBytes, mappedAtCreation: false.uint32))

  indexBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Cube Indices".toStringView(),
    usage: BufferUsage_Index or BufferUsage_CopyDst, size: indexBytes, mappedAtCreation: false.uint32))

  instanceBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Instances".toStringView(),
    usage: BufferUsage_Uniform or BufferUsage_CopyDst, size: instancesBytes(), mappedAtCreation: false.uint32))

  queue.write(vertexBuf,   0, cubeVertices[0].unsafeAddr, vertexBytes.csize_t)
  queue.write(indexBuf,    0, cubeIndices[0].unsafeAddr,  indexBytes.csize_t)
  queue.write(instanceBuf, 0, instances[0].unsafeAddr,    instancesBytes().csize_t)

  uniformBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Uniforms".toStringView(),
    usage: BufferUsage_Uniform or BufferUsage_CopyDst, size: sizeof(Uniforms).uint64, mappedAtCreation: false.uint32))

  let bindGroupLayoutEntries = @[
    BindGroupLayoutEntry(
      nextInChain : nil,
      binding     : 0,
      visibility  : ShaderStage_Vertex or ShaderStage_Fragment,
      buffer      : BufferBindingLayout(`type`: BufferBindingType.Uniform),
      ),
    BindGroupLayoutEntry(
      nextInChain : nil,
      binding     : 1,
      visibility  : ShaderStage_Vertex or ShaderStage_Fragment,
      buffer      : BufferBindingLayout(`type`: BufferBindingType.Uniform),
      ),
  ]
  let bindGroupLayout = device.createLayout(vaddr BindGroupLayoutDescriptor(
    nextInChain : nil,
    label       : "Uniforms Layout".toStringView(),
    entryCount  : bindGroupLayoutEntries.len.uint32,
    entries     : bindGroupLayoutEntries[0].addr
  ))

  let bindGroupEntries = @[
    BindGroupEntry(
      nextInChain : nil,
      binding     : 0,
      buffer      : uniformBuf,
      offset      : 0,
      size        : sizeof(Uniforms).uint64,
      ),
    BindGroupEntry(
      nextInChain : nil,
      binding     : 1,
      buffer      : instanceBuf,
      offset      : 0,
      size        : sizeof(CubeInstance).uint64 * instances.len.uint64,
      )
  ]
  bindGroup = device.create(vaddr BindGroupDescriptor(
    nextInChain : nil,
    label       : "Uniforms Bind Group".toStringView(),
    layout      : bindGroupLayout,
    entryCount  : bindGroupEntries.len.uint32,
    entries     : bindGroupEntries[0].addr
  ))

  let pipelineLayout = device.create(vaddr PipelineLayoutDescriptor(
    nextInChain          : nil,
    label                : "Cube Pipeline Layout".toStringView(),
    bindGroupLayoutCount : 1,
    bindGroupLayouts     : vaddr bindGroupLayout,
    ))

  var vertexAttrs = [
    VertexAttribute(
      format: VertexFormat.Float32x3,
      offset: 0,
      shaderLocation: 0,
    ),
  ]
  var vertexLayouts = [
    VertexBufferLayout(
      stepMode: VertexStepMode.Vertex,
      arrayStride: sizeof(Vertex).uint64,
      attributeCount: 1,
      attributes: vertexAttrs[0].addr
    ),
  ]

  pipeline = device.create(vaddr RenderPipelineDescriptor(
    nextInChain  : nil,
    label        : "Cube Pipeline".toStringView(),
    layout       : pipelineLayout,
    vertex       : VertexState(
      module        : shader,
      entryPoint    : "vs_main".toStringView(),
      constantCount : 0,
      constants     : nil,
      bufferCount   : 1,
      buffers       : vertexLayouts[0].addr,
    ),
    primitive    : PrimitiveState(
      nextInChain      : nil,
      topology         : PrimitiveTopology.TriangleList,
      stripIndexFormat : IndexFormat.Undefined,
      frontFace        : FrontFace.CCW,
      cullMode         : CullMode.None,
    ),
    depthStencil : vaddr DepthStencilState(
      nextInChain             : nil,
      format                  : depthFormat,
      depthWriteEnabled       : OptionalBool.True,
      depthCompare            : CompareFunction.Less,
      stencilFront            : StencilFaceState(compare: CompareFunction.Always, failOp: StencilOperation.Keep, depthFailOp: StencilOperation.Keep, passOp: StencilOperation.Keep),
      stencilBack             : StencilFaceState(compare: CompareFunction.Always, failOp: StencilOperation.Keep, depthFailOp: StencilOperation.Keep, passOp: StencilOperation.Keep),
      stencilReadMask         : 0,
      stencilWriteMask        : 0,
    ),
    multisample  : MultisampleState(
      nextInChain            : nil,
      count                  : 1,
      mask                   : uint32.high,
      alphaToCoverageEnabled : false.uint32,
    ),
    fragment     : vaddr FragmentState(
      nextInChain   : nil,
      module        : shader,
      entryPoint    : "fs_main".toStringView(),
      constantCount : 0,
      constants     : nil,
      targetCount   : 1,
      targets       : vaddr ColorTargetState(
        nextInChain : nil,
        format      : surfaceFormat,
        blend       : vaddr BlendState(
          alpha : BlendComponent(
            operation : BlendOperation.Add,
            srcFactor : BlendFactor.One,
            dstFactor : BlendFactor.Zero,
          ),
          color : BlendComponent(
            operation : BlendOperation.Add,
            srcFactor : BlendFactor.One,
            dstFactor : BlendFactor.Zero,
          ),
        ),
        writeMask   : ColorWrite.All,
      ),
    ),
  ))
  doAssert pipeline != nil, "Failed to create the render pipeline"

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
    )

  config.width  = (initialW * renderScale).uint32
  config.height = (initialH * renderScale).uint32
  surface.configure(config.addr)

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
  echo &":: Surface configured at {config.width} x {config.height}. Rendering {instances.len} cubes."
  emscripten_set_main_loop(drawFrame, 0.cint, 1.cint)

proc updateGraphics =
  var surfaceTexture = SurfaceTexture()
  surface.getCurrentTexture(surfaceTexture.addr)
  case surfaceTexture.status
  of SuccessOptimal, SuccessSuboptimal: discard
  of Timeout, Outdated, Lost:
    if surfaceTexture.texture != nil: surfaceTexture.texture.release()
    return
  else:
    echo $surfaceTexture.status, ": surface.getCurrentTexture() failed"
    return

  let mx           = mouse_x().float32
  let my           = mouse_y().float32
  let aspect       = config.width.float32 / config.height.float32
  let halfH        = camDist * tan(fovY * 0.5).float32
  let halfW        = halfH * aspect
  uniforms.aspect  = aspect
  uniforms.ambient = 0.12'f32
  uniforms.light   = [mx * halfW, my * halfH, lightZ - camDist, 0.0]

  let queue = device.getQueue()
  queue.write(uniformBuf, 0, uniforms.addr, sizeof(Uniforms).csize_t)
  queue.write(instanceBuf, 0, instances[0].unsafeAddr, instancesBytes().csize_t)

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
      view          : view,
      depthSlice    : priv_DEPTH_SLICE_UNDEFINED,
      resolveTarget : nil,
      loadOp        : Clear,
      storeOp       : Store,
      clearValue    : Color(r: 32.0 / 255.0 , g: 8.0 / 255.0 , b: 40.0 / 255.0, a: 1.0),
    ),
    depthStencilAttachment : vaddr RenderPassDepthStencilAttachment(
      nextInChain     : nil,
      view            : depthView,
      depthLoadOp     : Clear,
      depthStoreOp    : Store,
      depthClearValue : 1.0,
      depthReadOnly   : 0,
    ),
    occlusionQuerySet      : nil,
    timestampWrites        : nil,
  )

  var renderPass = encoder.begin(renderPassDesc.addr)
  renderPass.set(pipeline)
  renderPass.set(0, bindGroup, 0, nil)
  renderPass.setVertexBuffer(0, vertexBuf,   0, (cubeVertices.len * sizeof(Vertex)).uint64)
  renderPass.setIndexBuffer(indexBuf, IndexFormat.Uint16, 0, (cubeIndices.len * sizeof(uint16)).uint64)
  renderPass.drawIndexed(cubeIndices.len.uint32, instances.len.uint32, 0, 0, 0)
  renderPass.End()

  let cmdBuffer = encoder.finish(vaddr CommandBufferDescriptor(
    nextInChain : nil,
    label       : "Cube Command Buffer".toStringView(),
    ))
  queue.submit(1, cmdBuffer.addr)

  cmdBuffer.release()
  renderPass.release()
  encoder.release()
  view.release()
  surfaceTexture.texture.release()
  queue.release()

proc requestDevice =
  let deviceFuture = adapter.request(
    options = vaddr DeviceDescriptor(
      nextInChain                 : nil,
      label                       : "Cube Device".toStringView(),
      requiredFeatureCount        : 0,
      requiredFeatures            : nil,
      requiredLimits              : nil,
      defaultQueue                : QueueDescriptor(
        nextInChain : nil,
        label       : "Default Queue".toStringView(),
      ),
      deviceLostCallbackInfo      : deviceLostCallbackInfo(
        callback  = deviceLostCB,
        userdata1 = device.addr,
      ),
      uncapturedErrorCallbackInfo : uncapturedErrorCallbackInfo(
        callback  = errorCB,
        userdata1 = device.addr,
      ),
    ),
    callbackInfo = RequestDeviceCallbackInfo(
      nextInChain : nil,
      mode        : AllowSpontaneous,
      callback    : deviceRequestCB,
      userdata1   : device.addr,
      userdata2   : nil,
    ),
  )

proc adapterRequestCB(status :RequestAdapterStatus; got :Adapter; message :StringView; userdata1, userdata2 :pointer) :void=
  doAssert status == Success, &"Adapter request failed ({$status}): {$message}"
  adapter = got
  requestDevice()

proc deviceRequestCB(status :RequestDeviceStatus; got :Device; message :StringView; userdata1, userdata2 :pointer) :void=
  doAssert status == Success, &"Device request failed ({$status}): {$message}"
  device = got
  onDeviceReady()

proc initWebGPUGraphics =
  echo "Hello WebGPU Cubes"

  instance = wgpu.create(vaddr InstanceDescriptor(nextInChain: nil))
  doAssert instance != nil, "Could not initialize wgpu"

  surface = instance.getSurfaceEmscripten(canvasSelector)
  doAssert surface != nil, "Failed to create the surface"

  discard instance.request(
    options = vaddr RequestAdapterOptions(
      nextInChain          : nil,
      featureLevel         : Core,
      powerPreference      : HighPerformance,
      forceFallbackAdapter : false.uint32,
      backendType          : Undefined,
      compatibleSurface    : surface,
    ),
    callbackInfo = RequestAdapterCallbackInfo(
      nextInChain : nil,
      mode        : AllowSpontaneous,
      callback    : adapterRequestCB,
      userdata1   : adapter.addr,
      userdata2   : nil,
    ),
  )


#############
## Startup ##
#############
proc drawFrame =
  updatePhysics()
  updateGraphics()

when isMainModule:
  instances = createCubeInstances()
  initJoltPhysics()
  initWebGPUGraphics()
