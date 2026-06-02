#########################################################
## henka-nimconf-26  WebGPU + Jolt Cubes demo           ##
## ISC License                                          ##
## Copyright (c) [2026] Ivan Mar (sOkam!) and RowDaBoat ##
##########################################################

{.emit: """
#include <emscripten.h>
""".}

proc emscripten_get_now*(): cdouble
  {.importc, header:"<emscripten.h>".}

proc emscripten_set_main_loop*(
  f                 :proc() {.cdecl.};
  fps               :cint;
  simulateInfinite  :cint;
)
  {.importc, header:"<emscripten.h>".}
