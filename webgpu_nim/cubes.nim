#:___________________________________________________________
#  henka-nimconf-26  |  WebGPU Cubes demo  |  MIT             :
#:___________________________________________________________
# A wall of randomly placed & rotated grey cubes, drawn with  |
# instancing. Cube geometry lives in vertex/index buffers;    |
# per-cube world offset + rotation come from an instance      |
# buffer. Rotations are fixed (generated once, not animated). |
#                                                             |
# Runs in two modes from the same source:                    |
#   * Native : GLFW window + wgpu  (blocking adapter/device)  |
#   * Web    : -d:emscripten, surface bound to an HTML canvas |
#             (async adapter/device, emscripten main loop)    |
#_____________________________________________________________|
# @deps std
import std/strformat
import std/[math, random]
# @deps wgpu
import wgpu
import jolt

#_______________________________________
# @section Camera
#  Shared between the CPU (to size the wall) and the shader (must match).
#_____________________________
const
  camDist  = 10.0'f32  # distance from the camera to the z = 0 wall plane
  fovY     = 1.0'f32   # vertical field of view (radians)
  cubeSize = 0.8'f32   # cube half-extent
  lightZ   = 4.0'f32   # point-light depth: in front of the cubes, toward the camera
  initialW :int32 = 960
  initialH :int32 = 540
  renderScale :int32 = 2   # supersample factor: render larger, CSS shows it at logical size

var LIMIT = 100

#_______________________________________
# @section Geometry
#  8 corners, 36 indices (12 triangles). No per-vertex color: cubes are grey.
#_____________________________
type Vertex = object
  pos {.align: 16.} :array[4, float32]

type CubeInstance = object
  #offset   {.align: 16.} :array[4, float32]
  #rotation {.align: 16.} :array[4, float32]
  transform {.align: 16.} :Mat44

const s = cubeSize
let cubeVertices = [
  Vertex(pos: [-s, -s, -s, 0]), Vertex(pos: [ s, -s, -s, 0]),
  Vertex(pos: [ s,  s, -s, 0]), Vertex(pos: [-s,  s, -s, 0]),
  Vertex(pos: [-s, -s,  s, 0]), Vertex(pos: [ s, -s,  s, 0]),
  Vertex(pos: [ s,  s,  s, 0]), Vertex(pos: [-s,  s,  s, 0]),
]

const cubeIndices = [
  0'u16, 1, 2,  0, 2, 3,   # back   (-z)
  4,     6, 5,  4, 7, 6,   # front  (+z)
  0,     4, 5,  0, 5, 1,   # bottom (-y)
  3,     2, 6,  3, 6, 7,   # top    (+y)
  0,     3, 7,  0, 7, 4,   # left   (-x)
  1,     5, 6,  1, 6, 2,   # right  (+x)
]


