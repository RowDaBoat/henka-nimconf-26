# @deps std
from std/os import parentDir, `/`, normalizedPath
from std/strutils import endsWith
# @deps external
from henka import nil

const thisDir = currentSourcePath().parentDir()
const joltDir = thisDir/"JoltPhysics"

proc filter(kind: henka.LabelKind, name: string): bool =
  name notin [
    "JPH_EXPORT_GCC_BUG_WORKAROUND",
    "JPH_SUPPRESS_WARNING_PUSH",
    "JPH_SUPPRESS_WARNING_POP",
    "JPH_SUPPRESS_WARNINGS",
    "JPH_BREAKPOINT",
    "JPH_NAMESPACE_BEGIN",
    "JPH_NAMESPACE_END",
    "JPH_SUPPRESS_WARNINGS_STD_BEGIN",
    "JPH_SUPPRESS_WARNINGS_STD_END",
    "JPH_DEFAULT_ALLOCATE_ALIGNMENT",
    "JPH_FUNCTION_NAME",
    "JPH_OVERRIDE_NEW_DELETE",
    "JPH_EL",
    "JPH_INLINE",
    "JPH_PRECISE_MATH_ON",
    "JPH_PRECISE_MATH_OFF",
  ]

when isMainModule:
  let output = henka.generate(
    inputFiles   = @[
      joltDir/"Jolt"/"Jolt.h",
      joltDir/"Jolt"/"Core"/"Factory.h",
      joltDir/"Jolt"/"RegisterTypes.h",
    ],
    rootPath     = joltDir.normalizedPath,
    clangArgs    = @[
      "-I" & joltDir.normalizedPath,
      "-std=c++17",
      "-include", joltDir.normalizedPath/"Jolt"/"Jolt.h",
    ],
    isCpp        = true,
    symbolFilter = filter,
    singleFileParse = false,
    linkMode     = henka.LinkMode.header,
  )

  var combined = ""
  for module in output.modules:
    if module.definitions.len > 0:
      combined.add module.definitions
      if not combined.endsWith("\n"):
        combined.add "\n"

  system.writeFile(thisDir/"jolt.nim", combined)
