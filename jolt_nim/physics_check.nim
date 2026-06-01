## Headless repro of the cubes demo's PHYSICS (no WebGPU): same 50-box grid,
## tight spacing, random initial rotations, floor, stepped like drawFrame does.
import std/[math, random]
import jolt

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

const
  motionStatic  = 0.cint
  motionDynamic = 2.cint
  activate      = 0.cint
  dontActivate  = 1.cint

proc newPhysicsSystem(): ptr PhysicsSystem {.importcpp: "new JPH::PhysicsSystem()".}
proc newTempAllocator(size: cuint): ptr TempAllocatorImpl {.importcpp: "new JPH::TempAllocatorImpl(#)".}
proc newJobSystem(maxJobs, maxBarriers: cuint; numThreads: cint): ptr JobSystemThreadPool {.importcpp: "new JPH::JobSystemThreadPool(@)".}
proc newObjectLayerPairFilterTable(numLayers: cuint): ptr ObjectLayerPairFilterTable {.importcpp: "new JPH::ObjectLayerPairFilterTable(#)".}
proc newBroadPhaseLayerInterfaceTable(numObjLayers, numBpLayers: cuint): ptr BroadPhaseLayerInterfaceTable {.importcpp: "new JPH::BroadPhaseLayerInterfaceTable(@)".}
proc newObjectVsBroadPhaseLayerFilterTable(bpli: ptr BroadPhaseLayerInterfaceTable; numBpLayers: cuint; olp: ptr ObjectLayerPairFilterTable; numObjLayers: cuint): ptr ObjectVsBroadPhaseLayerFilterTable {.importcpp: "new JPH::ObjectVsBroadPhaseLayerFilterTable(*#, #, *#, #)".}
proc enableCollision(t: ptr ObjectLayerPairFilterTable; layer1, layer2: cushort) {.importcpp: "#->EnableCollision(@)".}
proc mapObjectToBroadPhaseLayer(t: ptr BroadPhaseLayerInterfaceTable; objLayer: cushort; bpLayer: uint8) {.importcpp: "#->MapObjectToBroadPhaseLayer(#, JPH::BroadPhaseLayer(#))".}
proc init(sys: ptr PhysicsSystem; maxBodies, numBodyMutexes, maxBodyPairs, maxContactConstraints: cuint; bpli: ptr BroadPhaseLayerInterfaceTable; ovb: ptr ObjectVsBroadPhaseLayerFilterTable; olp: ptr ObjectLayerPairFilterTable) {.importcpp: "#->Init(#, #, #, #, *#, *#, *#)".}
proc getBodyInterface(sys: ptr PhysicsSystem): ptr BodyInterface {.importcpp: "(& #->GetBodyInterface())".}
proc optimizeBroadPhase(sys: ptr PhysicsSystem) {.importcpp: "#->OptimizeBroadPhase()".}
proc update(sys: ptr PhysicsSystem; dt: cfloat; collisionSteps: cint; tempAlloc: ptr TempAllocatorImpl; jobSys: ptr JobSystemThreadPool): cint {.importcpp: "(int)#->Update(#, #, #, #)", discardable.}
proc newBoxShape(halfExtent: Vec3; convexRadius: cfloat): ptr Shape {.importcpp: "new JPH::BoxShape(@)".}
proc newBodyCreationSettings(shape: ptr Shape; pos: Vec3; rot: Quat; motionType: cint; objectLayer: cushort): ptr BodyCreationSettings {.importcpp: "new JPH::BodyCreationSettings(#, #, #, (JPH::EMotionType)#, #)".}
proc createAndAddBody(bi: ptr BodyInterface; settings: ptr BodyCreationSettings; activation: cint): BodyID {.importcpp: "#->CreateAndAddBody(*#, (JPH::EActivation)#)".}
proc getCenterOfMassPosition(bi: ptr BodyInterface; id: BodyID): Vec3 {.importcpp: "#->GetCenterOfMassPosition(#)".}
proc getRotation(bi: ptr BodyInterface; id: BodyID): Quat {.importcpp: "#->GetRotation(#)".}

