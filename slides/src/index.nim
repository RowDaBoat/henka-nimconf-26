##########################################################
## henka-nimconf-26  slides                             ##
## ISC License                                          ##
## Copyright (c) [2026] Ivan Mar (sOkam!) and RowDaBoat ##
##########################################################
import nimib, nimislides
import style
import std/strformat

let henka    {.inject.} = color(nimYellow, "henka")
let langNim  {.inject.} = color(nimYellow, "Nim")
let langC    {.inject.} = color(nimYellow, "C")
let langCpp  {.inject.} = color(nimYellow, "C++")
let langJsTs {.inject.} = color(nimYellow, "JS/TS")

const nimconfSurvivor = """
  <div id="game"></div>
  <script src="/survivor_demo/node_modules/phaser/dist/phaser.min.js"></script>
  <script type="module">
    import * as Box2D from "/survivor_demo/node_modules/phaser-box2d/dist/PhaserBox2D.min.js"
    Object.assign(globalThis, Box2D)
    const s = document.createElement("script")
    s.src = "/survivor_demo/bullet_heaven.js"
    document.body.appendChild(s)
  </script>
"""

const webgpuJolt = """
  <style>
    #cubes-canvas {
      display: block;
      margin: 1rem auto;
      background: #000;
      width: 960px;
      height: 540px;
    }
  </style>
  <canvas id="cubes-canvas" width="1920" height="1080"></canvas>
  <script>
    var Module = {
      canvas:   document.getElementById("cubes-canvas"),
      print:    function (text) { console.log(text); },
      printErr: function (text) { console.error(text); },
    };

    window.__mx = 0;
    window.__my = 0;
    Module.canvas.addEventListener("mousemove", function (e) {
      var r = Module.canvas.getBoundingClientRect();
      window.__mx = ((e.clientX - r.left) / r.width) * 2 - 1;
      window.__my = -(((e.clientY - r.top) / r.height) * 2 - 1);
    });
  </script>
  <script src="/cubes_demo/build/cubes.js"></script>
"""

const disableKeys = """
  <script>
    window.addEventListener('load', function () {
      Reveal.configure({
        keyboardCondition: function (event) {
          return event.keyCode !== 65 && event.keyCode !== 83;
        }
      });
    });
  </script>
"""

template title =
  slide:
    nbText "## Henka, Bind Anything"

    fragmentFadeIn:
      nbText &"How {langNim}👑 can be glued to just about any language."

template whoAreWe =
  slide:
    nbText "## Who are we?"

    fragmentFadeIn:
      let sokam {.inject.} = color(nimYellow, ".sOkam!")
      nbRawHtml img("img/sokam.png", align = "left", circle = true)
      nbRawHtml pLeft(&"{sokam}, game and engine developer.")

    fragmentFadeIn:
      let webgpuNim {.inject.} = link("https://github.com/RowDaBoat/webgpu-nim", "webgpu-nim")
      let cvulkan   {.inject.} = link("https://codeberg.org/heysokam/cvulkan", "cvulkan")
      nbRawHtml pLeft(&"Author of {webgpuNim} and {cvulkan}.")

    fragmentFadeIn:
      let row {.inject.} = color(nimYellow, "Row")
      nbRawHtml clearStyle
      nbRawHtml img("img/row.png", align = "right", circle = true)
      nbRawHtml pLeft(&"{row}, gamedev/demoscener,")
      nbRawHtml pLeft(&"fairly new to {langNim}.")

    fragmentFadeIn:
      let reploid    {.inject.} = link("https://github.com/RowDaBoat/reploid", "reploid")
      let shadercNim {.inject.} = link("https://github.com/RowDaBoat/shaderc-nim", "shaderc-nim")
      nbRawHtml pLeft(&"Author of {reploid} and {shadercNim}.")

