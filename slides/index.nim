import nimib, nimislides
import our

when isMainModule:
  myInit("index.nim")

  # Vertical slide group: nested `slide:` blocks become vertical
  # sub-slides (navigate with Down/Up arrows).
  slide:
    slide:
      nbText """
## Vertical slide 1
Press the Down arrow to reveal the next vertical slide.
"""
    slide:
      nbText """
## Vertical slide 2
Press Up to go back, Right to leave the group.
"""

  # Sibling top-level `slide:` — navigated to with the Right arrow.
  slide:
    nbText """
## Horizontal slide
A top-level slide alongside the vertical group above.
"""

  nbSave