######################
## Jolt integration ##
######################
{.emit: """/*INCLUDESECTION*/
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

# --- opaque handle types ------------------------------------------------------
type
  PhysicsSystem {.importcpp: "JPH::PhysicsSystem".} = object
  BodyInterface {.importcpp: "JPH::BodyInterface".} = object
  TempAllocatorImpl {.importcpp: "JPH::TempAllocatorImpl".} = object
  JobSystemThreadPool {.importcpp: "JPH::JobSystemThreadPool".} = object
  ObjectLayerPairFilterTable {.importcpp: "JPH::ObjectLayerPairFilterTable".} = object
  BroadPhaseLayerInterfaceTable {.importcpp: "JPH::BroadPhaseLayerInterfaceTable".} = object
  ObjectVsBroadPhaseLayerFilterTable {.importcpp: "JPH::ObjectVsBroadPhaseLayerFilterTable".} = object
  BodyCreationSettings {.importcpp: "JPH::BodyCreationSettings".} = object
  Shape {.importcpp: "JPH::Shape".} = object
  BodyID {.importcpp: "JPH::BodyID".} = object

# EMotionType / EActivation are `enum class`es; pass the integer value and cast
# in the C++ pattern rather than binding the enums.
const
  motionStatic  = 0.cint
  motionDynamic = 2.cint
  activate      = 0.cint
  dontActivate  = 1.cint

# --- inline physics bindings --------------------------------------------------
proc newPhysicsSystem(): ptr PhysicsSystem
  {.importcpp: "new JPH::PhysicsSystem()".}
proc newTempAllocator(size: cuint): ptr TempAllocatorImpl
  {.importcpp: "new JPH::TempAllocatorImpl(#)".}
proc newJobSystem(maxJobs, maxBarriers: cuint; numThreads: cint): ptr JobSystemThreadPool
  {.importcpp: "new JPH::JobSystemThreadPool(@)".}
proc newObjectLayerPairFilterTable(numLayers: cuint): ptr ObjectLayerPairFilterTable
  {.importcpp: "new JPH::ObjectLayerPairFilterTable(#)".}
proc newBroadPhaseLayerInterfaceTable(numObjLayers, numBpLayers: cuint): ptr BroadPhaseLayerInterfaceTable
  {.importcpp: "new JPH::BroadPhaseLayerInterfaceTable(@)".}
proc newObjectVsBroadPhaseLayerFilterTable(
    bpli: ptr BroadPhaseLayerInterfaceTable; numBpLayers: cuint;
    olp: ptr ObjectLayerPairFilterTable; numObjLayers: cuint): ptr ObjectVsBroadPhaseLayerFilterTable
  {.importcpp: "new JPH::ObjectVsBroadPhaseLayerFilterTable(*#, #, *#, #)".}

proc enableCollision(t: ptr ObjectLayerPairFilterTable; layer1, layer2: cushort)
  {.importcpp: "#->EnableCollision(@)".}
proc mapObjectToBroadPhaseLayer(t: ptr BroadPhaseLayerInterfaceTable; objLayer: cushort; bpLayer: uint8)
  {.importcpp: "#->MapObjectToBroadPhaseLayer(#, JPH::BroadPhaseLayer(#))".}

proc init(sys: ptr PhysicsSystem; maxBodies, numBodyMutexes, maxBodyPairs, maxContactConstraints: cuint;
          bpli: ptr BroadPhaseLayerInterfaceTable;
          ovb: ptr ObjectVsBroadPhaseLayerFilterTable;
          olp: ptr ObjectLayerPairFilterTable)
  {.importcpp: "#->Init(#, #, #, #, *#, *#, *#)".}
proc getBodyInterface(sys: ptr PhysicsSystem): ptr BodyInterface
  {.importcpp: "(& #->GetBodyInterface())".}
proc optimizeBroadPhase(sys: ptr PhysicsSystem)
  {.importcpp: "#->OptimizeBroadPhase()".}
proc update(sys: ptr PhysicsSystem; dt: cfloat; collisionSteps: cint;
            tempAlloc: ptr TempAllocatorImpl; jobSys: ptr JobSystemThreadPool): cint
  {.importcpp: "(int)#->Update(#, #, #, #)", discardable.}

proc newBoxShape(halfExtent: Vec3; convexRadius: cfloat): ptr Shape
  {.importcpp: "new JPH::BoxShape(@)".}
proc newBodyCreationSettings(shape: ptr Shape; pos: Vec3; rot: Quat;
                             motionType: cint; objectLayer: cushort): ptr BodyCreationSettings
  {.importcpp: "new JPH::BodyCreationSettings(#, #, #, (JPH::EMotionType)#, #)".}
proc createAndAddBody(bi: ptr BodyInterface; settings: ptr BodyCreationSettings; activation: cint): BodyID
  {.importcpp: "#->CreateAndAddBody(*#, (JPH::EActivation)#)".}
proc getCenterOfMassPosition(bi: ptr BodyInterface; id: BodyID): Vec3
  {.importcpp: "#->GetCenterOfMassPosition(#)".}
proc getRotation(bi: ptr BodyInterface; id: BodyID): Quat
  {.importcpp: "#->GetRotation(#)".}
proc getCenterOfMassTransform(bi: ptr BodyInterface; id: BodyID): RMat44
  {.importcpp: "#->GetCenterOfMassTransform(#)".}

# --- demo ---------------------------------------------------------------------
# Two object layers and two broad-phase layers: static vs moving.
const
  layerNonMoving = 0.cushort
  layerMoving    = 1.cushort
  bpNonMoving    = 0.uint8
  bpMoving       = 1.uint8

var physics       : ptr PhysicsSystem       = nil
var tempAllocator : ptr TempAllocatorImpl   = nil
var jobSystem     : ptr JobSystemThreadPool = nil
var bodies        : ptr BodyInterface       = nil
var cubes         : array[50, BodyID]
var instances     : seq[CubeInstance]

proc initJolt() =
  # 1. Bring Jolt up (from the generated bindings).
  RegisterDefaultAllocator()
  var factory: Factory
  Factory.sInstance = addr factory
  RegisterTypes()

  # 2. Allocators and job system for the simulation.
  tempAllocator = newTempAllocator(10 * 1024 * 1024)
  jobSystem = newJobSystem(2048, 8, 2)

  # 3. Collision layer configuration (concrete Table implementations).
  let objectLayerPairFilter = newObjectLayerPairFilterTable(2)
  objectLayerPairFilter.enableCollision(layerMoving, layerNonMoving)
  objectLayerPairFilter.enableCollision(layerMoving, layerMoving)

  let broadPhaseLayerInterface = newBroadPhaseLayerInterfaceTable(2, 2)
  broadPhaseLayerInterface.mapObjectToBroadPhaseLayer(layerNonMoving, bpNonMoving)
  broadPhaseLayerInterface.mapObjectToBroadPhaseLayer(layerMoving, bpMoving)

  let objectVsBroadPhaseLayerFilter =
    newObjectVsBroadPhaseLayerFilterTable(broadPhaseLayerInterface, 2, objectLayerPairFilter, 2)

  # 4. The physics system. Gravity defaults to (0, -9.81, 0).
  physics = newPhysicsSystem()
  physics.init(1024, 0, 1024, 1024,
    broadPhaseLayerInterface, objectVsBroadPhaseLayerFilter, objectLayerPairFilter)
  bodies = physics.getBodyInterface()

  # 5. Static floor at (0, 0, 0), size (10, 0.1, 10)  ->  half extents (5, 0.05, 5).
  let floorShape = newBoxShape(Vec3_create(50.0, 0.05, 50.0), 0.04)
  let floorSettings = newBodyCreationSettings(
    floorShape, Vec3_create(0.0, -4.0, 0.0), Quat.sIdentity(), motionStatic, layerNonMoving)
  discard bodies.createAndAddBody(floorSettings, dontActivate)

  # 6. Dynamic cubes
  for (id, instance) in instances.pairs:
    let position = instance.transform.GetTranslation()
    let rotation = instance.transform.GetQuaternion()
    let cubeShape = newBoxShape(Vec3_create(cubeSize, cubeSize, cubeSize), 0.05)
    let cubeSettings = newBodyCreationSettings(cubeShape, position, rotation, motionDynamic, layerMoving)

    cubes[id] = bodies.createAndAddBody(cubeSettings, activate)

  physics.optimizeBroadPhase()


########################
## WebGPU integration ##
########################
when defined(emscripten):
  proc emscripten_get_now(): cdouble {.importc, header:"<emscripten.h>".}
  # The browser provides WebGPU and drives the render loop for us.
  proc emscripten_set_main_loop(
    f                 :proc() {.cdecl.};
    fps               :cint;
    simulateInfinite  :cint;
    ) {.importc, header:"<emscripten.h>".}
  # Mouse position in normalized [-1, 1] coords, fed by a listener in index.html.
  {.emit: """
#include <emscripten.h>
EM_JS(float, mouse_x, (), { return window.__mx || 0.0; });
EM_JS(float, mouse_y, (), { return window.__my || 0.0; });
""".}
  proc mouse_x() :cfloat {.importc, nodecl.}
  proc mouse_y() :cfloat {.importc, nodecl.}
else:
  # @deps external
  from nglfw as glfw import nil


#_______________________________________
# @section Cube Shader
#  Vertices/indices come from buffers. Per instance we receive a world offset
#  and an XYZ rotation. Faces are flat-shaded grey using screen-space
#  derivatives, so 8 shared vertices still read as a solid cube.
#_____________________________
const shaderCode = """
struct Uniforms {
  aspect: f32,
  ambient: f32,
  lightView: vec4<f32>,
};
@group(0) @binding(0) var<uniform> u : Uniforms;

struct Instances {
  transform : array<mat4x4<f32>, 50>
};
@group(0) @binding(1) var<uniform> instances : Instances;

struct VSIn {
  @location(0) position : vec4<f32>,
};
struct VSOut {
  @builtin(position) pos     : vec4<f32>,
  @location(0)       viewPos : vec3<f32>,
  @location(1)       color   : vec3<f32>,
};

const draculaLen = 12;
const dracula = array<vec3<f32>, draculaLen>(
  vec3(40.0, 42.0, 54.0)    / 255.0,
  vec3(98.0, 114.0, 164.0)  / 255.0,
  vec3(68.0, 71.0, 90.0)    / 255.0,
  vec3(248.0, 248.0, 242.0) / 255.0,
  vec3(98.0, 114.0, 164.0)  / 255.0,
  vec3(255.0, 85.0, 85.0)   / 255.0,
  vec3(255.0, 184.0, 108.0) / 255.0,
  vec3(241.0, 250.0, 140.0) / 255.0,
  vec3(80.0, 250.0, 123.0)  / 255.0,
  vec3(139.0, 233.0, 253.0) / 255.0,
  vec3(189.0, 147.0, 249.0) / 255.0,
  vec3(255.0, 121.0, 198.0) / 255.0,
);

@vertex
fn vs_main(in :VSIn, @builtin(instance_index) instanceIndex: u32) ->VSOut {
  let world   = instances.transform[instanceIndex] * in.position;
  let viewPos = vec3<f32>(world.x, world.y, world.z - 10.0);  // matches camDist

  // Right-handed perspective mapping depth to [0, 1] (WebGPU convention)
  let f   = 1.0 / tan(1.0 * 0.5);  // matches fovY
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
  out.pos     = proj * vec4<f32>(viewPos, 1.0);
  out.viewPos = viewPos;
  out.color   = dracula[instanceIndex % draculaLen];
  return out;
}

fn faceforward(N: vec3<f32>, I: vec3<f32>, Nref: vec3<f32>) -> vec3<f32> {
  if (dot(Nref, I) < 0.0) {
    return N;
  } else {
    return -N;
  }
}

@fragment
fn fs_main(in :VSOut) ->@location(0) vec4<f32> {
  var n = normalize(cross(dpdx(in.viewPos), dpdy(in.viewPos)));
  let V = normalize(-in.viewPos);        // fragment-to-camera in view space
  n = faceforward(n, -V, n);             // flip n if it points away from the camera

  // Point light with distance attenuation
  let toLight = u.lightView.xyz - in.viewPos;
  let dist    = length(toLight);
  let L       = toLight / dist;
  let diff    = max(dot(n, L), 0.0);
  let atten   = 1.0 / (1.0 + 0.0125 * dist * dist);

  // Blinn-Phong specular
  let H = normalize(L + V);
  let shininess = 64.0; // larger = tighter highlight
  let spec = pow(max(dot(n, H), 0.0), shininess);

  let albedo    = in.color;

  let ambientTerm  = u.ambient;
  let diffuseTerm  = diff * atten;
  let specularTerm = 2.0 * spec * atten;

  //let color =
  //    albedo * (ambientTerm + diffuseTerm) +
  //    vec3<f32>(1.0) * specularTerm;
  let color =
    albedo * (ambientTerm + diffuseTerm + 0.2 * specularTerm);
  return vec4<f32>(color, 1.0);
}
"""

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


#_______________________________________
# @section State
#  HTML canvas selector must match the <canvas id> in index.html.
#_____________________________
const
  canvasSelector       = "#cubes-canvas"
  title                = "WebGPU Cubes"
  depthFormat          = TextureFormat.Depth24Plus

type Uniforms = object
  aspect  : float32
  ambient : float32
  light   {.align: 16.} : array[4, float32]

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
  let vertexBytes   = (cubeVertices.len * sizeof(Vertex)).uint64
  let indexBytes    = (cubeIndices.len  * sizeof(uint16)).uint64

  vertexBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Cube Vertices".toStringView(),
    usage: BufferUsage_Vertex or BufferUsage_CopyDst, size: vertexBytes, mappedAtCreation: false.uint32))
  indexBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Cube Indices".toStringView(),
    usage: BufferUsage_Index or BufferUsage_CopyDst, size: indexBytes, mappedAtCreation: false.uint32))

  echo "@@@@@@@@ Instances len: ", instancesBytes()
  instanceBuf = device.create(vaddr BufferDescriptor(
    nextInChain: nil, label: "Instances".toStringView(),
    usage: BufferUsage_Uniform or BufferUsage_CopyDst, size: instancesBytes(), mappedAtCreation: false.uint32))

  queue.write(vertexBuf,   0, cubeVertices[0].unsafeAddr, vertexBytes.csize_t)
  queue.write(indexBuf,    0, cubeIndices[0].unsafeAddr,  indexBytes.csize_t)
  queue.write(instanceBuf, 0, instances[0].unsafeAddr,    instancesBytes().csize_t)

  # --- Uniform buffer (aspect ratio), bound to the vertex stage ---
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
    VertexAttribute(format: VertexFormat.Float32x3, offset: 0, shaderLocation: 0),   # position
  ]
  var vertexLayouts = [
    VertexBufferLayout(stepMode: VertexStepMode.Vertex,   arrayStride: sizeof(Vertex).uint64,   attributeCount: 1, attributes: vertexAttrs[0].addr),
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
      bufferCount             : 1,
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
  when defined(emscripten):
    # Render larger than the logical canvas; surface.configure resizes the canvas
    # drawing buffer to match, and CSS scales it back down for a crisp result.
    config.width  = (initialW * renderScale).uint32
    config.height = (initialH * renderScale).uint32
  else:
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
  echo &":: Surface configured at {config.width} x {config.height}. Rendering {instances.len} cubes."

  when defined(emscripten):
    # Hand the render loop over to the browser (fps 0 = use requestAnimationFrame)
    emscripten_set_main_loop(drawFrame, 0.cint, 1.cint)

var lastMs     = 0.0'f32
const fixedDt   = 1.0'f32 / 60.0'f32
var accumulator = 0.0'f32

#_______________________________________
# @section Render
#_____________________________
proc drawFrame() =
  let now = emscripten_get_now()
  let dt  = float32((now - lastMs) / 1000.0)
  lastMs = now
  accumulator += dt

  while accumulator >= fixedDt:
    physics.update(fixedDt, 10.cint, tempAllocator, jobSystem)
    accumulator -= fixedDt

    for (id, instance) in instances.mpairs:
      instance.transform = bodies.getCenterOfMassTransform(cubes[id])

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

  # Read the mouse (normalized [-1, 1]) and place the point light on the cube plane
  when defined(emscripten):
    let mx = mouse_x().float32
    let my = mouse_y().float32
  else:
    let mx = 0.0'f32
    let my = 0.0'f32
  let aspect = config.width.float32 / config.height.float32
  let halfH  = camDist * tan(fovY * 0.5).float32     # visible half-height at the cube plane
  let halfW  = halfH * aspect
  uniforms.aspect  = aspect
  uniforms.ambient = 0.12'f32
  uniforms.light   = [mx * halfW, my * halfH, lightZ - camDist, 0.0]
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
      view                 : view,
      depthSlice           : priv_DEPTH_SLICE_UNDEFINED,  # required by Dawn for non-3D attachments
      resolveTarget        : nil,
      loadOp               : Clear,
      storeOp              : Store,
      clearValue           : Color(r: 32.0 / 255.0 , g: 8.0 / 255.0 , b: 40.0 / 255.0, a: 1.0),
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
  renderPass.setVertexBuffer(0, vertexBuf,   0, (cubeVertices.len * sizeof(Vertex)).uint64)
  #renderPass.setVertexBuffer(1, instanceBuf, 0, (instances.len    * sizeof(CubeInstance)).uint64)
  renderPass.setIndexBuffer(indexBuf, IndexFormat.Uint16, 0, (cubeIndices.len * sizeof(uint16)).uint64)
  renderPass.drawIndexed(cubeIndices.len.uint32, instances.len.uint32, 0, 0, 0)
  renderPass.End()

  let cmdBuffer = encoder.finish(vaddr CommandBufferDescriptor(
    nextInChain : nil,
    label       : "Cube Command Buffer".toStringView(),
    ))
  queue.submit(1, cmdBuffer.addr)

  # The browser presents the canvas automatically; only native needs an explicit present.
  when not defined(emscripten):
    let status = surface.present()
    if status != Success: echo "ERR:: Surface.present() failed with: ", $status

  # Release every object acquired this frame. Without this the WebGPU objects
  # leak on the wasm heap and the demo OOMs after a few seconds (the heap is a
  # fixed 16 MB and getCurrentTexture/getQueue/createCommandEncoder all alloc).
  cmdBuffer.release()
  renderPass.release()
  encoder.release()
  view.release()
  surfaceTexture.texture.release()
  queue.release()


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
  instances = createCubeInstances()
  initJolt()
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
