# slides

Slides built with [nimib](https://github.com/pietroppeter/nimib) and
[nimislides](https://github.com/HugoGranstrom/nimiSlides).

## Setup

Install the dependencies (once):

```sh
nimble install nimib nimislides
```

## Build

From this directory:

```sh
nim r index.nim
```

This compiles and runs `index.nim`, which writes `index.html` next to it.
Open `index.html` in a browser to view the deck.

To rebuild after changes, just re-run the same command.

## Style

The look-and-feel lives in `our.nim`:

- `nimConfTheme` — colors, list bullets, link/heading color overrides.
- `myInit` — calls `nbInit` with the reveal theme, applies the theme,
  registers the `nbTextSmall` partial and the `nimibLandLogo` partial.

Call `myInit("yourFile.nim")` at the top of any new slide entry point to
inherit the style.
