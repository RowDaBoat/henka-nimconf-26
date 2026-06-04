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
        # write to a file

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
        nbText &"Jolt Physics {langCpp} bindings, proof of concept."
      listItem(fadeIn):
        nbText &"Nim {langCpp} backend with emscripten."

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


template henkav1 =
  slide:
    nbText "## Henka v1"
    nbText "### Architecture"
    unorderedList:
      listItem(fadeIn):
        nbText "v1 generated Nim bindings for C using"
        nbText "`clang -ast-dump=json`."
      listItem(fadeIn):
        nbText "Initially, we wanted to keep `henka` independent from `libclang` and its API'."
      listItem(fadeIn):
        nbText "Reason 1: easy to parse JSON data."
      listItem(fadeIn):
        nbText "Reason 2: less binary dependencies, easier to port and get working anywhere."

  slide:
    nbText "## Henka v1"
    nbText "### How it worked"
    unorderedList:
      listItem(fadeIn):
        nbText "1  - Walk the AST json data."
      listItem(fadeIn):
        nbText "2  - Handle some edge cases such as unnamed unions/structs, forward declarations, and enum value duplications."
      listItem(fadeIn):
        nbText "3  - Generate Nim code for types, variables, and functions."
      listItem(fadeIn):
        nbText "A basic symbol renamer was provided for customizing the output."

  autoAnimateSlides(6):
    nbText "## Henka v1"
    nbText "### Workflow"
    showText(@[
      ({1}, ""),
      ({2}, "Specs for generating bindings are pretty straightforward to produce from real world use cases. In order to scale the library we just need to use well known C libraries as dogfood."),
      ({3}, "1  - Get a rich C library interface (ie: `webgpu.h`) to generate bindings for it."),
      ({4}, "2  - Use generative AI to fix edge cases on the generator (Claude)."),
      ({5}, "3  - Review, rewrite or discard the code."),
      ({6}, "4  - Repeat."),
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
    nbText "## Henka v2"
    nbText "### Starting over"
    unorderedList:
      listItem(fadeIn):
        nbText "We went back to using `libclang`."
      listItem(fadeIn):
        nbText &"~~Reason 1: easy to parse JSON data.~~ As simple as parsing JSON is, `clang`'s API provides clear enough semantics, and a visitor. Overall less parsing, this was crucial for v2's features, specially {langCpp}."
      listItem(fadeIn):
        nbText "~~Reason 2: less binary dependencies...~~ While still true, this is a 'do once' thing."

  slide:
    nbText "## Henka v2"
    nbText "### New features, more scale"
    unorderedList:
      listItem(fadeIn):
        nbText &"v2 supports {langC}, {langCpp}, and {langJsTs}."
      listItem(fadeIn):
        nbText "Callbacks for working with symbols and pragmas (ie: renaming, overriding, filtering, unnamed symbols)."
      listItem(fadeIn):
        nbText "Can be configured to generate bindings for static or dynamic libraries."
      listItem(fadeIn):
        nbText "Allows more customization on how enums are generated."

  slide:
    nbText "## Henka v2"
    nbText "### New features, more scale"
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
    nbText "## Henka v2"
    nbText "### How it works"
    unorderedList:
      listItem(fadeIn):
        nbText "1  - Uses `libclang`'s visitor to walk the AST."
      listItem(fadeIn):
        nbText &"2  - Handle edge cases, mapping {langCpp} AST nodes to {langNim} AST nodes using [`astTF`](https://codeberg.org/heysokam/astTF)."
      listItem(fadeIn):
        nbText &"3  - Pass the {langNim} AST to a [`nim code generator`](https://github.com/MechasNotBrains/nonim)."
      listItem(fadeIn):
        nbText &"This allows `henka` to **only** focus on mapping ASTs and nothing else."

  slide:
    nbText "## Henka v2"
    nbText "### Workflow"
    unorderedList:
      listItem(fadeIn):
        nbText &"The same principles still apply, but now with {langCpp}'s overblown scale."
      listItem(fadeIn):
        nbText "We added TDD to the workflow, tests are now our specification."
      listItem(fadeIn):
        nbText "Tests check for bugs, validate new features, and keep AI in check."

  slide:
    nbText "## Henka v2"
    nbText "### Workflow"
    fragmentFadeIn:
      nbText "About AI usage:"
    unorderedList:
      listItem(fadeIn):
        nbText "We decided when to use AI on the basis of what's faster."
      listItem(fadeIn):
        nbText "A lot of code was generated, no code was untested/not reviewd."
      listItem(fadeIn):
        nbText "As it scales, the project becomes a token eating machine."

  autoAnimateSlides(4):
    nbText "## Henka v2"
    nbText "### Workflow"
    showText(@[
      ({1}, ""),
      ({2}, &"1  - Get a well known {langC}/{langCpp}/{langJsTs} library, generate bindings."),
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
        nbText: "Currently, LLM's usefulness has started degrading while eating a huge amount of tokens!"
      listItem(fadeIn):
        nbText: "This can probably be fixed by refactoring, and writting prompts with more context."
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
    whoAreWe

  slide: introduction
  slide: usage
  slide: showcase
  slide: henkav1
  slide: henkav2
  slide: wrappingUp

  nbSave
