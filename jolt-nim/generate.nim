# @deps std
from std/os import parentDir, `/`, normalizedPath
# @deps external
from henka import nil

const thisDir = currentSourcePath().parentDir()
const joltDir = thisDir/"JoltPhysics"

# Macros whose bodies aren't valid Nim constant expressions (C/C++ token soup,
# or references to symbols henka doesn't emit). Skip them entirely.
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
    # Compiler-directive macros (__attribute__, _Pragma) that henka emits as
    # raw {.emit.} C, dumping junk into the generated C output.
    "JPH_INLINE",
    "JPH_PRECISE_MATH_ON",
    "JPH_PRECISE_MATH_OFF",
  ]

when isMainModule:
  let output = henka.generate(
    inputFile    = joltDir/"Jolt"/"Jolt.h",
    rootPath     = joltDir.normalizedPath,
    clangArgs    = @["-I" & joltDir.normalizedPath],
    isCpp        = true,
    symbolFilter = filter,
    linkMode     = henka.LinkMode.header,
  )
  system.writeFile(thisDir/"jolt.nim", output)