template introduction =
  slide:
    nbText "## Henka"

    fragmentFadeIn:
      nbText &"{henka} is a bindings generator for {langNim}."

    fragmentFadeInSameLine(&"supporting {langC}", &", {langCpp}", &" and {langJsTs}")

    fragmentFadeIn:
      let henkaJp  {.inject.} = color(nimYellow, "変化 (hen-ka)")
      nbRawHtml clearStyle
      nbText &"{henkaJp}: change, variation, transformation in Japanese."

  slide:
    nbText "## Futhark"

    fragmentFadeIn:
      nbText "**Futhark already exists and it's awesome,**"
      nbText "**why did we not extend it?**"

    unorderedList:
      listItem(fadeIn):
        nbText "Our main motivator was curiosity."
      listItem(fadeIn):
        nbText "We wanted to start on a blank slate."
      listItem(fadeIn):
        nbText "Also to try different architectural choices."
      listItem(fadeIn):
        nbText "And use it as an excuse to experiment with AI."

template usage =
  slide:
    nbText "## Henka CLI"

    unorderedList:
      listItem(fadeIn):
        nbText &"Generating {langC} bindings from the command line is simple."

      listItem(fadeIn):
        nbText &"Running {henka} from the CLI:"
        nbText """
  ```bash
  $ henka point.h
  ```
  """

      listItem(fadeIn):
        nbText "On this header:"
        nbText """
  ```c
  struct Point {
      float x;
      float y;
  };

  float point_magnitude(struct Point p);
  ```
  """

  slide:
    nbText "## Henka CLI"
    unorderedList:
      listItem(fadeIn):
        nbText "Generates " & color(nimYellow, "`point.nim`") & ":"
        nbCode:
          type
            struct_Point* {.bycopy, importc:"struct Point", header:"point.h".} = object
              x* :cint
              y* :cint
            Point* = struct_Point
          proc point_magnitude*(p :struct_Point) :cfloat {.importc:"magnitude", cdecl, header:"point.h".}

  slide:
    unorderedList:
      listItem:
        nbText &"Generating {langCpp} and {langJsTs} bindings:"
        nbText """
```bash
$ henka --cpp --std=c++17 --js header.hpp
$ henka --js lib.js
```
"""

  slide:
    nbText "## Henka as a library"

    unorderedList:
      listItem(fadeIn):
        nbText &"Henka can be imported and called from {langNim} code."

    fragmentFadeIn:
      nbCodeSkip:
        import henka

        let bindings = generate("header.h")

  slide:
    nbText "## Refining the bindings"

    unorderedList:
      listItem(fadeIn):
        nbText &"Calling it from {langNim} allows customizing how bindings are generated."

    fragmentFadeIn:
      nbCodeSkip:
        proc rename(kind: henka.LabelKind, name: string): string =
          result = name.replace("point_", "")

        proc pragmas(kind: henka.LabelKind, name: string, defaults: seq[(string, string)]): seq[(string, string)] =
          result = defaults

          if kind is henka.StructType:
            result.add [("pure", ""), ("inheritable", "")]

        let bindings = generate(
          headerPath,
          renamer = rename,
          pragmaOverride = pragmas
        )


template showcase =
  slide:
    nbText "# Demos!"
  slide:
    nbRawHtml webgpuJolt

  slide:
    nbText "## [WebGPU](https://webgpu.org/) + [Jolt Physics](https://github.com/jrouwe/joltphysics)"
    unorderedList:
      listItem(fadeIn):
        nbText "[WebGPU C bindings](https://github.com/rowdaboat/webgpu-nim), fully supported."
      listItem(fadeIn):
        nbText "Jolt Physics C++ bindings, proof of concept."
      listItem(fadeIn):
        nbText "Nim C++ backend with emscripten."

  slide:
    nbRawHtml nimconfSurvivor

  slide:
    nbText "## [Phaser](https://phaser.io/)"
    unorderedList:
      listItem(fadeIn):
        nbText "Phaser JS bindings, proof of concept."
      listItem(fadeIn):
        nbText "Phaser Box2D JS bindings, proof of concept."
      listItem(fadeIn):
        nbText "Nim JS backend."


when isMainModule:
  myInit("index.nim")
  nbRawHtml disableKeys

  slide:
    title
    whoAreWe

  slide: introduction
  slide: usage
  slide: showcase

  nbSave
