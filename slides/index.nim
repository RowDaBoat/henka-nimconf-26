import nimib, nimislides
import style
import std/strformat

when isMainModule:
  myInit("index.nim")

  slide:
    slide:
      nbText "## Henka, Bind Anything"
      let henka    = color(nimYellow, "henka")
      let langNim  = color(nimYellow, "Nim")
      let langC    = color(nimYellow, "C")
      let langCpp  = color(nimYellow, "C++")
      let langJsTs = color(nimYellow, "JS/TS")
      fragmentFadeIn:
        nbText  &"{henka} is a bindings generator for {langNim}👑"
      fragmentFadeInSameLine(&"supporting {langC}", &", {langCpp}", &" and {langJsTs}")
    slide:
      nbText "## Who are we?"

      let sokam       = color(nimYellow, ".sOkam!")
      let webgpuNim   = link("https://github.com/RowDaBoat/webgpu-nim", "webgpu-nim")
      let nglfw       = link("https://github.com/RowDaBoat/nglfw", "nglfw")

      let row         = color(nimYellow, "Row")
      let reploid     = link("https://github.com/RowDaBoat/reploid", "reploid")
      let shadercNim  = link("https://github.com/RowDaBoat/shaderc-nim", "shaderc-nim")

      fragmentFadeIn:
        nbRawHtml img("img/sokam.png", align = "left", circle = true)
        nbRawHtml pLeft(&"{sokam}, lorem ipsum dolor sit amet,")
        nbRawHtml pLeft("consectetur adipiscing elit.")
      fragmentFadeIn:
        nbRawHtml pLeft(&"Author of {webgpuNim} and {nglfw}.")
      fragmentFadeIn:
        nbRawHtml clearStyle
        nbRawHtml img("img/row.png", align = "right", circle = true)
        nbRawHtml pLeft(&"{row}, gamedev/demoscener,")
        nbRawHtml pLeft(&"fairly new to {langNim}.")
      fragmentFadeIn:
        nbRawHtml pLeft(&"Author of {reploid} and {shadercNim}.")


  ### 変化
  ### Vertical slide 2
  #Press Up to go back, Right to leave the group.
  #"""

  # Sibling top-level `slide:` — navigated to with the Right arrow.
  slide:
    nbText """
## Horizontal slide
A top-level slide alongside the vertical group above.
"""

  nbSave
