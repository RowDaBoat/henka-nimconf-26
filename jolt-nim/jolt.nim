type
  uint * = cuint
  AllocateFunction * = proc (a0 :cint) :pointer {.cdecl.}
  ReallocateFunction * = proc (a0 :pointer; a1 :cint; a2 :cint) :pointer {.cdecl.}
  FreeFunction * = proc (a0 :pointer) {.cdecl.}
  AlignedAllocateFunction * = proc (a0 :cint; a1 :cint) :pointer {.cdecl.}
  AlignedFreeFunction * = proc (a0 :pointer) {.cdecl.}
  TraceFunction * = proc (a0 :cstring) {.cdecl.}
  AssertFailedFunction * = proc (a0 :cstring; a1 :cstring; a2 :cstring; a3 :uint) :bool {.cdecl.}
  AssertLastParam *{.incompleteStruct, importcpp:"JPH::AssertLastParam", header:"Jolt/Jolt.h".}= object
  AllocatorHasReallocate *[T]{.incompleteStruct, importcpp:"JPH::AllocatorHasReallocate", header:"Jolt/Jolt.h".}= object
  STLAllocator *[T]{.incompleteStruct, importcpp:"JPH::STLAllocator", header:"Jolt/Jolt.h".}= object
  hash *{.importcpp:"std::hash", header:"Jolt/Jolt.h".}= object
  Hash *{.importcpp:"JPH::Hash", header:"Jolt/Jolt.h".}= object
  Array *[T, Allocator]{.importcpp:"JPH::Array", header:"Jolt/Jolt.h".}= object
    mSize *:cint
    mCapacity *:cint
    mElements *:ptr T
  Float4 *{.importcpp:"JPH::Float4", header:"Jolt/Jolt.h".}= object
    x *:cfloat
    y *:cfloat
    z *:cfloat
    w *:cfloat
  Vec3 *{.importcpp:"JPH::Vec3", header:"Jolt/Jolt.h".}= object
  DVec3 *{.importcpp:"JPH::DVec3", header:"Jolt/Jolt.h".}= object
  Vec4 *{.importcpp:"JPH::Vec4", header:"Jolt/Jolt.h".}= object
  UVec4 *{.importcpp:"JPH::UVec4", header:"Jolt/Jolt.h".}= object
  BVec16 *{.incompleteStruct, importcpp:"JPH::BVec16", header:"Jolt/Jolt.h".}= object
  Quat *{.importcpp:"JPH::Quat", header:"Jolt/Jolt.h".}= object
    mValue *:Vec4
  Mat44 *{.importcpp:"JPH::Mat44", header:"Jolt/Jolt.h".}= object
  DMat44 *{.importcpp:"JPH::DMat44", header:"Jolt/Jolt.h".}= object
  Vec3Arg *{.incompleteStruct, importcpp:"Vec3Arg", header:"Jolt/Jolt.h".}= object
  DVec3Arg * = DVec3
  Vec4Arg *{.incompleteStruct, importcpp:"Vec4Arg", header:"Jolt/Jolt.h".}= object
  UVec4Arg *{.incompleteStruct, importcpp:"UVec4Arg", header:"Jolt/Jolt.h".}= object
  BVec16Arg *{.incompleteStruct, importcpp:"BVec16Arg", header:"Jolt/Jolt.h".}= object
  QuatArg *{.incompleteStruct, importcpp:"QuatArg", header:"Jolt/Jolt.h".}= object
  Mat44Arg * = Mat44
  DMat44Arg * = DMat44
  StaticArray *[T]{.importcpp:"JPH::StaticArray", header:"Jolt/Jolt.h".}= object
    mSize *:size_type
  Float3 *{.importcpp:"JPH::Float3", header:"Jolt/Jolt.h".}= object
    x *:cfloat
    y *:cfloat
    z *:cfloat
  Double3 *{.importcpp:"JPH::Double3", header:"Jolt/Jolt.h".}= object
    x *:cdouble
    y *:cdouble
    z *:cdouble
  Real * = cfloat
  Real3 * = Float3
  RVec3 * = Vec3
  RVec3Arg * = Vec3Arg
  RMat44 * = Mat44
  RMat44Arg * = Mat44Arg
const JPH_VERSION_MAJOR* = 5
const JPH_VERSION_MINOR* = 5
const JPH_VERSION_PATCH* = 1
const JPH_VERSION_FEATURE_BIT_1* = 0
const JPH_VERSION_FEATURE_BIT_2* = 0
const JPH_VERSION_FEATURE_BIT_3* = 0
const JPH_VERSION_FEATURE_BIT_4* = 0
const JPH_VERSION_FEATURE_BIT_5* = 0
const JPH_VERSION_FEATURE_BIT_6* = 0
const JPH_VERSION_FEATURE_BIT_7* = 0
const JPH_VERSION_FEATURE_BIT_8* = 0
const JPH_VERSION_FEATURE_BIT_9* = 0
const JPH_VERSION_FEATURE_BIT_10* = 0
const JPH_VERSION_FEATURE_BIT_11* = 0
const JPH_VERSION_FEATURES* = ( uint64 ( JPH_VERSION_FEATURE_BIT_1 ) or ( JPH_VERSION_FEATURE_BIT_2 shl 1 ) or ( JPH_VERSION_FEATURE_BIT_3 shl 2 ) or ( JPH_VERSION_FEATURE_BIT_4 shl 3 ) or ( JPH_VERSION_FEATURE_BIT_5 shl 4 ) or ( JPH_VERSION_FEATURE_BIT_6 shl 5 ) or ( JPH_VERSION_FEATURE_BIT_7 shl 6 ) or ( JPH_VERSION_FEATURE_BIT_8 shl 7 ) or ( JPH_VERSION_FEATURE_BIT_9 shl 8 ) or ( JPH_VERSION_FEATURE_BIT_10 shl 9 ) or ( JPH_VERSION_FEATURE_BIT_11 shl 10 ) )
const JPH_VERSION_ID* = ( ( JPH_VERSION_FEATURES shl 24 ) or ( JPH_VERSION_MAJOR shl 16 ) or ( JPH_VERSION_MINOR shl 8 ) or JPH_VERSION_PATCH )
const JPH_CPU_ARCH_BITS* = 64
const JPH_VECTOR_ALIGNMENT* = 16
const JPH_DVECTOR_ALIGNMENT* = 32
const JPH_CACHE_LINE_SIZE* = 64
const JPH_RVECTOR_ALIGNMENT* = JPH_VECTOR_ALIGNMENT
var
  Allocate *:AllocateFunction
  Reallocate *:ReallocateFunction
  Free *:FreeFunction
  AlignedAllocate *:AlignedAllocateFunction
  AlignedFree *:AlignedFreeFunction
proc RegisterDefaultAllocator *() {.importcpp:"JPH::RegisterDefaultAllocator(@)", header:"Jolt/Jolt.h".}
var
  Trace *:TraceFunction
  AssertFailed *:AssertFailedFunction
proc AssertFailedParamHelper *(inExpression :cstring; inFile :cstring; inLine :uint; a3 :AssertLastParam) :bool {.importcpp:"JPH::AssertFailedParamHelper(@)", header:"Jolt/Jolt.h".}
proc call *(this :hash; inRHS :cint) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc HashBytes *(inData :pointer; inSize :uint; inSeed :cint) :cint {.importcpp:"JPH::HashBytes(@)", header:"Jolt/Jolt.h".}
proc HashString *(inString :cstring; inSeed :cint) :cint {.importcpp:"JPH::HashString(@)", header:"Jolt/Jolt.h".}
proc Hash64 *(inValue :cint) :cint {.importcpp:"JPH::Hash64(@)", header:"Jolt/Jolt.h".}
proc call *(this :Hash; inValue :cfloat) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc call *(this :Hash; inValue :cdouble) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc call *(this :Hash; inValue :cstring) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc call *(this :Hash; inValue :cchar) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc call *(this :Hash; inValue :cint) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc HashCombine *[T](ioSeed :var cint; inValue :T) {.importcpp:"JPH::HashCombine<'*0>(@)", header:"Jolt/Jolt.h".}
const
  JPH_PI *:cfloat= 3.1415927410125732
  cLargeFloat *:cfloat= 999999986991104.0
proc DegreesToRadians *(inV :cfloat) :cfloat {.importcpp:"JPH::DegreesToRadians(@)", header:"Jolt/Jolt.h".}
proc RadiansToDegrees *(inV :cfloat) :cfloat {.importcpp:"JPH::RadiansToDegrees(@)", header:"Jolt/Jolt.h".}
proc CenterAngleAroundZero *(inV :cfloat) :cfloat {.importcpp:"JPH::CenterAngleAroundZero(@)", header:"Jolt/Jolt.h".}
proc DifferenceOfProducts *(inA :cfloat; inB :cfloat; inC :cfloat; inD :cfloat) :cfloat {.importcpp:"JPH::DifferenceOfProducts(@)", header:"Jolt/Jolt.h".}
proc Clamp *[T](inV :T; inMin :T; inMax :T) :T {.importcpp:"JPH::Clamp<'*0>(@)", header:"Jolt/Jolt.h".}
proc Square *[T](inV :T) :T {.importcpp:"JPH::Square<'*0>(@)", header:"Jolt/Jolt.h".}
proc Sqrt *(inV :cfloat) :cfloat {.importcpp:"JPH::Sqrt(@)", header:"Jolt/Jolt.h".}
proc Cubed *[T](inV :T) :T {.importcpp:"JPH::Cubed<'*0>(@)", header:"Jolt/Jolt.h".}
proc Sign *[T](inV :T) :T {.importcpp:"JPH::Sign<'*0>(@)", header:"Jolt/Jolt.h".}
proc IsPowerOf2 *[T](inV :T) :bool {.importcpp:"JPH::IsPowerOf2<'*0>(@)", header:"Jolt/Jolt.h".}
proc AlignUp *[T](inV :T; inAlignment :cint) :T {.importcpp:"JPH::AlignUp<'*0>(@)", header:"Jolt/Jolt.h".}
proc IsAligned *[T](inV :T; inAlignment :cint) :bool {.importcpp:"JPH::IsAligned<'*0>(@)", header:"Jolt/Jolt.h".}
proc CountTrailingZeros *(inValue :cint) :uint {.importcpp:"JPH::CountTrailingZeros(@)", header:"Jolt/Jolt.h".}
proc CountLeadingZeros *(inValue :cint) :uint {.importcpp:"JPH::CountLeadingZeros(@)", header:"Jolt/Jolt.h".}
proc CountBits *(inValue :cint) :uint {.importcpp:"JPH::CountBits(@)", header:"Jolt/Jolt.h".}
proc GetNextPowerOf2 *(inValue :cint) :cint {.importcpp:"JPH::GetNextPowerOf2(@)", header:"Jolt/Jolt.h".}
proc BitCast *[To, From](inValue :From) :To {.importcpp:"JPH::BitCast<'*0>(@)", header:"Jolt/Jolt.h".}
proc new *(inCount :cint) :pointer {.importcpp, header:"Jolt/Jolt.h".}
proc delete *(inPointer :pointer) {.importcpp, header:"Jolt/Jolt.h".}
proc delete *(inPointer :pointer; inSize :cint) {.importcpp, header:"Jolt/Jolt.h".}
proc newArray *(inCount :cint) :pointer {.importcpp, header:"Jolt/Jolt.h".}
proc deleteArray *(inPointer :pointer) {.importcpp, header:"Jolt/Jolt.h".}
proc deleteArray *(inPointer :pointer; inSize :cint) {.importcpp, header:"Jolt/Jolt.h".}
proc new *(inCount :cint; inAlignment :cint) :pointer {.importcpp, header:"Jolt/Jolt.h".}
proc delete *(inPointer :pointer; inSize :cint; inAlignment :cint) {.importcpp, header:"Jolt/Jolt.h".}
proc newArray *(inCount :cint; inAlignment :cint) :pointer {.importcpp, header:"Jolt/Jolt.h".}
proc deleteArray *(inPointer :pointer; inSize :cint; inAlignment :cint) {.importcpp, header:"Jolt/Jolt.h".}
proc new *(inCount :cint; inPointer :pointer) :pointer {.importcpp, header:"Jolt/Jolt.h".}
proc delete *(inPointer :pointer; inPlace :pointer) {.importcpp, header:"Jolt/Jolt.h".}
proc newArray *(inCount :cint; inPointer :pointer) :pointer {.importcpp, header:"Jolt/Jolt.h".}
proc deleteArray *(inPointer :pointer; inPlace :pointer) {.importcpp, header:"Jolt/Jolt.h".}
proc Float4_create *() :Float4 {.importcpp:"JPH::Float4(@)", constructor, header:"Jolt/Jolt.h".}
proc Float4_create *(inRHS :Float4) :Float4 {.importcpp:"JPH::Float4(@)", constructor, header:"Jolt/Jolt.h".}
proc Float4_create *(inX :cfloat; inY :cfloat; inZ :cfloat; inW :cfloat) :Float4 {.importcpp:"JPH::Float4(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var Float4; inRHS :Float4) :var Float4 {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc `[]` *(this :Float4; inCoordinate :cint) :cfloat {.importcpp:"#[#]", header:"Jolt/Jolt.h".}
proc `==` *(this :Float4; inRHS :Float4) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :Float4; inRHS :Float4) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
const
  SWIZZLE_X *:cint= 0
  SWIZZLE_Y *:cint= 1
  SWIZZLE_Z *:cint= 2
  SWIZZLE_W *:cint= 3
  SWIZZLE_UNUSED *:cint= 2
