# @deps std
from std/os import parentDir, `/`, normalizedPath
# @deps external
from henka import nil

const thisDir = currentSourcePath().parentDir()
const joltDir = thisDir/"JoltPhysics"

when isMainModule:
  let output = henka.generate(
    inputFile = joltDir/"Jolt"/"Jolt.h",
    rootPath  = joltDir.normalizedPath,
    clangArgs = @["-I" & joltDir.normalizedPath],
    isCpp     = true,
    linkMode  = henka.LinkMode.header,
  )
  system.writeFile(thisDir/"jolt.nim", output)
