##########################################################
## henka-nimconf-26  slides                             ##
## ISC License                                          ##
## Copyright (c) [2026] Ivan Mar (sOkam!) and RowDaBoat ##
##########################################################
import nimib, nimiSlides
import style
import std/strformat

let henka    {.inject.} = color(nimYellow, "Henka")
let langNim  {.inject.} = color(nimYellow, "Nim")
let langC    {.inject.} = color(nimYellow, "C")
let langCpp  {.inject.} = color(nimYellow, "C++")
let langJsTs {.inject.} = color(nimYellow, "JS/TS")

const nimconfSurvivor = """
  <div id="game"></div>
  <script src="/survivor_demo/phaser.min.js"></script>
  <script type="module">
    import * as Box2D from "/survivor_demo/PhaserBox2D.min.js"
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
  <script src="/cubes_demo/cubes.js"></script>
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
    nbImage("img/henka.svg")
    nbText "## Bind Anything"

    fragmentFadeIn:
      nbText &"How we bound {langNim} to native and web libraries."

template presentationLink =
  slide:
    nbText &"https://rowdaboat.github.io/henka-nimconf-26"

template whoAreWe =
  slide:
    nbText "## Who we are"

    fragmentFadeIn:
      let row {.inject.} = color(nimYellow, "Row")
      nbRawHtml clearStyle
      nbRawHtml img("img/row.png", align = "left", circle = true)
      nbRawHtml pLeft(&"{row}, gamedev/demoscener.")

    fragmentFadeIn:
      let reploid    {.inject.} = link("https://github.com/RowDaBoat/reploid", "reploid")
      let shadercNim {.inject.} = link("https://github.com/RowDaBoat/shaderc-nim", "shaderc-nim")
      nbRawHtml pLeft(&"Author of {reploid} and {shadercNim}.<br/>")

    fragmentFadeIn:
      let sokam {.inject.} = color(nimYellow, ".sOkam!")
      nbRawHtml "<br/>"
      nbRawHtml img("img/sokam.png", align = "right", circle = true)
      nbRawHtml pLeft(&"{sokam}, game and engine developer.")

    fragmentFadeIn:
      let webgpuNim {.inject.} = link("https://github.com/RowDaBoat/webgpu-nim", "webgpu-nim")
      let cvulkan   {.inject.} = link("https://codeberg.org/heysokam/cvulkan", "cvulkan")
      nbRawHtml pLeft(&"Author of {webgpuNim} and {cvulkan}.")

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
    nbText "## Command Line Interface"

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
    nbText &"## {henka} CLI"
    unorderedList:
      listItem(fadeIn):
        nbText "Generates " & color(nimYellow, "`point.nim`") & ":"
        nbCode:
          type
            struct_Point* {.bycopy, importc:"struct Point", header:"point.h".} = object
              x* :cfloat
              y* :cfloat
            Point* = struct_Point
          proc point_magnitude*(p :struct_Point) :cfloat {.importc:"point_magnitude", cdecl, header:"point.h".}

  slide:
    nbText &"## {henka} CLI"
    fragmentFadeIn:
      nbText &"Generating bindings:"
    unorderedList:
      listItem(fadeIn):
         nbText &"For {langCpp}:"
         nbText """
```
$ henka --cpp --std=c++17 header.hpp
```
"""
      listItem(fadeIn):
         nbText &"For {langJsTs}:"
         nbText """