proc Vec4_create *() :Vec4 {.importcpp:"JPH::Vec4(@)", constructor, header:"Jolt/Jolt.h".}
proc Vec4_create *(inRHS :Vec4) :Vec4 {.importcpp:"JPH::Vec4(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var Vec4; inRHS :Vec4) :var Vec4 {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc Vec4_create *(inRHS :Vec3Arg) :Vec4 {.importcpp:"JPH::Vec4(@)", constructor, header:"Jolt/Jolt.h".}
proc Vec4_create *(inRHS :Vec3Arg; inW :cfloat) :Vec4 {.importcpp:"JPH::Vec4(@)", constructor, header:"Jolt/Jolt.h".}
proc Vec4_create *(inRHS :Type) :Vec4 {.importcpp:"JPH::Vec4(@)", constructor, header:"Jolt/Jolt.h".}
proc Vec4_create *(inX :cfloat; inY :cfloat; inZ :cfloat; inW :cfloat) :Vec4 {.importcpp:"JPH::Vec4(@)", constructor, header:"Jolt/Jolt.h".}
proc sZero *() :Vec4 {.importcpp:"JPH::Vec4::sZero(@)", header:"Jolt/Jolt.h".}
proc sOne *() :Vec4 {.importcpp:"JPH::Vec4::sOne(@)", header:"Jolt/Jolt.h".}
proc sNaN *() :Vec4 {.importcpp:"JPH::Vec4::sNaN(@)", header:"Jolt/Jolt.h".}
proc sReplicate *(inV :cfloat) :Vec4 {.importcpp:"JPH::Vec4::sReplicate(@)", header:"Jolt/Jolt.h".}
proc sLoadFloat4 *(inV :ptr Float4) :Vec4 {.importcpp:"JPH::Vec4::sLoadFloat4(@)", header:"Jolt/Jolt.h".}
proc sLoadFloat4Aligned *(inV :ptr Float4) :Vec4 {.importcpp:"JPH::Vec4::sLoadFloat4Aligned(@)", header:"Jolt/Jolt.h".}
proc sMin *(inV1 :Vec4Arg; inV2 :Vec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sMin(@)", header:"Jolt/Jolt.h".}
proc sMax *(inV1 :Vec4Arg; inV2 :Vec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sMax(@)", header:"Jolt/Jolt.h".}
proc sClamp *(inV :Vec4Arg; inMin :Vec4Arg; inMax :Vec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sClamp(@)", header:"Jolt/Jolt.h".}
proc sEquals *(inV1 :Vec4Arg; inV2 :Vec4Arg) :UVec4 {.importcpp:"JPH::Vec4::sEquals(@)", header:"Jolt/Jolt.h".}
proc sLess *(inV1 :Vec4Arg; inV2 :Vec4Arg) :UVec4 {.importcpp:"JPH::Vec4::sLess(@)", header:"Jolt/Jolt.h".}
proc sLessOrEqual *(inV1 :Vec4Arg; inV2 :Vec4Arg) :UVec4 {.importcpp:"JPH::Vec4::sLessOrEqual(@)", header:"Jolt/Jolt.h".}
proc sGreater *(inV1 :Vec4Arg; inV2 :Vec4Arg) :UVec4 {.importcpp:"JPH::Vec4::sGreater(@)", header:"Jolt/Jolt.h".}
proc sGreaterOrEqual *(inV1 :Vec4Arg; inV2 :Vec4Arg) :UVec4 {.importcpp:"JPH::Vec4::sGreaterOrEqual(@)", header:"Jolt/Jolt.h".}
proc sFusedMultiplyAdd *(inMul1 :Vec4Arg; inMul2 :Vec4Arg; inAdd :Vec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sFusedMultiplyAdd(@)", header:"Jolt/Jolt.h".}
proc sSelect *(inNotSet :Vec4Arg; inSet :Vec4Arg; inControl :UVec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sSelect(@)", header:"Jolt/Jolt.h".}
proc sOr *(inV1 :Vec4Arg; inV2 :Vec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sOr(@)", header:"Jolt/Jolt.h".}
proc sXor *(inV1 :Vec4Arg; inV2 :Vec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sXor(@)", header:"Jolt/Jolt.h".}
proc sAnd *(inV1 :Vec4Arg; inV2 :Vec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sAnd(@)", header:"Jolt/Jolt.h".}
proc sSort4 *(ioValue :var Vec4; ioIndex :var UVec4) {.importcpp:"JPH::Vec4::sSort4(@)", header:"Jolt/Jolt.h".}
proc sSort4Reverse *(ioValue :var Vec4; ioIndex :var UVec4) {.importcpp:"JPH::Vec4::sSort4Reverse(@)", header:"Jolt/Jolt.h".}
proc GetX *(this :Vec4) :cfloat {.importcpp:"#.GetX(@)", header:"Jolt/Jolt.h".}
proc GetY *(this :Vec4) :cfloat {.importcpp:"#.GetY(@)", header:"Jolt/Jolt.h".}
proc GetZ *(this :Vec4) :cfloat {.importcpp:"#.GetZ(@)", header:"Jolt/Jolt.h".}
proc GetW *(this :Vec4) :cfloat {.importcpp:"#.GetW(@)", header:"Jolt/Jolt.h".}
proc SetX *(this :var Vec4; inX :cfloat) {.importcpp:"#.SetX(@)", header:"Jolt/Jolt.h".}
proc SetY *(this :var Vec4; inY :cfloat) {.importcpp:"#.SetY(@)", header:"Jolt/Jolt.h".}
proc SetZ *(this :var Vec4; inZ :cfloat) {.importcpp:"#.SetZ(@)", header:"Jolt/Jolt.h".}
proc SetW *(this :var Vec4; inW :cfloat) {.importcpp:"#.SetW(@)", header:"Jolt/Jolt.h".}
proc Set *(this :var Vec4; inX :cfloat; inY :cfloat; inZ :cfloat; inW :cfloat) {.importcpp:"#.Set(@)", header:"Jolt/Jolt.h".}
proc `[]` *(this :Vec4; inCoordinate :uint) :cfloat {.importcpp:"#[#]", header:"Jolt/Jolt.h".}
proc `[]` *(this :var Vec4; inCoordinate :uint) :var cfloat {.importcpp:"#[#]", header:"Jolt/Jolt.h".}
proc `==` *(this :Vec4; inV2 :Vec4Arg) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :Vec4; inV2 :Vec4Arg) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
proc IsClose *(this :Vec4; inV2 :Vec4Arg; inMaxDistSq :cfloat) :bool {.importcpp:"#.IsClose(@)", header:"Jolt/Jolt.h".}
proc IsNearZero *(this :Vec4; inMaxDistSq :cfloat) :bool {.importcpp:"#.IsNearZero(@)", header:"Jolt/Jolt.h".}
proc IsNormalized *(this :Vec4; inTolerance :cfloat) :bool {.importcpp:"#.IsNormalized(@)", header:"Jolt/Jolt.h".}
proc IsNaN *(this :Vec4) :bool {.importcpp:"#.IsNaN(@)", header:"Jolt/Jolt.h".}
proc `*` *(this :Vec4; inV2 :Vec4Arg) :Vec4 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*` *(this :Vec4; inV2 :cfloat) :Vec4 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `/` *(this :Vec4; inV2 :cfloat) :Vec4 {.importcpp:"# / #", header:"Jolt/Jolt.h".}
proc `*=` *(this :var Vec4; inV2 :cfloat) :var Vec4 {.importcpp:"# *= #", discardable, header:"Jolt/Jolt.h".}
proc `*=` *(this :var Vec4; inV2 :Vec4Arg) :var Vec4 {.importcpp:"# *= #", discardable, header:"Jolt/Jolt.h".}
proc `/=` *(this :var Vec4; inV2 :cfloat) :var Vec4 {.importcpp:"# /= #", discardable, header:"Jolt/Jolt.h".}
proc `+` *(this :Vec4; inV2 :Vec4Arg) :Vec4 {.importcpp:"# + #", header:"Jolt/Jolt.h".}
proc `+=` *(this :var Vec4; inV2 :Vec4Arg) :var Vec4 {.importcpp:"# += #", discardable, header:"Jolt/Jolt.h".}
proc `-` *(this :Vec4) :Vec4 {.importcpp:"-#", header:"Jolt/Jolt.h".}
proc `-` *(this :Vec4; inV2 :Vec4Arg) :Vec4 {.importcpp:"# - #", header:"Jolt/Jolt.h".}
proc `-=` *(this :var Vec4; inV2 :Vec4Arg) :var Vec4 {.importcpp:"# -= #", discardable, header:"Jolt/Jolt.h".}
proc `/` *(this :Vec4; inV2 :Vec4Arg) :Vec4 {.importcpp:"# / #", header:"Jolt/Jolt.h".}
proc SplatX *(this :Vec4) :Vec4 {.importcpp:"#.SplatX(@)", header:"Jolt/Jolt.h".}
proc SplatY *(this :Vec4) :Vec4 {.importcpp:"#.SplatY(@)", header:"Jolt/Jolt.h".}
proc SplatZ *(this :Vec4) :Vec4 {.importcpp:"#.SplatZ(@)", header:"Jolt/Jolt.h".}
proc SplatW *(this :Vec4) :Vec4 {.importcpp:"#.SplatW(@)", header:"Jolt/Jolt.h".}
proc SplatX3 *(this :Vec4) :Vec3 {.importcpp:"#.SplatX3(@)", header:"Jolt/Jolt.h".}
proc SplatY3 *(this :Vec4) :Vec3 {.importcpp:"#.SplatY3(@)", header:"Jolt/Jolt.h".}
proc SplatZ3 *(this :Vec4) :Vec3 {.importcpp:"#.SplatZ3(@)", header:"Jolt/Jolt.h".}
proc SplatW3 *(this :Vec4) :Vec3 {.importcpp:"#.SplatW3(@)", header:"Jolt/Jolt.h".}
proc GetLowestComponentIndex *(this :Vec4) :cint {.importcpp:"#.GetLowestComponentIndex(@)", header:"Jolt/Jolt.h".}
proc GetHighestComponentIndex *(this :Vec4) :cint {.importcpp:"#.GetHighestComponentIndex(@)", header:"Jolt/Jolt.h".}
proc Abs *(this :Vec4) :Vec4 {.importcpp:"#.Abs(@)", header:"Jolt/Jolt.h".}
proc Reciprocal *(this :Vec4) :Vec4 {.importcpp:"#.Reciprocal(@)", header:"Jolt/Jolt.h".}
proc sDifferenceOfProducts *(inA :Vec4Arg; inB :Vec4Arg; inC :Vec4Arg; inD :Vec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sDifferenceOfProducts(@)", header:"Jolt/Jolt.h".}
proc DotV *(this :Vec4; inV2 :Vec4Arg) :Vec4 {.importcpp:"#.DotV(@)", header:"Jolt/Jolt.h".}
proc Dot *(this :Vec4; inV2 :Vec4Arg) :cfloat {.importcpp:"#.Dot(@)", header:"Jolt/Jolt.h".}
proc LengthSq *(this :Vec4) :cfloat {.importcpp:"#.LengthSq(@)", header:"Jolt/Jolt.h".}
proc Length *(this :Vec4) :cfloat {.importcpp:"#.Length(@)", header:"Jolt/Jolt.h".}
proc Normalized *(this :Vec4) :Vec4 {.importcpp:"#.Normalized(@)", header:"Jolt/Jolt.h".}
proc StoreFloat4 *(this :Vec4; outV :ptr Float4) {.importcpp:"#.StoreFloat4(@)", header:"Jolt/Jolt.h".}
proc ToInt *(this :Vec4) :UVec4 {.importcpp:"#.ToInt(@)", header:"Jolt/Jolt.h".}
proc ReinterpretAsInt *(this :Vec4) :UVec4 {.importcpp:"#.ReinterpretAsInt(@)", header:"Jolt/Jolt.h".}
proc GetSignBits *(this :Vec4) :cint {.importcpp:"#.GetSignBits(@)", header:"Jolt/Jolt.h".}
proc ReduceMin *(this :Vec4) :cfloat {.importcpp:"#.ReduceMin(@)", header:"Jolt/Jolt.h".}
proc ReduceMax *(this :Vec4) :cfloat {.importcpp:"#.ReduceMax(@)", header:"Jolt/Jolt.h".}
proc ReduceSum *(this :Vec4) :cfloat {.importcpp:"#.ReduceSum(@)", header:"Jolt/Jolt.h".}
proc Sqrt *(this :Vec4) :Vec4 {.importcpp:"#.Sqrt(@)", header:"Jolt/Jolt.h".}
proc GetSign *(this :Vec4) :Vec4 {.importcpp:"#.GetSign(@)", header:"Jolt/Jolt.h".}
proc SinCos *(this :Vec4; outSin :var Vec4; outCos :var Vec4) {.importcpp:"#.SinCos(@)", header:"Jolt/Jolt.h".}
proc Tan *(this :Vec4) :Vec4 {.importcpp:"#.Tan(@)", header:"Jolt/Jolt.h".}
proc ASin *(this :Vec4) :Vec4 {.importcpp:"#.ASin(@)", header:"Jolt/Jolt.h".}
proc ACos *(this :Vec4) :Vec4 {.importcpp:"#.ACos(@)", header:"Jolt/Jolt.h".}
proc ATan *(this :Vec4) :Vec4 {.importcpp:"#.ATan(@)", header:"Jolt/Jolt.h".}
proc sATan2 *(inY :Vec4Arg; inX :Vec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sATan2(@)", header:"Jolt/Jolt.h".}
proc CompressUnitVector *(this :Vec4) :cint {.importcpp:"#.CompressUnitVector(@)", header:"Jolt/Jolt.h".}
proc sDecompressUnitVector *(inValue :cint) :Vec4 {.importcpp:"JPH::Vec4::sDecompressUnitVector(@)", header:"Jolt/Jolt.h".}
proc Sin *(inX :cfloat) :cfloat {.importcpp:"JPH::Sin(@)", header:"Jolt/Jolt.h".}
proc Cos *(inX :cfloat) :cfloat {.importcpp:"JPH::Cos(@)", header:"Jolt/Jolt.h".}
proc Tan *(inX :cfloat) :cfloat {.importcpp:"JPH::Tan(@)", header:"Jolt/Jolt.h".}
proc ASin *(inX :cfloat) :cfloat {.importcpp:"JPH::ASin(@)", header:"Jolt/Jolt.h".}
proc ACos *(inX :cfloat) :cfloat {.importcpp:"JPH::ACos(@)", header:"Jolt/Jolt.h".}
proc ACosApproximate *(inX :cfloat) :cfloat {.importcpp:"JPH::ACosApproximate(@)", header:"Jolt/Jolt.h".}
proc ATan *(inX :cfloat) :cfloat {.importcpp:"JPH::ATan(@)", header:"Jolt/Jolt.h".}
proc ATan2 *(inY :cfloat; inX :cfloat) :cfloat {.importcpp:"JPH::ATan2(@)", header:"Jolt/Jolt.h".}
proc Float3_create *() :Float3 {.importcpp:"JPH::Float3(@)", constructor, header:"Jolt/Jolt.h".}
proc Float3_create *(inRHS :Float3) :Float3 {.importcpp:"JPH::Float3(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var Float3; inRHS :Float3) :var Float3 {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc Float3_create *(inX :cfloat; inY :cfloat; inZ :cfloat) :Float3 {.importcpp:"JPH::Float3(@)", constructor, header:"Jolt/Jolt.h".}
proc `[]` *(this :Float3; inCoordinate :cint) :cfloat {.importcpp:"#[#]", header:"Jolt/Jolt.h".}
proc `==` *(this :Float3; inRHS :Float3) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :Float3; inRHS :Float3) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
proc call *(this :Hash; t :JPH::Float3) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc Vec3_create *() :Vec3 {.importcpp:"JPH::Vec3(@)", constructor, header:"Jolt/Jolt.h".}
proc Vec3_create *(inRHS :Vec3) :Vec3 {.importcpp:"JPH::Vec3(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var Vec3; inRHS :Vec3) :var Vec3 {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc Vec3_create *(inRHS :Vec4Arg) :Vec3 {.importcpp:"JPH::Vec3(@)", constructor, header:"Jolt/Jolt.h".}
proc Vec3_create *(inRHS :Type) :Vec3 {.importcpp:"JPH::Vec3(@)", constructor, header:"Jolt/Jolt.h".}
proc Vec3_create *(inV :Float3) :Vec3 {.importcpp:"JPH::Vec3(@)", constructor, header:"Jolt/Jolt.h".}
proc Vec3_create *(inX :cfloat; inY :cfloat; inZ :cfloat) :Vec3 {.importcpp:"JPH::Vec3(@)", constructor, header:"Jolt/Jolt.h".}
proc sAxisX *() :Vec3 {.importcpp:"JPH::Vec3::sAxisX(@)", header:"Jolt/Jolt.h".}
proc sAxisY *() :Vec3 {.importcpp:"JPH::Vec3::sAxisY(@)", header:"Jolt/Jolt.h".}
proc sAxisZ *() :Vec3 {.importcpp:"JPH::Vec3::sAxisZ(@)", header:"Jolt/Jolt.h".}
proc sLoadFloat3Unsafe *(inV :Float3) :Vec3 {.importcpp:"JPH::Vec3::sLoadFloat3Unsafe(@)", header:"Jolt/Jolt.h".}
proc sMin *(inV1 :Vec3Arg; inV2 :Vec3Arg) :Vec3 {.importcpp:"JPH::Vec3::sMin(@)", header:"Jolt/Jolt.h".}
proc sMax *(inV1 :Vec3Arg; inV2 :Vec3Arg) :Vec3 {.importcpp:"JPH::Vec3::sMax(@)", header:"Jolt/Jolt.h".}
proc sClamp *(inV :Vec3Arg; inMin :Vec3Arg; inMax :Vec3Arg) :Vec3 {.importcpp:"JPH::Vec3::sClamp(@)", header:"Jolt/Jolt.h".}
proc sEquals *(inV1 :Vec3Arg; inV2 :Vec3Arg) :UVec4 {.importcpp:"JPH::Vec3::sEquals(@)", header:"Jolt/Jolt.h".}
proc sLess *(inV1 :Vec3Arg; inV2 :Vec3Arg) :UVec4 {.importcpp:"JPH::Vec3::sLess(@)", header:"Jolt/Jolt.h".}
proc sLessOrEqual *(inV1 :Vec3Arg; inV2 :Vec3Arg) :UVec4 {.importcpp:"JPH::Vec3::sLessOrEqual(@)", header:"Jolt/Jolt.h".}
proc sGreater *(inV1 :Vec3Arg; inV2 :Vec3Arg) :UVec4 {.importcpp:"JPH::Vec3::sGreater(@)", header:"Jolt/Jolt.h".}
proc sGreaterOrEqual *(inV1 :Vec3Arg; inV2 :Vec3Arg) :UVec4 {.importcpp:"JPH::Vec3::sGreaterOrEqual(@)", header:"Jolt/Jolt.h".}
proc sFusedMultiplyAdd *(inMul1 :Vec3Arg; inMul2 :Vec3Arg; inAdd :Vec3Arg) :Vec3 {.importcpp:"JPH::Vec3::sFusedMultiplyAdd(@)", header:"Jolt/Jolt.h".}
proc sSelect *(inNotSet :Vec3Arg; inSet :Vec3Arg; inControl :UVec4Arg) :Vec3 {.importcpp:"JPH::Vec3::sSelect(@)", header:"Jolt/Jolt.h".}
proc sOr *(inV1 :Vec3Arg; inV2 :Vec3Arg) :Vec3 {.importcpp:"JPH::Vec3::sOr(@)", header:"Jolt/Jolt.h".}
proc sXor *(inV1 :Vec3Arg; inV2 :Vec3Arg) :Vec3 {.importcpp:"JPH::Vec3::sXor(@)", header:"Jolt/Jolt.h".}
proc sAnd *(inV1 :Vec3Arg; inV2 :Vec3Arg) :Vec3 {.importcpp:"JPH::Vec3::sAnd(@)", header:"Jolt/Jolt.h".}
proc sUnitSpherical *(inTheta :cfloat; inPhi :cfloat) :Vec3 {.importcpp:"JPH::Vec3::sUnitSpherical(@)", header:"Jolt/Jolt.h".}
proc GetX *(this :Vec3) :cfloat {.importcpp:"#.GetX(@)", header:"Jolt/Jolt.h".}
proc GetY *(this :Vec3) :cfloat {.importcpp:"#.GetY(@)", header:"Jolt/Jolt.h".}
proc GetZ *(this :Vec3) :cfloat {.importcpp:"#.GetZ(@)", header:"Jolt/Jolt.h".}
proc SetX *(this :var Vec3; inX :cfloat) {.importcpp:"#.SetX(@)", header:"Jolt/Jolt.h".}
proc SetY *(this :var Vec3; inY :cfloat) {.importcpp:"#.SetY(@)", header:"Jolt/Jolt.h".}
proc SetZ *(this :var Vec3; inZ :cfloat) {.importcpp:"#.SetZ(@)", header:"Jolt/Jolt.h".}
proc Set *(this :var Vec3; inX :cfloat; inY :cfloat; inZ :cfloat) {.importcpp:"#.Set(@)", header:"Jolt/Jolt.h".}
proc `[]` *(this :Vec3; inCoordinate :uint) :cfloat {.importcpp:"#[#]", header:"Jolt/Jolt.h".}
proc SetComponent *(this :var Vec3; inCoordinate :uint; inValue :cfloat) {.importcpp:"#.SetComponent(@)", header:"Jolt/Jolt.h".}
proc `==` *(this :Vec3; inV2 :Vec3Arg) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :Vec3; inV2 :Vec3Arg) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
proc IsClose *(this :Vec3; inV2 :Vec3Arg; inMaxDistSq :cfloat) :bool {.importcpp:"#.IsClose(@)", header:"Jolt/Jolt.h".}
proc IsNearZero *(this :Vec3; inMaxDistSq :cfloat) :bool {.importcpp:"#.IsNearZero(@)", header:"Jolt/Jolt.h".}
proc IsNormalized *(this :Vec3; inTolerance :cfloat) :bool {.importcpp:"#.IsNormalized(@)", header:"Jolt/Jolt.h".}
proc IsNaN *(this :Vec3) :bool {.importcpp:"#.IsNaN(@)", header:"Jolt/Jolt.h".}
proc `*` *(this :Vec3; inV2 :Vec3Arg) :Vec3 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*` *(this :Vec3; inV2 :cfloat) :Vec3 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `/` *(this :Vec3; inV2 :cfloat) :Vec3 {.importcpp:"# / #", header:"Jolt/Jolt.h".}
proc `*=` *(this :var Vec3; inV2 :cfloat) :var Vec3 {.importcpp:"# *= #", discardable, header:"Jolt/Jolt.h".}
proc `*=` *(this :var Vec3; inV2 :Vec3Arg) :var Vec3 {.importcpp:"# *= #", discardable, header:"Jolt/Jolt.h".}
proc `/=` *(this :var Vec3; inV2 :cfloat) :var Vec3 {.importcpp:"# /= #", discardable, header:"Jolt/Jolt.h".}
proc `+` *(this :Vec3; inV2 :Vec3Arg) :Vec3 {.importcpp:"# + #", header:"Jolt/Jolt.h".}
proc `+=` *(this :var Vec3; inV2 :Vec3Arg) :var Vec3 {.importcpp:"# += #", discardable, header:"Jolt/Jolt.h".}
proc `-` *(this :Vec3) :Vec3 {.importcpp:"-#", header:"Jolt/Jolt.h".}
proc `-` *(this :Vec3; inV2 :Vec3Arg) :Vec3 {.importcpp:"# - #", header:"Jolt/Jolt.h".}
proc `-=` *(this :var Vec3; inV2 :Vec3Arg) :var Vec3 {.importcpp:"# -= #", discardable, header:"Jolt/Jolt.h".}
proc `/` *(this :Vec3; inV2 :Vec3Arg) :Vec3 {.importcpp:"# / #", header:"Jolt/Jolt.h".}
proc SplatX *(this :Vec3) :Vec4 {.importcpp:"#.SplatX(@)", header:"Jolt/Jolt.h".}
proc SplatY *(this :Vec3) :Vec4 {.importcpp:"#.SplatY(@)", header:"Jolt/Jolt.h".}
proc SplatZ *(this :Vec3) :Vec4 {.importcpp:"#.SplatZ(@)", header:"Jolt/Jolt.h".}
proc GetLowestComponentIndex *(this :Vec3) :cint {.importcpp:"#.GetLowestComponentIndex(@)", header:"Jolt/Jolt.h".}
proc GetHighestComponentIndex *(this :Vec3) :cint {.importcpp:"#.GetHighestComponentIndex(@)", header:"Jolt/Jolt.h".}
proc Abs *(this :Vec3) :Vec3 {.importcpp:"#.Abs(@)", header:"Jolt/Jolt.h".}
proc Reciprocal *(this :Vec3) :Vec3 {.importcpp:"#.Reciprocal(@)", header:"Jolt/Jolt.h".}
proc sDifferenceOfProducts *(inA :Vec3Arg; inB :Vec3Arg; inC :Vec3Arg; inD :Vec3Arg) :Vec3 {.importcpp:"JPH::Vec3::sDifferenceOfProducts(@)", header:"Jolt/Jolt.h".}
proc Cross *(this :Vec3; inV2 :Vec3Arg) :Vec3 {.importcpp:"#.Cross(@)", header:"Jolt/Jolt.h".}
proc CrossPrecise *(this :Vec3; inV2 :Vec3Arg) :Vec3 {.importcpp:"#.CrossPrecise(@)", header:"Jolt/Jolt.h".}
proc DotV *(this :Vec3; inV2 :Vec3Arg) :Vec3 {.importcpp:"#.DotV(@)", header:"Jolt/Jolt.h".}
proc DotV4 *(this :Vec3; inV2 :Vec3Arg) :Vec4 {.importcpp:"#.DotV4(@)", header:"Jolt/Jolt.h".}
proc Dot *(this :Vec3; inV2 :Vec3Arg) :cfloat {.importcpp:"#.Dot(@)", header:"Jolt/Jolt.h".}
proc LengthSq *(this :Vec3) :cfloat {.importcpp:"#.LengthSq(@)", header:"Jolt/Jolt.h".}
proc Length *(this :Vec3) :cfloat {.importcpp:"#.Length(@)", header:"Jolt/Jolt.h".}
proc Normalized *(this :Vec3) :Vec3 {.importcpp:"#.Normalized(@)", header:"Jolt/Jolt.h".}
proc NormalizedOr *(this :Vec3; inZeroValue :Vec3Arg) :Vec3 {.importcpp:"#.NormalizedOr(@)", header:"Jolt/Jolt.h".}
proc StoreFloat3 *(this :Vec3; outV :ptr Float3) {.importcpp:"#.StoreFloat3(@)", header:"Jolt/Jolt.h".}
proc ToInt *(this :Vec3) :UVec4 {.importcpp:"#.ToInt(@)", header:"Jolt/Jolt.h".}
proc ReinterpretAsInt *(this :Vec3) :UVec4 {.importcpp:"#.ReinterpretAsInt(@)", header:"Jolt/Jolt.h".}
proc ReduceMin *(this :Vec3) :cfloat {.importcpp:"#.ReduceMin(@)", header:"Jolt/Jolt.h".}
proc ReduceMax *(this :Vec3) :cfloat {.importcpp:"#.ReduceMax(@)", header:"Jolt/Jolt.h".}
proc ReduceSum *(this :Vec3) :cfloat {.importcpp:"#.ReduceSum(@)", header:"Jolt/Jolt.h".}
proc Sqrt *(this :Vec3) :Vec3 {.importcpp:"#.Sqrt(@)", header:"Jolt/Jolt.h".}
proc GetNormalizedPerpendicular *(this :Vec3) :Vec3 {.importcpp:"#.GetNormalizedPerpendicular(@)", header:"Jolt/Jolt.h".}
proc GetSign *(this :Vec3) :Vec3 {.importcpp:"#.GetSign(@)", header:"Jolt/Jolt.h".}
proc CompressUnitVector *(this :Vec3) :cint {.importcpp:"#.CompressUnitVector(@)", header:"Jolt/Jolt.h".}
proc CheckW *(this :Vec3) {.importcpp:"#.CheckW(@)", header:"Jolt/Jolt.h".}
proc sFixW *(inValue :Type) :Type {.importcpp:"JPH::Vec3::sFixW(@)", header:"Jolt/Jolt.h".}
proc UVec4_create *() :UVec4 {.importcpp:"JPH::UVec4(@)", constructor, header:"Jolt/Jolt.h".}
proc UVec4_create *(inRHS :UVec4) :UVec4 {.importcpp:"JPH::UVec4(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var UVec4; inRHS :UVec4) :var UVec4 {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc UVec4_create *(inRHS :Type) :UVec4 {.importcpp:"JPH::UVec4(@)", constructor, header:"Jolt/Jolt.h".}
proc UVec4_create *(inX :cint; inY :cint; inZ :cint; inW :cint) :UVec4 {.importcpp:"JPH::UVec4(@)", constructor, header:"Jolt/Jolt.h".}
proc `==` *(this :UVec4; inV2 :UVec4Arg) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :UVec4; inV2 :UVec4Arg) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
proc sReplicate *(inV :cint) :UVec4 {.importcpp:"JPH::UVec4::sReplicate(@)", header:"Jolt/Jolt.h".}
proc sLoadInt *(inV :ptr cint) :UVec4 {.importcpp:"JPH::UVec4::sLoadInt(@)", header:"Jolt/Jolt.h".}
proc sLoadInt4 *(inV :ptr cint) :UVec4 {.importcpp:"JPH::UVec4::sLoadInt4(@)", header:"Jolt/Jolt.h".}
proc sLoadInt4Aligned *(inV :ptr cint) :UVec4 {.importcpp:"JPH::UVec4::sLoadInt4Aligned(@)", header:"Jolt/Jolt.h".}
proc sMin *(inV1 :UVec4Arg; inV2 :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sMin(@)", header:"Jolt/Jolt.h".}
proc sMax *(inV1 :UVec4Arg; inV2 :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sMax(@)", header:"Jolt/Jolt.h".}
proc sEquals *(inV1 :UVec4Arg; inV2 :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sEquals(@)", header:"Jolt/Jolt.h".}
proc sSelect *(inNotSet :UVec4Arg; inSet :UVec4Arg; inControl :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sSelect(@)", header:"Jolt/Jolt.h".}
proc sOr *(inV1 :UVec4Arg; inV2 :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sOr(@)", header:"Jolt/Jolt.h".}
proc sXor *(inV1 :UVec4Arg; inV2 :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sXor(@)", header:"Jolt/Jolt.h".}
proc sAnd *(inV1 :UVec4Arg; inV2 :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sAnd(@)", header:"Jolt/Jolt.h".}
proc sNot *(inV1 :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sNot(@)", header:"Jolt/Jolt.h".}
proc sSort4True *(inValue :UVec4Arg; inIndex :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sSort4True(@)", header:"Jolt/Jolt.h".}
proc GetX *(this :UVec4) :cint {.importcpp:"#.GetX(@)", header:"Jolt/Jolt.h".}
proc GetY *(this :UVec4) :cint {.importcpp:"#.GetY(@)", header:"Jolt/Jolt.h".}
proc GetZ *(this :UVec4) :cint {.importcpp:"#.GetZ(@)", header:"Jolt/Jolt.h".}
proc GetW *(this :UVec4) :cint {.importcpp:"#.GetW(@)", header:"Jolt/Jolt.h".}
proc SetX *(this :var UVec4; inX :cint) {.importcpp:"#.SetX(@)", header:"Jolt/Jolt.h".}
proc SetY *(this :var UVec4; inY :cint) {.importcpp:"#.SetY(@)", header:"Jolt/Jolt.h".}
proc SetZ *(this :var UVec4; inZ :cint) {.importcpp:"#.SetZ(@)", header:"Jolt/Jolt.h".}
proc SetW *(this :var UVec4; inW :cint) {.importcpp:"#.SetW(@)", header:"Jolt/Jolt.h".}
proc `[]` *(this :UVec4; inCoordinate :uint) :cint {.importcpp:"#[#]", header:"Jolt/Jolt.h".}
proc `[]` *(this :var UVec4; inCoordinate :uint) :var cint {.importcpp:"#[#]", header:"Jolt/Jolt.h".}
proc `*` *(this :UVec4; inV2 :UVec4Arg) :UVec4 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `+` *(this :UVec4; inV2 :UVec4Arg) :UVec4 {.importcpp:"# + #", header:"Jolt/Jolt.h".}
proc `+=` *(this :var UVec4; inV2 :UVec4Arg) :var UVec4 {.importcpp:"# += #", discardable, header:"Jolt/Jolt.h".}
proc `-` *(this :UVec4; inV2 :UVec4Arg) :UVec4 {.importcpp:"# - #", header:"Jolt/Jolt.h".}
proc `-=` *(this :var UVec4; inV2 :UVec4Arg) :var UVec4 {.importcpp:"# -= #", discardable, header:"Jolt/Jolt.h".}
proc SplatX *(this :UVec4) :UVec4 {.importcpp:"#.SplatX(@)", header:"Jolt/Jolt.h".}
proc SplatY *(this :UVec4) :UVec4 {.importcpp:"#.SplatY(@)", header:"Jolt/Jolt.h".}
proc SplatZ *(this :UVec4) :UVec4 {.importcpp:"#.SplatZ(@)", header:"Jolt/Jolt.h".}
proc SplatW *(this :UVec4) :UVec4 {.importcpp:"#.SplatW(@)", header:"Jolt/Jolt.h".}
proc ToFloat *(this :UVec4) :Vec4 {.importcpp:"#.ToFloat(@)", header:"Jolt/Jolt.h".}
proc ReinterpretAsFloat *(this :UVec4) :Vec4 {.importcpp:"#.ReinterpretAsFloat(@)", header:"Jolt/Jolt.h".}
proc DotV *(this :UVec4; inV2 :UVec4Arg) :UVec4 {.importcpp:"#.DotV(@)", header:"Jolt/Jolt.h".}
proc Dot *(this :UVec4; inV2 :UVec4Arg) :cint {.importcpp:"#.Dot(@)", header:"Jolt/Jolt.h".}
proc StoreInt4 *(this :UVec4; outV :ptr cint) {.importcpp:"#.StoreInt4(@)", header:"Jolt/Jolt.h".}
proc StoreInt4Aligned *(this :UVec4; outV :ptr cint) {.importcpp:"#.StoreInt4Aligned(@)", header:"Jolt/Jolt.h".}
proc TestAnyTrue *(this :UVec4) :bool {.importcpp:"#.TestAnyTrue(@)", header:"Jolt/Jolt.h".}
proc TestAnyXYZTrue *(this :UVec4) :bool {.importcpp:"#.TestAnyXYZTrue(@)", header:"Jolt/Jolt.h".}
proc TestAllTrue *(this :UVec4) :bool {.importcpp:"#.TestAllTrue(@)", header:"Jolt/Jolt.h".}
proc TestAllXYZTrue *(this :UVec4) :bool {.importcpp:"#.TestAllXYZTrue(@)", header:"Jolt/Jolt.h".}
proc CountTrues *(this :UVec4) :cint {.importcpp:"#.CountTrues(@)", header:"Jolt/Jolt.h".}
proc GetTrues *(this :UVec4) :cint {.importcpp:"#.GetTrues(@)", header:"Jolt/Jolt.h".}
proc Expand4Uint16Lo *(this :UVec4) :UVec4 {.importcpp:"#.Expand4Uint16Lo(@)", header:"Jolt/Jolt.h".}
proc Expand4Uint16Hi *(this :UVec4) :UVec4 {.importcpp:"#.Expand4Uint16Hi(@)", header:"Jolt/Jolt.h".}
proc Expand4Byte0 *(this :UVec4) :UVec4 {.importcpp:"#.Expand4Byte0(@)", header:"Jolt/Jolt.h".}
proc Expand4Byte4 *(this :UVec4) :UVec4 {.importcpp:"#.Expand4Byte4(@)", header:"Jolt/Jolt.h".}
proc Expand4Byte8 *(this :UVec4) :UVec4 {.importcpp:"#.Expand4Byte8(@)", header:"Jolt/Jolt.h".}
proc Expand4Byte12 *(this :UVec4) :UVec4 {.importcpp:"#.Expand4Byte12(@)", header:"Jolt/Jolt.h".}
proc ShiftComponents4Minus *(this :UVec4; inCount :cint) :UVec4 {.importcpp:"#.ShiftComponents4Minus(@)", header:"Jolt/Jolt.h".}
proc Swizzle *() :UVec4 {.importcpp:"JPH::UVec4::Swizzle<'*0>(@)", header:"Jolt/Jolt.h".}
proc sGatherInt4 *(inBase :ptr cint; inOffsets :UVec4Arg) :UVec4 {.importcpp:"JPH::UVec4::sGatherInt4<'*0>(@)", header:"Jolt/Jolt.h".}
proc LogicalShiftLeft *() :UVec4 {.importcpp:"JPH::UVec4::LogicalShiftLeft<'*0>(@)", header:"Jolt/Jolt.h".}
proc LogicalShiftRight *() :UVec4 {.importcpp:"JPH::UVec4::LogicalShiftRight<'*0>(@)", header:"Jolt/Jolt.h".}
proc ArithmeticShiftRight *() :UVec4 {.importcpp:"JPH::UVec4::ArithmeticShiftRight<'*0>(@)", header:"Jolt/Jolt.h".}
proc call *(this :Hash; t :JPH::Vec3) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc sRandom *[Random](inRandom :var Random) :Vec3 {.importcpp:"JPH::Vec3::sRandom<'*0>(@)", header:"Jolt/Jolt.h".}
proc `*` *(inV1 :cfloat; inV2 :Vec3Arg) :Vec3 {.importcpp:"JPH::operator*(@)", header:"Jolt/Jolt.h".}
proc FlipSign *() :Vec3 {.importcpp:"JPH::Vec3::FlipSign<'*0>(@)", header:"Jolt/Jolt.h".}
proc sGatherFloat4 *(inBase :ptr cfloat; inOffsets :UVec4Arg) :Vec4 {.importcpp:"JPH::Vec4::sGatherFloat4<'*0>(@)", header:"Jolt/Jolt.h".}
proc Mat44_create *() :Mat44 {.importcpp:"JPH::Mat44(@)", constructor, header:"Jolt/Jolt.h".}
proc Mat44_create *(inC1 :Vec4Arg; inC2 :Vec4Arg; inC3 :Vec4Arg; inC4 :Vec4Arg) :Mat44 {.importcpp:"JPH::Mat44(@)", constructor, header:"Jolt/Jolt.h".}
proc Mat44_create *(inC1 :Vec4Arg; inC2 :Vec4Arg; inC3 :Vec4Arg; inC4 :Vec3Arg) :Mat44 {.importcpp:"JPH::Mat44(@)", constructor, header:"Jolt/Jolt.h".}
proc Mat44_create *(inM2 :Mat44) :Mat44 {.importcpp:"JPH::Mat44(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var Mat44; inM2 :Mat44) :var Mat44 {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc Mat44_create *(inC1 :Type; inC2 :Type; inC3 :Type; inC4 :Type) :Mat44 {.importcpp:"JPH::Mat44(@)", constructor, header:"Jolt/Jolt.h".}
proc sIdentity *() :Mat44 {.importcpp:"JPH::Mat44::sIdentity(@)", header:"Jolt/Jolt.h".}
proc sLoadFloat4x4 *(inV :ptr Float4) :Mat44 {.importcpp:"JPH::Mat44::sLoadFloat4x4(@)", header:"Jolt/Jolt.h".}
proc sLoadFloat4x4Aligned *(inV :ptr Float4) :Mat44 {.importcpp:"JPH::Mat44::sLoadFloat4x4Aligned(@)", header:"Jolt/Jolt.h".}
proc sRotationX *(inX :cfloat) :Mat44 {.importcpp:"JPH::Mat44::sRotationX(@)", header:"Jolt/Jolt.h".}
proc sRotationY *(inY :cfloat) :Mat44 {.importcpp:"JPH::Mat44::sRotationY(@)", header:"Jolt/Jolt.h".}
proc sRotationZ *(inZ :cfloat) :Mat44 {.importcpp:"JPH::Mat44::sRotationZ(@)", header:"Jolt/Jolt.h".}
proc sRotation *(inAxis :Vec3Arg; inAngle :cfloat) :Mat44 {.importcpp:"JPH::Mat44::sRotation(@)", header:"Jolt/Jolt.h".}
proc sRotation *(inQuat :QuatArg) :Mat44 {.importcpp:"JPH::Mat44::sRotation(@)", header:"Jolt/Jolt.h".}
proc sTranslation *(inV :Vec3Arg) :Mat44 {.importcpp:"JPH::Mat44::sTranslation(@)", header:"Jolt/Jolt.h".}
proc sRotationTranslation *(inR :QuatArg; inT :Vec3Arg) :Mat44 {.importcpp:"JPH::Mat44::sRotationTranslation(@)", header:"Jolt/Jolt.h".}
proc sInverseRotationTranslation *(inR :QuatArg; inT :Vec3Arg) :Mat44 {.importcpp:"JPH::Mat44::sInverseRotationTranslation(@)", header:"Jolt/Jolt.h".}
proc sScale *(inScale :cfloat) :Mat44 {.importcpp:"JPH::Mat44::sScale(@)", header:"Jolt/Jolt.h".}
proc sScale *(inV :Vec3Arg) :Mat44 {.importcpp:"JPH::Mat44::sScale(@)", header:"Jolt/Jolt.h".}
proc sOuterProduct *(inV1 :Vec3Arg; inV2 :Vec3Arg) :Mat44 {.importcpp:"JPH::Mat44::sOuterProduct(@)", header:"Jolt/Jolt.h".}
proc sCrossProduct *(inV :Vec3Arg) :Mat44 {.importcpp:"JPH::Mat44::sCrossProduct(@)", header:"Jolt/Jolt.h".}
proc sQuatLeftMultiply *(inQ :QuatArg) :Mat44 {.importcpp:"JPH::Mat44::sQuatLeftMultiply(@)", header:"Jolt/Jolt.h".}
proc sQuatRightMultiply *(inQ :QuatArg) :Mat44 {.importcpp:"JPH::Mat44::sQuatRightMultiply(@)", header:"Jolt/Jolt.h".}
proc sLookAt *(inPos :Vec3Arg; inTarget :Vec3Arg; inUp :Vec3Arg) :Mat44 {.importcpp:"JPH::Mat44::sLookAt(@)", header:"Jolt/Jolt.h".}
proc sPerspective *(inFovY :cfloat; inAspect :cfloat; inNear :cfloat; inFar :cfloat) :Mat44 {.importcpp:"JPH::Mat44::sPerspective(@)", header:"Jolt/Jolt.h".}
proc call *(this :Mat44; inRow :uint; inColumn :uint) :cfloat {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc call *(this :var Mat44; inRow :uint; inColumn :uint) :var cfloat {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc `==` *(this :Mat44; inM2 :Mat44Arg) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :Mat44; inM2 :Mat44Arg) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
proc IsClose *(this :Mat44; inM2 :Mat44Arg; inMaxDistSq :cfloat) :bool {.importcpp:"#.IsClose(@)", header:"Jolt/Jolt.h".}
proc `*` *(this :Mat44; inM :Mat44Arg) :Mat44 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*` *(this :Mat44; inV :Vec3Arg) :Vec3 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*` *(this :Mat44; inV :Vec4Arg) :Vec4 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc Multiply3x3 *(this :Mat44; inV :Vec3Arg) :Vec3 {.importcpp:"#.Multiply3x3(@)", header:"Jolt/Jolt.h".}
proc Multiply3x3Transposed *(this :Mat44; inV :Vec3Arg) :Vec3 {.importcpp:"#.Multiply3x3Transposed(@)", header:"Jolt/Jolt.h".}
proc Multiply3x3 *(this :Mat44; inM :Mat44Arg) :Mat44 {.importcpp:"#.Multiply3x3(@)", header:"Jolt/Jolt.h".}
proc Multiply3x3LeftTransposed *(this :Mat44; inM :Mat44Arg) :Mat44 {.importcpp:"#.Multiply3x3LeftTransposed(@)", header:"Jolt/Jolt.h".}
proc Multiply3x3RightTransposed *(this :Mat44; inM :Mat44Arg) :Mat44 {.importcpp:"#.Multiply3x3RightTransposed(@)", header:"Jolt/Jolt.h".}
proc `*` *(this :Mat44; inV :cfloat) :Mat44 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*=` *(this :var Mat44; inV :cfloat) :var Mat44 {.importcpp:"# *= #", discardable, header:"Jolt/Jolt.h".}
proc `+` *(this :Mat44; inM :Mat44Arg) :Mat44 {.importcpp:"# + #", header:"Jolt/Jolt.h".}
proc `-` *(this :Mat44) :Mat44 {.importcpp:"-#", header:"Jolt/Jolt.h".}
proc `-` *(this :Mat44; inM :Mat44Arg) :Mat44 {.importcpp:"# - #", header:"Jolt/Jolt.h".}
proc `+=` *(this :var Mat44; inM :Mat44Arg) :var Mat44 {.importcpp:"# += #", discardable, header:"Jolt/Jolt.h".}
proc GetAxisX *(this :Mat44) :Vec3 {.importcpp:"#.GetAxisX(@)", header:"Jolt/Jolt.h".}
proc SetAxisX *(this :var Mat44; inV :Vec3Arg) {.importcpp:"#.SetAxisX(@)", header:"Jolt/Jolt.h".}
proc GetAxisY *(this :Mat44) :Vec3 {.importcpp:"#.GetAxisY(@)", header:"Jolt/Jolt.h".}
proc SetAxisY *(this :var Mat44; inV :Vec3Arg) {.importcpp:"#.SetAxisY(@)", header:"Jolt/Jolt.h".}
proc GetAxisZ *(this :Mat44) :Vec3 {.importcpp:"#.GetAxisZ(@)", header:"Jolt/Jolt.h".}
proc SetAxisZ *(this :var Mat44; inV :Vec3Arg) {.importcpp:"#.SetAxisZ(@)", header:"Jolt/Jolt.h".}
proc GetTranslation *(this :Mat44) :Vec3 {.importcpp:"#.GetTranslation(@)", header:"Jolt/Jolt.h".}
proc SetTranslation *(this :var Mat44; inV :Vec3Arg) {.importcpp:"#.SetTranslation(@)", header:"Jolt/Jolt.h".}
proc GetDiagonal3 *(this :Mat44) :Vec3 {.importcpp:"#.GetDiagonal3(@)", header:"Jolt/Jolt.h".}
proc SetDiagonal3 *(this :var Mat44; inV :Vec3Arg) {.importcpp:"#.SetDiagonal3(@)", header:"Jolt/Jolt.h".}
proc GetDiagonal4 *(this :Mat44) :Vec4 {.importcpp:"#.GetDiagonal4(@)", header:"Jolt/Jolt.h".}
proc SetDiagonal4 *(this :var Mat44; inV :Vec4Arg) {.importcpp:"#.SetDiagonal4(@)", header:"Jolt/Jolt.h".}
proc GetColumn3 *(this :Mat44; inCol :uint) :Vec3 {.importcpp:"#.GetColumn3(@)", header:"Jolt/Jolt.h".}
proc SetColumn3 *(this :var Mat44; inCol :uint; inV :Vec3Arg) {.importcpp:"#.SetColumn3(@)", header:"Jolt/Jolt.h".}
proc GetColumn4 *(this :Mat44; inCol :uint) :Vec4 {.importcpp:"#.GetColumn4(@)", header:"Jolt/Jolt.h".}
proc SetColumn4 *(this :var Mat44; inCol :uint; inV :Vec4Arg) {.importcpp:"#.SetColumn4(@)", header:"Jolt/Jolt.h".}
proc StoreFloat4x4 *(this :Mat44; outV :ptr Float4) {.importcpp:"#.StoreFloat4x4(@)", header:"Jolt/Jolt.h".}
proc Transposed *(this :Mat44) :Mat44 {.importcpp:"#.Transposed(@)", header:"Jolt/Jolt.h".}
proc Transposed3x3 *(this :Mat44) :Mat44 {.importcpp:"#.Transposed3x3(@)", header:"Jolt/Jolt.h".}
proc Inversed *(this :Mat44) :Mat44 {.importcpp:"#.Inversed(@)", header:"Jolt/Jolt.h".}
proc InversedRotationTranslation *(this :Mat44) :Mat44 {.importcpp:"#.InversedRotationTranslation(@)", header:"Jolt/Jolt.h".}
proc GetDeterminant3x3 *(this :Mat44) :cfloat {.importcpp:"#.GetDeterminant3x3(@)", header:"Jolt/Jolt.h".}
proc Adjointed3x3 *(this :Mat44) :Mat44 {.importcpp:"#.Adjointed3x3(@)", header:"Jolt/Jolt.h".}
proc Inversed3x3 *(this :Mat44) :Mat44 {.importcpp:"#.Inversed3x3(@)", header:"Jolt/Jolt.h".}
proc SetInversed3x3 *(this :var Mat44; inM :Mat44Arg) :bool {.importcpp:"#.SetInversed3x3(@)", header:"Jolt/Jolt.h".}
proc GetRotation *(this :Mat44) :Mat44 {.importcpp:"#.GetRotation(@)", header:"Jolt/Jolt.h".}
proc GetRotationSafe *(this :Mat44) :Mat44 {.importcpp:"#.GetRotationSafe(@)", header:"Jolt/Jolt.h".}
proc SetRotation *(this :var Mat44; inRotation :Mat44Arg) {.importcpp:"#.SetRotation(@)", header:"Jolt/Jolt.h".}
proc GetQuaternion *(this :Mat44) :Quat {.importcpp:"#.GetQuaternion(@)", header:"Jolt/Jolt.h".}
proc GetDirectionPreservingMatrix *(this :Mat44) :Mat44 {.importcpp:"#.GetDirectionPreservingMatrix(@)", header:"Jolt/Jolt.h".}
proc PreTranslated *(this :Mat44; inTranslation :Vec3Arg) :Mat44 {.importcpp:"#.PreTranslated(@)", header:"Jolt/Jolt.h".}
proc PostTranslated *(this :Mat44; inTranslation :Vec3Arg) :Mat44 {.importcpp:"#.PostTranslated(@)", header:"Jolt/Jolt.h".}
proc PreScaled *(this :Mat44; inScale :Vec3Arg) :Mat44 {.importcpp:"#.PreScaled(@)", header:"Jolt/Jolt.h".}
proc PostScaled *(this :Mat44; inScale :Vec3Arg) :Mat44 {.importcpp:"#.PostScaled(@)", header:"Jolt/Jolt.h".}
proc Decompose *(this :Mat44; outScale :var Vec3) :Mat44 {.importcpp:"#.Decompose(@)", header:"Jolt/Jolt.h".}
proc ToMat44 *(this :Mat44) :Mat44 {.importcpp:"#.ToMat44(@)", header:"Jolt/Jolt.h".}
proc Quat_create *() :Quat {.importcpp:"JPH::Quat(@)", constructor, header:"Jolt/Jolt.h".}
proc Quat_create *(inRHS :Quat) :Quat {.importcpp:"JPH::Quat(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var Quat; inRHS :Quat) :var Quat {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc Quat_create *(inX :cfloat; inY :cfloat; inZ :cfloat; inW :cfloat) :Quat {.importcpp:"JPH::Quat(@)", constructor, header:"Jolt/Jolt.h".}
proc Quat_create *(inV :Float4) :Quat {.importcpp:"JPH::Quat(@)", constructor, header:"Jolt/Jolt.h".}
proc Quat_create *(inV :Vec4Arg) :Quat {.importcpp:"JPH::Quat(@)", constructor, header:"Jolt/Jolt.h".}
proc `==` *(this :Quat; inRHS :QuatArg) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :Quat; inRHS :QuatArg) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
proc IsClose *(this :Quat; inRHS :QuatArg; inMaxDistSq :cfloat) :bool {.importcpp:"#.IsClose(@)", header:"Jolt/Jolt.h".}
proc IsNormalized *(this :Quat; inTolerance :cfloat) :bool {.importcpp:"#.IsNormalized(@)", header:"Jolt/Jolt.h".}
proc IsNaN *(this :Quat) :bool {.importcpp:"#.IsNaN(@)", header:"Jolt/Jolt.h".}
proc GetX *(this :Quat) :cfloat {.importcpp:"#.GetX(@)", header:"Jolt/Jolt.h".}
proc GetY *(this :Quat) :cfloat {.importcpp:"#.GetY(@)", header:"Jolt/Jolt.h".}
proc GetZ *(this :Quat) :cfloat {.importcpp:"#.GetZ(@)", header:"Jolt/Jolt.h".}
proc GetW *(this :Quat) :cfloat {.importcpp:"#.GetW(@)", header:"Jolt/Jolt.h".}
proc GetXYZ *(this :Quat) :Vec3 {.importcpp:"#.GetXYZ(@)", header:"Jolt/Jolt.h".}
proc GetXYZW *(this :Quat) :Vec4 {.importcpp:"#.GetXYZW(@)", header:"Jolt/Jolt.h".}
proc SetX *(this :var Quat; inX :cfloat) {.importcpp:"#.SetX(@)", header:"Jolt/Jolt.h".}
proc SetY *(this :var Quat; inY :cfloat) {.importcpp:"#.SetY(@)", header:"Jolt/Jolt.h".}
proc SetZ *(this :var Quat; inZ :cfloat) {.importcpp:"#.SetZ(@)", header:"Jolt/Jolt.h".}
proc SetW *(this :var Quat; inW :cfloat) {.importcpp:"#.SetW(@)", header:"Jolt/Jolt.h".}
proc Set *(this :var Quat; inX :cfloat; inY :cfloat; inZ :cfloat; inW :cfloat) {.importcpp:"#.Set(@)", header:"Jolt/Jolt.h".}
proc GetAxisAngle *(this :Quat; outAxis :var Vec3; outAngle :var cfloat) {.importcpp:"#.GetAxisAngle(@)", header:"Jolt/Jolt.h".}
proc GetAngularVelocity *(this :Quat; inDeltaTime :cfloat) :Vec3 {.importcpp:"#.GetAngularVelocity(@)", header:"Jolt/Jolt.h".}
proc sFromTo *(inFrom :Vec3Arg; inTo :Vec3Arg) :Quat {.importcpp:"JPH::Quat::sFromTo(@)", header:"Jolt/Jolt.h".}
proc sEulerAngles *(inAngles :Vec3Arg) :Quat {.importcpp:"JPH::Quat::sEulerAngles(@)", header:"Jolt/Jolt.h".}
proc GetEulerAngles *(this :Quat) :Vec3 {.importcpp:"#.GetEulerAngles(@)", header:"Jolt/Jolt.h".}
proc LengthSq *(this :Quat) :cfloat {.importcpp:"#.LengthSq(@)", header:"Jolt/Jolt.h".}
proc Length *(this :Quat) :cfloat {.importcpp:"#.Length(@)", header:"Jolt/Jolt.h".}
proc Normalized *(this :Quat) :Quat {.importcpp:"#.Normalized(@)", header:"Jolt/Jolt.h".}
proc `+=` *(this :var Quat; inRHS :QuatArg) {.importcpp:"# += #", discardable, header:"Jolt/Jolt.h".}
proc `-=` *(this :var Quat; inRHS :QuatArg) {.importcpp:"# -= #", discardable, header:"Jolt/Jolt.h".}
proc `*=` *(this :var Quat; inValue :cfloat) {.importcpp:"# *= #", discardable, header:"Jolt/Jolt.h".}
proc `/=` *(this :var Quat; inValue :cfloat) {.importcpp:"# /= #", discardable, header:"Jolt/Jolt.h".}
proc `-` *(this :Quat) :Quat {.importcpp:"-#", header:"Jolt/Jolt.h".}
proc `+` *(this :Quat; inRHS :QuatArg) :Quat {.importcpp:"# + #", header:"Jolt/Jolt.h".}
proc `-` *(this :Quat; inRHS :QuatArg) :Quat {.importcpp:"# - #", header:"Jolt/Jolt.h".}
proc `*` *(this :Quat; inRHS :QuatArg) :Quat {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*` *(this :Quat; inValue :cfloat) :Quat {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `/` *(this :Quat; inValue :cfloat) :Quat {.importcpp:"# / #", header:"Jolt/Jolt.h".}
proc `*` *(this :Quat; inValue :Vec3Arg) :Vec3 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc sMultiplyImaginary *(inLHS :Vec3Arg; inRHS :QuatArg) :Quat {.importcpp:"JPH::Quat::sMultiplyImaginary(@)", header:"Jolt/Jolt.h".}
proc InverseRotate *(this :Quat; inValue :Vec3Arg) :Vec3 {.importcpp:"#.InverseRotate(@)", header:"Jolt/Jolt.h".}
proc RotateAxisX *(this :Quat) :Vec3 {.importcpp:"#.RotateAxisX(@)", header:"Jolt/Jolt.h".}
proc RotateAxisY *(this :Quat) :Vec3 {.importcpp:"#.RotateAxisY(@)", header:"Jolt/Jolt.h".}
proc RotateAxisZ *(this :Quat) :Vec3 {.importcpp:"#.RotateAxisZ(@)", header:"Jolt/Jolt.h".}
proc Dot *(this :Quat; inRHS :QuatArg) :cfloat {.importcpp:"#.Dot(@)", header:"Jolt/Jolt.h".}
proc Conjugated *(this :Quat) :Quat {.importcpp:"#.Conjugated(@)", header:"Jolt/Jolt.h".}
proc Inversed *(this :Quat) :Quat {.importcpp:"#.Inversed(@)", header:"Jolt/Jolt.h".}
proc EnsureWPositive *(this :Quat) :Quat {.importcpp:"#.EnsureWPositive(@)", header:"Jolt/Jolt.h".}
proc GetPerpendicular *(this :Quat) :Quat {.importcpp:"#.GetPerpendicular(@)", header:"Jolt/Jolt.h".}
proc GetRotationAngle *(this :Quat; inAxis :Vec3Arg) :cfloat {.importcpp:"#.GetRotationAngle(@)", header:"Jolt/Jolt.h".}
proc GetTwist *(this :Quat; inAxis :Vec3Arg) :Quat {.importcpp:"#.GetTwist(@)", header:"Jolt/Jolt.h".}
proc GetSwingTwist *(this :Quat; outSwing :var Quat; outTwist :var Quat) {.importcpp:"#.GetSwingTwist(@)", header:"Jolt/Jolt.h".}
proc LERP *(this :Quat; inDestination :QuatArg; inFraction :cfloat) :Quat {.importcpp:"#.LERP(@)", header:"Jolt/Jolt.h".}
proc SLERP *(this :Quat; inDestination :QuatArg; inFraction :cfloat) :Quat {.importcpp:"#.SLERP(@)", header:"Jolt/Jolt.h".}
proc StoreFloat3 *(this :Quat; outV :ptr Float3) {.importcpp:"#.StoreFloat3(@)", header:"Jolt/Jolt.h".}
proc StoreFloat4 *(this :Quat; outV :ptr Float4) {.importcpp:"#.StoreFloat4(@)", header:"Jolt/Jolt.h".}
proc CompressUnitQuat *(this :Quat) :cint {.importcpp:"#.CompressUnitQuat(@)", header:"Jolt/Jolt.h".}
proc sDecompressUnitQuat *(inValue :cint) :Quat {.importcpp:"JPH::Quat::sDecompressUnitQuat(@)", header:"Jolt/Jolt.h".}
proc Double3_create *() :Double3 {.importcpp:"JPH::Double3(@)", constructor, header:"Jolt/Jolt.h".}
proc Double3_create *(inRHS :Double3) :Double3 {.importcpp:"JPH::Double3(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var Double3; inRHS :Double3) :var Double3 {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc Double3_create *(inX :cdouble; inY :cdouble; inZ :cdouble) :Double3 {.importcpp:"JPH::Double3(@)", constructor, header:"Jolt/Jolt.h".}
proc `[]` *(this :Double3; inCoordinate :cint) :cdouble {.importcpp:"#[#]", header:"Jolt/Jolt.h".}
proc `==` *(this :Double3; inRHS :Double3) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :Double3; inRHS :Double3) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
proc call *(this :Hash; t :JPH::Double3) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc DVec3_create *() :DVec3 {.importcpp:"JPH::DVec3(@)", constructor, header:"Jolt/Jolt.h".}
proc DVec3_create *(inRHS :DVec3) :DVec3 {.importcpp:"JPH::DVec3(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var DVec3; inRHS :DVec3) :var DVec3 {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc DVec3_create *(inRHS :Vec3Arg) :DVec3 {.importcpp:"JPH::DVec3(@)", constructor, header:"Jolt/Jolt.h".}
proc DVec3_create *(inRHS :Vec4Arg) :DVec3 {.importcpp:"JPH::DVec3(@)", constructor, header:"Jolt/Jolt.h".}
proc DVec3_create *(inRHS :TypeArg) :DVec3 {.importcpp:"JPH::DVec3(@)", constructor, header:"Jolt/Jolt.h".}
proc DVec3_create *(inX :cdouble; inY :cdouble; inZ :cdouble) :DVec3 {.importcpp:"JPH::DVec3(@)", constructor, header:"Jolt/Jolt.h".}
proc DVec3_create *(inV :Double3) :DVec3 {.importcpp:"JPH::DVec3(@)", constructor, header:"Jolt/Jolt.h".}
proc sReplicate *(inV :cdouble) :DVec3 {.importcpp:"JPH::DVec3::sReplicate(@)", header:"Jolt/Jolt.h".}
proc sLoadDouble3Unsafe *(inV :Double3) :DVec3 {.importcpp:"JPH::DVec3::sLoadDouble3Unsafe(@)", header:"Jolt/Jolt.h".}
proc StoreDouble3 *(this :DVec3; outV :ptr Double3) {.importcpp:"#.StoreDouble3(@)", header:"Jolt/Jolt.h".}
proc toVec3 *(this :DVec3) :Vec3 {.importcpp:"#.operator Vec3(@)", header:"Jolt/Jolt.h".}
proc PrepareRoundToZero *(this :DVec3) :DVec3 {.importcpp:"#.PrepareRoundToZero(@)", header:"Jolt/Jolt.h".}
proc PrepareRoundToInf *(this :DVec3) :DVec3 {.importcpp:"#.PrepareRoundToInf(@)", header:"Jolt/Jolt.h".}
proc ToVec3RoundDown *(this :DVec3) :Vec3 {.importcpp:"#.ToVec3RoundDown(@)", header:"Jolt/Jolt.h".}
proc ToVec3RoundUp *(this :DVec3) :Vec3 {.importcpp:"#.ToVec3RoundUp(@)", header:"Jolt/Jolt.h".}
proc sMin *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sMin(@)", header:"Jolt/Jolt.h".}
proc sMax *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sMax(@)", header:"Jolt/Jolt.h".}
proc sClamp *(inV :DVec3Arg; inMin :DVec3Arg; inMax :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sClamp(@)", header:"Jolt/Jolt.h".}
proc sEquals *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sEquals(@)", header:"Jolt/Jolt.h".}
proc sLess *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sLess(@)", header:"Jolt/Jolt.h".}
proc sLessOrEqual *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sLessOrEqual(@)", header:"Jolt/Jolt.h".}
proc sGreater *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sGreater(@)", header:"Jolt/Jolt.h".}
proc sGreaterOrEqual *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sGreaterOrEqual(@)", header:"Jolt/Jolt.h".}
proc sFusedMultiplyAdd *(inMul1 :DVec3Arg; inMul2 :DVec3Arg; inAdd :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sFusedMultiplyAdd(@)", header:"Jolt/Jolt.h".}
proc sSelect *(inNotSet :DVec3Arg; inSet :DVec3Arg; inControl :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sSelect(@)", header:"Jolt/Jolt.h".}
proc sOr *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sOr(@)", header:"Jolt/Jolt.h".}
proc sXor *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sXor(@)", header:"Jolt/Jolt.h".}
proc sAnd *(inV1 :DVec3Arg; inV2 :DVec3Arg) :DVec3 {.importcpp:"JPH::DVec3::sAnd(@)", header:"Jolt/Jolt.h".}
proc GetTrues *(this :DVec3) :cint {.importcpp:"#.GetTrues(@)", header:"Jolt/Jolt.h".}
proc TestAnyTrue *(this :DVec3) :bool {.importcpp:"#.TestAnyTrue(@)", header:"Jolt/Jolt.h".}
proc TestAllTrue *(this :DVec3) :bool {.importcpp:"#.TestAllTrue(@)", header:"Jolt/Jolt.h".}
proc GetX *(this :DVec3) :cdouble {.importcpp:"#.GetX(@)", header:"Jolt/Jolt.h".}
proc GetY *(this :DVec3) :cdouble {.importcpp:"#.GetY(@)", header:"Jolt/Jolt.h".}
proc GetZ *(this :DVec3) :cdouble {.importcpp:"#.GetZ(@)", header:"Jolt/Jolt.h".}
proc SetX *(this :var DVec3; inX :cdouble) {.importcpp:"#.SetX(@)", header:"Jolt/Jolt.h".}
proc SetY *(this :var DVec3; inY :cdouble) {.importcpp:"#.SetY(@)", header:"Jolt/Jolt.h".}
proc SetZ *(this :var DVec3; inZ :cdouble) {.importcpp:"#.SetZ(@)", header:"Jolt/Jolt.h".}
proc Set *(this :var DVec3; inX :cdouble; inY :cdouble; inZ :cdouble) {.importcpp:"#.Set(@)", header:"Jolt/Jolt.h".}
proc `[]` *(this :DVec3; inCoordinate :uint) :cdouble {.importcpp:"#[#]", header:"Jolt/Jolt.h".}
proc SetComponent *(this :var DVec3; inCoordinate :uint; inValue :cdouble) {.importcpp:"#.SetComponent(@)", header:"Jolt/Jolt.h".}
proc `==` *(this :DVec3; inV2 :DVec3Arg) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :DVec3; inV2 :DVec3Arg) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
proc IsClose *(this :DVec3; inV2 :DVec3Arg; inMaxDistSq :cdouble) :bool {.importcpp:"#.IsClose(@)", header:"Jolt/Jolt.h".}
proc IsNearZero *(this :DVec3; inMaxDistSq :cdouble) :bool {.importcpp:"#.IsNearZero(@)", header:"Jolt/Jolt.h".}
proc IsNormalized *(this :DVec3; inTolerance :cdouble) :bool {.importcpp:"#.IsNormalized(@)", header:"Jolt/Jolt.h".}
proc IsNaN *(this :DVec3) :bool {.importcpp:"#.IsNaN(@)", header:"Jolt/Jolt.h".}
proc `*` *(this :DVec3; inV2 :DVec3Arg) :DVec3 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*` *(this :DVec3; inV2 :cdouble) :DVec3 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `/` *(this :DVec3; inV2 :cdouble) :DVec3 {.importcpp:"# / #", header:"Jolt/Jolt.h".}
proc `*=` *(this :var DVec3; inV2 :cdouble) :var DVec3 {.importcpp:"# *= #", discardable, header:"Jolt/Jolt.h".}
proc `*=` *(this :var DVec3; inV2 :DVec3Arg) :var DVec3 {.importcpp:"# *= #", discardable, header:"Jolt/Jolt.h".}
proc `/=` *(this :var DVec3; inV2 :cdouble) :var DVec3 {.importcpp:"# /= #", discardable, header:"Jolt/Jolt.h".}
proc `+` *(this :DVec3; inV2 :Vec3Arg) :DVec3 {.importcpp:"# + #", header:"Jolt/Jolt.h".}
proc `+` *(this :DVec3; inV2 :DVec3Arg) :DVec3 {.importcpp:"# + #", header:"Jolt/Jolt.h".}
proc `+=` *(this :var DVec3; inV2 :Vec3Arg) :var DVec3 {.importcpp:"# += #", discardable, header:"Jolt/Jolt.h".}
proc `+=` *(this :var DVec3; inV2 :DVec3Arg) :var DVec3 {.importcpp:"# += #", discardable, header:"Jolt/Jolt.h".}
proc `-` *(this :DVec3) :DVec3 {.importcpp:"-#", header:"Jolt/Jolt.h".}
proc `-` *(this :DVec3; inV2 :Vec3Arg) :DVec3 {.importcpp:"# - #", header:"Jolt/Jolt.h".}
proc `-` *(this :DVec3; inV2 :DVec3Arg) :DVec3 {.importcpp:"# - #", header:"Jolt/Jolt.h".}
proc `-=` *(this :var DVec3; inV2 :Vec3Arg) :var DVec3 {.importcpp:"# -= #", discardable, header:"Jolt/Jolt.h".}
proc `-=` *(this :var DVec3; inV2 :DVec3Arg) :var DVec3 {.importcpp:"# -= #", discardable, header:"Jolt/Jolt.h".}
proc `/` *(this :DVec3; inV2 :DVec3Arg) :DVec3 {.importcpp:"# / #", header:"Jolt/Jolt.h".}
proc Abs *(this :DVec3) :DVec3 {.importcpp:"#.Abs(@)", header:"Jolt/Jolt.h".}
proc Reciprocal *(this :DVec3) :DVec3 {.importcpp:"#.Reciprocal(@)", header:"Jolt/Jolt.h".}
proc Cross *(this :DVec3; inV2 :DVec3Arg) :DVec3 {.importcpp:"#.Cross(@)", header:"Jolt/Jolt.h".}
proc Dot *(this :DVec3; inV2 :DVec3Arg) :cdouble {.importcpp:"#.Dot(@)", header:"Jolt/Jolt.h".}
proc LengthSq *(this :DVec3) :cdouble {.importcpp:"#.LengthSq(@)", header:"Jolt/Jolt.h".}
proc Length *(this :DVec3) :cdouble {.importcpp:"#.Length(@)", header:"Jolt/Jolt.h".}
proc Normalized *(this :DVec3) :DVec3 {.importcpp:"#.Normalized(@)", header:"Jolt/Jolt.h".}
proc Sqrt *(this :DVec3) :DVec3 {.importcpp:"#.Sqrt(@)", header:"Jolt/Jolt.h".}
proc GetSign *(this :DVec3) :DVec3 {.importcpp:"#.GetSign(@)", header:"Jolt/Jolt.h".}
proc CheckW *(this :DVec3) {.importcpp:"#.CheckW(@)", header:"Jolt/Jolt.h".}
proc sFixW *(inValue :TypeArg) :Type {.importcpp:"JPH::DVec3::sFixW(@)", header:"Jolt/Jolt.h".}
proc call *(this :Hash; t :JPH::DVec3) :cint {.importcpp:"#(@)", header:"Jolt/Jolt.h".}
proc DMat44_create *() :DMat44 {.importcpp:"JPH::DMat44(@)", constructor, header:"Jolt/Jolt.h".}
proc DMat44_create *(inC1 :Vec4Arg; inC2 :Vec4Arg; inC3 :Vec4Arg; inC4 :DVec3Arg) :DMat44 {.importcpp:"JPH::DMat44(@)", constructor, header:"Jolt/Jolt.h".}
proc DMat44_create *(inM2 :DMat44) :DMat44 {.importcpp:"JPH::DMat44(@)", constructor, header:"Jolt/Jolt.h".}
proc assign *(this :var DMat44; inM2 :DMat44) :var DMat44 {.importcpp:"# = #", discardable, header:"Jolt/Jolt.h".}
proc DMat44_create *(inM :Mat44Arg) :DMat44 {.importcpp:"JPH::DMat44(@)", constructor, header:"Jolt/Jolt.h".}
proc DMat44_create *(inRot :Mat44Arg; inT :DVec3Arg) :DMat44 {.importcpp:"JPH::DMat44(@)", constructor, header:"Jolt/Jolt.h".}
proc DMat44_create *(inC1 :Type; inC2 :Type; inC3 :Type; inC4 :DTypeArg) :DMat44 {.importcpp:"JPH::DMat44(@)", constructor, header:"Jolt/Jolt.h".}
proc sTranslation *(inV :DVec3Arg) :DMat44 {.importcpp:"JPH::DMat44::sTranslation(@)", header:"Jolt/Jolt.h".}
proc sRotationTranslation *(inR :QuatArg; inT :DVec3Arg) :DMat44 {.importcpp:"JPH::DMat44::sRotationTranslation(@)", header:"Jolt/Jolt.h".}
proc sInverseRotationTranslation *(inR :QuatArg; inT :DVec3Arg) :DMat44 {.importcpp:"JPH::DMat44::sInverseRotationTranslation(@)", header:"Jolt/Jolt.h".}
proc ToMat44 *(this :DMat44) :Mat44 {.importcpp:"#.ToMat44(@)", header:"Jolt/Jolt.h".}
proc `==` *(this :DMat44; inM2 :DMat44Arg) :bool {.importcpp:"# == #", header:"Jolt/Jolt.h".}
proc `!=` *(this :DMat44; inM2 :DMat44Arg) :bool {.importcpp:"# != #", header:"Jolt/Jolt.h".}
proc IsClose *(this :DMat44; inM2 :DMat44Arg; inMaxDistSq :cfloat) :bool {.importcpp:"#.IsClose(@)", header:"Jolt/Jolt.h".}
proc `*` *(this :DMat44; inM :Mat44Arg) :DMat44 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*` *(this :DMat44; inM :DMat44Arg) :DMat44 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*` *(this :DMat44; inV :Vec3Arg) :DVec3 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc `*` *(this :DMat44; inV :DVec3Arg) :DVec3 {.importcpp:"# * #", header:"Jolt/Jolt.h".}
proc Multiply3x3 *(this :DMat44; inV :Vec3Arg) :Vec3 {.importcpp:"#.Multiply3x3(@)", header:"Jolt/Jolt.h".}
proc Multiply3x3 *(this :DMat44; inV :DVec3Arg) :DVec3 {.importcpp:"#.Multiply3x3(@)", header:"Jolt/Jolt.h".}
proc Multiply3x3Transposed *(this :DMat44; inV :Vec3Arg) :Vec3 {.importcpp:"#.Multiply3x3Transposed(@)", header:"Jolt/Jolt.h".}
proc PreScaled *(this :DMat44; inScale :Vec3Arg) :DMat44 {.importcpp:"#.PreScaled(@)", header:"Jolt/Jolt.h".}
proc PostScaled *(this :DMat44; inScale :Vec3Arg) :DMat44 {.importcpp:"#.PostScaled(@)", header:"Jolt/Jolt.h".}
proc PreTranslated *(this :DMat44; inTranslation :Vec3Arg) :DMat44 {.importcpp:"#.PreTranslated(@)", header:"Jolt/Jolt.h".}
proc PreTranslated *(this :DMat44; inTranslation :DVec3Arg) :DMat44 {.importcpp:"#.PreTranslated(@)", header:"Jolt/Jolt.h".}
proc PostTranslated *(this :DMat44; inTranslation :Vec3Arg) :DMat44 {.importcpp:"#.PostTranslated(@)", header:"Jolt/Jolt.h".}
proc PostTranslated *(this :DMat44; inTranslation :DVec3Arg) :DMat44 {.importcpp:"#.PostTranslated(@)", header:"Jolt/Jolt.h".}
proc GetAxisX *(this :DMat44) :Vec3 {.importcpp:"#.GetAxisX(@)", header:"Jolt/Jolt.h".}
proc SetAxisX *(this :var DMat44; inV :Vec3Arg) {.importcpp:"#.SetAxisX(@)", header:"Jolt/Jolt.h".}
proc GetAxisY *(this :DMat44) :Vec3 {.importcpp:"#.GetAxisY(@)", header:"Jolt/Jolt.h".}
proc SetAxisY *(this :var DMat44; inV :Vec3Arg) {.importcpp:"#.SetAxisY(@)", header:"Jolt/Jolt.h".}
proc GetAxisZ *(this :DMat44) :Vec3 {.importcpp:"#.GetAxisZ(@)", header:"Jolt/Jolt.h".}
proc SetAxisZ *(this :var DMat44; inV :Vec3Arg) {.importcpp:"#.SetAxisZ(@)", header:"Jolt/Jolt.h".}
proc GetTranslation *(this :DMat44) :DVec3 {.importcpp:"#.GetTranslation(@)", header:"Jolt/Jolt.h".}
proc SetTranslation *(this :var DMat44; inV :DVec3Arg) {.importcpp:"#.SetTranslation(@)", header:"Jolt/Jolt.h".}
proc GetColumn3 *(this :DMat44; inCol :uint) :Vec3 {.importcpp:"#.GetColumn3(@)", header:"Jolt/Jolt.h".}
proc SetColumn3 *(this :var DMat44; inCol :uint; inV :Vec3Arg) {.importcpp:"#.SetColumn3(@)", header:"Jolt/Jolt.h".}
proc GetColumn4 *(this :DMat44; inCol :uint) :Vec4 {.importcpp:"#.GetColumn4(@)", header:"Jolt/Jolt.h".}
proc SetColumn4 *(this :var DMat44; inCol :uint; inV :Vec4Arg) {.importcpp:"#.SetColumn4(@)", header:"Jolt/Jolt.h".}
proc Transposed3x3 *(this :DMat44) :Mat44 {.importcpp:"#.Transposed3x3(@)", header:"Jolt/Jolt.h".}
proc Inversed *(this :DMat44) :DMat44 {.importcpp:"#.Inversed(@)", header:"Jolt/Jolt.h".}
proc InversedRotationTranslation *(this :DMat44) :DMat44 {.importcpp:"#.InversedRotationTranslation(@)", header:"Jolt/Jolt.h".}
proc GetRotation *(this :DMat44) :Mat44 {.importcpp:"#.GetRotation(@)", header:"Jolt/Jolt.h".}
proc SetRotation *(this :var DMat44; inRotation :Mat44Arg) {.importcpp:"#.SetRotation(@)", header:"Jolt/Jolt.h".}
proc GetQuaternion *(this :DMat44) :Quat {.importcpp:"#.GetQuaternion(@)", header:"Jolt/Jolt.h".}
proc GetDirectionPreservingMatrix *(this :DMat44) :Mat44 {.importcpp:"#.GetDirectionPreservingMatrix(@)", header:"Jolt/Jolt.h".}
proc Decompose *(this :DMat44; outScale :var Vec3) :DMat44 {.importcpp:"#.Decompose(@)", header:"Jolt/Jolt.h".}
proc r *(inValue :clongdouble) :Real {.importcpp:"JPH::literals::operator\"\"_r(@)", header:"Jolt/Jolt.h".}