const
  layerNonMoving = 0.cushort
  layerMoving    = 1.cushort
  bpNonMoving    = 0.uint8
  bpMoving       = 1.uint8
  gridCols = 10
  gridRows = 5
  spacing  = 1.9'f32
  cubeSize = 0.8'f32
  bodyCount = gridCols * gridRows

proc quatFromEuler(e: array[3, float32]): Quat =
  let
    (cx, sx) = (cos(e[0] * 0.5), sin(e[0] * 0.5))
    (cy, sy) = (cos(e[1] * 0.5), sin(e[1] * 0.5))
    (cz, sz) = (cos(e[2] * 0.5), sin(e[2] * 0.5))
  Quat_create((sx*cy*cz - cx*sy*sz).cfloat, (cx*sy*cz + sx*cy*sz).cfloat,
              (cx*cy*sz - sx*sy*cz).cfloat, (cx*cy*cz + sx*sy*sz).cfloat)

var bodyIds: array[bodyCount, BodyID]

proc main =
  RegisterDefaultAllocator()
  var factory {.global.}: Factory
  Factory.sInstance = addr factory
  RegisterTypes()
  let tempAllocator = newTempAllocator(10 * 1024 * 1024)
  let jobSystem = newJobSystem(2048, 8, 0)
  let olp = newObjectLayerPairFilterTable(2)
  olp.enableCollision(layerMoving, layerNonMoving)
  let bpli = newBroadPhaseLayerInterfaceTable(2, 2)
  bpli.mapObjectToBroadPhaseLayer(layerNonMoving, bpNonMoving)
  bpli.mapObjectToBroadPhaseLayer(layerMoving, bpMoving)
  let ovb = newObjectVsBroadPhaseLayerFilterTable(bpli, 2, olp, 2)
  let physics = newPhysicsSystem()
  physics.init(1024, 0, 1024, 1024, bpli, ovb, olp)
  let bodies = physics.getBodyInterface()

  let floorShape = newBoxShape(Vec3_create(16.0, 0.5, 16.0), 0.04)
  discard bodies.createAndAddBody(newBodyCreationSettings(floorShape,
    Vec3_create(0.0, -5.5, 0.0), Quat.sIdentity(), motionStatic, layerNonMoving), dontActivate)

  var rng = initRand(20260528)
  template rf(lo, hi: float32): float32 = lo + rng.rand(1.0).float32 * (hi - lo)
  let half = Vec3_create(cubeSize, cubeSize, cubeSize)
  var i = 0
  for row in 0 ..< gridRows:
    for col in 0 ..< gridCols:
      let x = (col.float32 - (gridCols.float32 - 1.0'f32) * 0.5'f32) * spacing
      let y = (row.float32 - (gridRows.float32 - 1.0'f32) * 0.5'f32) * spacing
      let rot = quatFromEuler([rf(0.0, TAU), rf(0.0, TAU), rf(0.0, TAU)])
      bodyIds[i] = bodies.createAndAddBody(newBodyCreationSettings(
        newBoxShape(half, 0.05), Vec3_create(x, y, 0.0), rot, motionDynamic, layerMoving), activate)
      inc i
  physics.optimizeBroadPhase()
  echo "set up ", bodyCount, " boxes"

  for frame in 0 ..< 300:
    physics.update(1.0'f32 / 60.0'f32, 1, tempAllocator, jobSystem)
    for j in 0 ..< bodyCount:
      let p = bodies.getCenterOfMassPosition(bodyIds[j])
      let q = bodies.getRotation(bodyIds[j])
      discard (p.GetX(), q.GetW())   # touch readback exactly like cubes does
    if frame mod 60 == 0 or frame == 299:
      let p = bodies.getCenterOfMassPosition(bodyIds[0])
      echo "frame ", frame, " body0 y=", p.GetY()
  echo "DONE 300 frames, no crash"

main()
