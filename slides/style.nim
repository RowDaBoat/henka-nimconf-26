import std / [strutils, strformat]
export strutils, strformat
import nimib, nimislides

const
  colorAgile* = "#02A4BD"
  nimYellow*  = "#FFE953"
  clearStyle* = """<br style="clear: both;">"""

proc color*(c, text: string): string =
  "<span style=\"color: " & c & "\">" & text & "</span>"

proc link*(url, text: string): string =
  &"""<a href="{url}">{text}</a>"""

proc pLeft*(content: string): string =
  &"""<p style="text-align: left">{content}</p>"""

proc pRight*(content: string): string =
  &"""<p style="text-align: right">{content}</p>"""

proc img*(src: string, align = "", width = 200, circle = false): string =
  ## Returns an `<img>` tag. `align` may be "left", "right", or "" (no float).
  ## `width` is in pixels. `circle` crops to a circle (square aspect, cover).
  var style = &"width: {width}px;"
  if circle:
    style.add &" height: {width}px; border-radius: 50%; object-fit: cover;"
  case align
  of "left":  style.add " float: left; margin-right: 20px;"
  of "right": style.add " float: right; margin-left: 20px;"
  else: discard
  &"""<img src="{src}" style="{style}">"""

template addNbTextSmall* =
  nb.partials["nbTextSmall"] = "<small>" & nb.partials["nbText"] & "</small>"
  nb.renderPlans["nbTextSmall"] = nb.renderPlans["nbText"]

template nbTextSmall*(text: string) =
  nbText: text
  nb.blk.command = "nbTextSmall"

template reference*(text: string) =
  nbTextSmall: text

template fragmentFadeInSameLine*(parts: varargs[string]) =
  ## Reveals each `part` inline on successive Down/Space presses,
  ## keeping them on the same line. Uses `fragmentFadeIn` for each
  ## part so they get explicit `data-fragment-index` (correct order),
  ## then `.same-line > .fragment` CSS forces them inline.
  nbRawHtml """<div class="same-line">"""
  for p in parts:
    fragmentFadeIn:
      nbRawHtml p
  nbRawHtml "</div>"

template nimConfTheme*() =
  setSlidesTheme(Black)
  nb.addStyle: """
:root {
  --r-background-color: #181922;
  --r-heading-color: $1;
  --r-link-color: $1;
  --r-selection-color: $1;
  --r-link-color-dark: darken($1 , 15%)
}

.reveal ul, .reveal ol {
  display: block;
  text-align: left;
}

li::marker {
  color: $1;
  content: "»";
}

li {
  padding-left: 12px;
}

.reveal a {
  text-decoration: underline;
}

.same-line > .fragment {
  display: inline;
}
""" % [nimYellow]

template myInit*(sourceFileRel = "my.nim") =
  nbInit(thisFileRel=sourceFileRel, theme=revealTheme)
  nimConfTheme()
  addNbTextSmall
  nbRawHtml """
<style>
.reveal strong {
  color: $1;
  font-style: normal;
}

</style>
""" % [colorAgile]
  nb.partials["nimibCodeAnimate"] = nb.partials["animateCode"]
  nb.renderPlans["nimibCodeAnimate"] = nb.renderPlans["animateCode"]
  # NimibLand logo in bottom-left — uncomment to re-enable.
  # nb.partials["logo"] = """
  # <div id="nimibLandLogo" style="background: url(https://raw.githubusercontent.com/nimib-land/assets/refs/heads/main/nimib_logo_white_cup.svg);
  # background-repeat: no-repeat;
  # background-size: contain;
  # position: absolute;
  # bottom: 10px;
  # left: 10px;
  # width: 128px;
  # height: 128px;"></div>
  # """ # adjust the px as needed
  # nb.partials["document"] = """
  # <!DOCTYPE html>
  # <html>
  #   {{> head}}
  #   <body>
  #   {{> main}}
  #   {{> logo}}
  #   </body>
  # </html>
  # """
