## Jolt falling-cube demo.
##
## A dynamic cube is dropped from (0, 50, 0) onto a static floor at (0, 0, 0) and
## the simulation is stepped, printing the cube's position every frame.
##
## Coordinate system matches webgpu_nim/cubes.nim: right-handed, +Y up. Jolt's
## default gravity is (0, -9.81, 0), so the cube falls "down" in that view with
## no axis remapping.
##
## The core (allocator, Factory, RegisterTypes, Vec3, Quat) comes from the
## henka-generated `jolt` bindings. The physics API that henka can't generate
## cleanly yet (PhysicsSystem and friends) is bound inline below. Jolt's *Table
## layer classes are concrete, so no C++ subclassing/glue is needed.

import jolt

# --- include the Jolt headers we bind to, Jolt.h first (it defines the JPH_* ---
# macros the rest rely on). Goes in demo.nim's own translation unit.
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

# --- demo ---------------------------------------------------------------------
# Two object layers and two broad-phase layers: static vs moving.
const
  layerNonMoving = 0.cushort
  layerMoving    = 1.cushort
  bpNonMoving    = 0.uint8
  bpMoving       = 1.uint8

proc main() =
  # 1. Bring Jolt up (from the generated bindings).
  RegisterDefaultAllocator()
  var factory: Factory
  Factory.sInstance = addr factory
  RegisterTypes()

  # 2. Allocators and job system for the simulation.
  let tempAllocator = newTempAllocator(10 * 1024 * 1024)
  let jobSystem = newJobSystem(2048, 8, 2)

  # 3. Collision layer configuration (concrete Table implementations).
  let objectLayerPairFilter = newObjectLayerPairFilterTable(2)
  objectLayerPairFilter.enableCollision(layerMoving, layerNonMoving)

  let broadPhaseLayerInterface = newBroadPhaseLayerInterfaceTable(2, 2)
  broadPhaseLayerInterface.mapObjectToBroadPhaseLayer(layerNonMoving, bpNonMoving)
  broadPhaseLayerInterface.mapObjectToBroadPhaseLayer(layerMoving, bpMoving)

  let objectVsBroadPhaseLayerFilter =
    newObjectVsBroadPhaseLayerFilterTable(broadPhaseLayerInterface, 2, objectLayerPairFilter, 2)

  # 4. The physics system. Gravity defaults to (0, -9.81, 0).
  let physics = newPhysicsSystem()
  physics.init(1024, 0, 1024, 1024,
    broadPhaseLayerInterface, objectVsBroadPhaseLayerFilter, objectLayerPairFilter)
  let bodies = physics.getBodyInterface()

  # 5. Static floor at (0, 0, 0), size (10, 0.1, 10)  ->  half extents (5, 0.05, 5).
  let floorShape = newBoxShape(Vec3_create(5.0, 0.05, 5.0), 0.04)
  let floorSettings = newBodyCreationSettings(
    floorShape, Vec3_create(0.0, 0.0, 0.0), Quat.sIdentity(), motionStatic, layerNonMoving)
  discard bodies.createAndAddBody(floorSettings, dontActivate)

  # 6. Dynamic cube at (0, 50, 0), size (1, 1, 1)  ->  half extents (0.5, 0.5, 0.5).
  let cubeShape = newBoxShape(Vec3_create(0.5, 0.5, 0.5), 0.05)
  let cubeSettings = newBodyCreationSettings(
    cubeShape, Vec3_create(0.0, 50.0, 0.0), Quat.sIdentity(), motionDynamic, layerMoving)
  let cube = bodies.createAndAddBody(cubeSettings, activate)

  physics.optimizeBroadPhase()

  # 7. Step the simulation, printing the cube position each frame.
  const
    deltaTime = 1.0'f32 / 60.0'f32
    frames    = 300
  for frame in 0 ..< frames:
    physics.update(deltaTime, 1, tempAllocator, jobSystem)
    let p = bodies.getCenterOfMassPosition(cube)
    echo "frame ", frame, ": (", p.GetX(), ", ", p.GetY(), ", ", p.GetZ(), ")"

main()