```
$ henka --js lib.js
```
"""

  slide:
    nbText &"## {henka} as a library"

    unorderedList:
      listItem(fadeIn):
        nbText &"However, {henka} is best used as a library."

    fragmentFadeIn:
      nbCodeSkip:
        import henka

        let bindings = generate("header.h")
        "bindings.nim".writeFile(bindings)

  slide:
    nbText "### Customization is a first class citizen"

    unorderedList:
      listItem(fadeIn):
        nbText &"Importing {henka} as a library allows for complete customization of the output"

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

  slide:
    nbText &"## {henka} as a library"
    unorderedList:
      listItem(fadeIn):
        nbText "Generating a cleaner " & color(nimYellow, "`point.nim`") & ":"
        nbCodeSkip:
          type Point *{.bycopy, importc:"struct Point", header:"header.h", pure, inheritable.}= object
            x *:cfloat
            y *:cfloat
          proc magnitude *(p :Point) :cfloat {.importc:"point_magnitude", cdecl, header:"header.h".}


template showcase =
  slide:
    nbText "# Demo 1"

  slide:
    nbRawHtml webgpuJolt

  slide:
    nbText "## [WebGPU](https://webgpu.org/) + [Jolt Physics](https://github.com/jrouwe/joltphysics)"
    unorderedList:
      listItem(fadeIn):
        nbText  &"[WebGPU bindings](https://github.com/rowdaboat/webgpu-nim), {langC}, fully supported."
      listItem(fadeIn):
        nbText &"Jolt Physics bindings, {langCpp}, proof of concept."
      listItem(fadeIn):
        nbText &"Nim {langCpp} backend with emscripten."

  slide:
    nbText "# Demo 2"

  slide:
    nbRawHtml nimconfSurvivor

  slide:
    nbText "## [Phaser](https://phaser.io/)"
    unorderedList:
      listItem(fadeIn):
        nbText "Phaser bindings, JS, proof of concept."
      listItem(fadeIn):
        nbText "Phaser Box2D bindings, JS, proof of concept."
      listItem(fadeIn):
        nbText "Nim JS backend."


template henkav1 =
  slide:
    nbText &"## {henka} v1"
    nbText "### Architecture"
    unorderedList:
      listItem(fadeIn):
        nbText  "v1 generated Nim bindings for C using"
        nbText  "`clang -ast-dump=json`."
      listItem(fadeIn):
        nbText &"Initially, we wanted to keep {henka} independent from `libclang` and its API."
      listItem(fadeIn):
        nbText  "Reason 1: easy to parse JSON data."
      listItem(fadeIn):
        nbText  "Reason 2: fewer binary dependencies, easier to port and get working anywhere."

  slide:
    nbText &"## {henka} v1"
    nbText "### How it worked"
    unorderedList:
      listItem(fadeIn):
        nbText "1  - Walk the AST JSON data."
      listItem(fadeIn):
        nbText "2  - Handle edge cases: unnamed unions/structs, forward declarations, and enum value duplications."
      listItem(fadeIn):
        nbText "3  - Generate Nim code for types, variables, and functions."
      listItem(fadeIn):
        nbText "Basic symbol renamer for customizing the output."

  autoAnimateSlides(6):
    nbText &"## {henka} v1"
    nbText "### Workflow"
    showText(@[
      ({1},  ""),
      ({2}, &"Adding features to henka was straightforward using real-world libraries as dogfood."),
      ({3},  "1  - Find a complex C library (eg: webgpu.h)"),
      ({4},  "2  - Fix edge cases on the generator (assisted with Claude)."),
      ({5},  "3  - Review, rewrite or discard the code."),
      ({6},  "4  - Repeat."),
    ])
    adaptiveColumns:
      column:
        showAt(3..3): nbImage("img/webgpu-header.svg")
      column:
        showAt(3..3): nbImage("img/henka-arrow.svg")
      column:
        showAt(3..6): nbImage("img/nim-file-bind.svg")
      column:
        showAt(4..6): nbImage("img/write-arrow.svg")
      column:
        showAt(4..6): nbImage("img/henka-small.svg")



template henkav2 =
  slide:
    nbText &"## {henka} v2"
    nbText  "### Starting over"
    unorderedList:
      listItem(fadeIn):
        nbText  "We went back to using `libclang`."
      listItem(fadeIn):
        nbText &"~~Reason 1: easy to parse JSON data.~~ libclang is clear enough, and supports extended features."
      listItem(fadeIn):
        nbText &"~~Reason 2: fewer dependencies...~~ True, but bindings are generated once, and distributed via source control."
      listItem(fadeIn):
        nbText &"This is an design distinction from Futhark, which builds bindings in compile-time instead."

  slide:
    nbText &"## {henka} v2"
    nbText  "### New features, more scale"
    unorderedList:
      listItem(fadeIn):
        nbText &"v2 supports {langC}, {langCpp}, and {langJsTs}."
      listItem(fadeIn):
        nbText "Callbacks for pragmas and symbols: rename, override, filter, resolve unnamed, etc."
      listItem(fadeIn):
        nbText "Supports generating bindings for both static and dynamically linked libraries."
      listItem(fadeIn):
        nbText "Support for generating enums as cint, distinct cint, and pure/impure enums."

  slide:
    nbText &"## {henka} v2"
    nbText  "### New features, more scale"
    unorderedList:
      listItem(fadeIn):
        nbText &"{langCpp} blew the scale out of proportion:"
      fragmentFadeInSameLine(
        "v1 edge cases",
        ", extern C",
        ", operator overloads",
        ", move semantics",
        ", type aliases",
        ", double and trailing _",
        ", duplicated typedefs",
        ", templates",
        ", static and instance methods",
        ", etc.",
      )

  slide:
    nbText &"## {henka} v2"
    nbText  "### How it works"
    unorderedList:
      listItem(fadeIn):
        nbText "1  - Uses `libclang`'s visitor to walk the AST."
      listItem(fadeIn):
        nbText &"2  - Handle edge cases, mapping {langCpp} AST nodes to {langNim} AST nodes using [`astTF`](https://codeberg.org/heysokam/astTF)."
      listItem(fadeIn):
        nbText &"3  - Pass the {langNim} AST to a [`nim code generator`](https://github.com/MechasNotBrains/nonim)."
      listItem(fadeIn):
        nbText &"This allows {henka} to focus **exclusively** on mapping ASTs, and nothing else."

  slide:
    nbText &"## {henka} v2"
    nbText  "### Workflow"
    unorderedList:
      listItem(fadeIn):
        nbText &"The same principles still apply, but with a much bigger scale (ie: {langC}, {langCpp}, and {langJsTs})."
      listItem(fadeIn):
        nbText &"Test Driven Development is maximum priority. Unit Tests are {henka}'s specification."
      listItem(fadeIn):
        nbText "Tests check for bugs, validate new features, and keep AI in check."

  slide:
    nbText &"## {henka} v2"
    nbText  "### Workflow"
    fragmentFadeIn:
      nbText "About AI usage:"
    unorderedList:
      listItem(fadeIn):
        nbText "We decided when to use AI on the basis of what's faster."
      listItem(fadeIn):
        nbText "A lot of code was generated. But all code was left thorougly tested or strictly reviewed."
      listItem(fadeIn):
        nbText "As it scales, the project becomes a token eating machine."

  autoAnimateSlides(4):
    nbText &"## {henka} v2"
    nbText  "### Workflow"
    showText(@[
      ({1}, ""),
      ({2}, &"1  - Get a well-known {langC}/{langCpp}/{langJsTs} library, generate bindings."),
      ({3},  "2  - Write tests to cover for the new cases and bugs (or generate and review them)."),
      ({4},  "3  - Write the implementation (or generate and review it)."),
      ({5},  "4  - Repeat."),
    ])
    adaptiveColumns:
      column:
        showAt(2..2): nbImage("img/jolt-header.svg")
      column:
        showAt(2..2): nbImage("img/henka-arrow.svg")
      column:
        showAt(2..3): nbImage("img/nim-file-bind.svg")
      column:
        showAt(3..3): nbImage("img/write-arrow.svg")
      column:
        showAt(3..4): nbImage("img/nim-file-test.svg")
      column:
        showAt(4..4): nbImage("img/write-arrow.svg")
      column:
        showAt(4..4): nbImage("img/henka-small.svg")

template wrappingUp =
  slide:
    nbText: "## Conclusions/Future Work"
    unorderedList:
      listItem(fadeIn):
        nbText: "Currently, the LLM's usefulness has started degrading while eating a huge amount of tokens!"
      listItem(fadeIn):
        nbText: "This can probably be fixed by refactoring and writing prompts with more context."
      listItem(fadeIn):
        nbText: &"TODO: add support for more {langC}/{langCpp} features: namespaces, macros, enum bitflags."
      listItem(fadeIn):
        nbText: &"TODO: stabilize {langJsTs} and integrate it into the `main` branch."

  slide:
    nbText: "## Conclusions/Future Work"
    unorderedList:
      listItem(fadeIn):
        nbText: "Again: tests were straightforward to write due to the nature of the project."
      listItem(fadeIn):
        nbText: "AI was prevented from hallucinating thanks to the abundance of tests."
      listItem(fadeIn):
        nbText: "This workflow allowed us to iterate fast enough to get this working in a couple months."

  slide:
    nbText:  "### Ask your questions away"
    nbText: &"### on {langNim}'s Discord!"
    nbText:  "## **@RowDaBoat** / **@heysokam**"
  slide:
    nbImage("img/henka.svg")
    nbText: "# Thank You!"

when isMainModule:
  myInit("index.nim")
  nbRawHtml disableKeys

  slide:
    title
    presentationLink
    whoAreWe

  slide: introduction
  slide: usage
  slide: showcase
  slide: henkav1
  slide: henkav2
  slide: wrappingUp

  nbSave
