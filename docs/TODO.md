# Unnamed Card Game — To-Do / Known Issues

Project-specific task list. For gameplay ideas/premise, see `gameplay-notes.md`.

## Known issues

### 🔴 Card browser scroll still feels bad on-device (S23 Ultra)

Dragging over a card to scroll the grid still feels sketchy/slow, despite
three fix attempts against different theories:

1. Cards were `Button` nodes -- `BaseButton` consumes the input on press,
   so a drag starting on a card never reached the `ScrollContainer` at
   all. Switched cards to a plain `Control`.
2. Assumed the drag would then bubble up to `ScrollContainer`'s own
   native touch-scroll handling. It didn't (still broken) -- so cards
   now track press/drag/release themselves and forward the delta to
   `card_browser.gd`, which applies it to `scroll_vertical` directly.
   This got scrolling *working* but it felt very slow.
3. Root-caused the slowness to `roundi()` being applied per raw input
   event -- touch delivers many sub-pixel deltas, and rounding each one
   individually discards nearly all of them. Switched to accumulating
   the fractional remainder instead. Still felt slow, and now also
   choppy/flickering.
4. Root-caused the choppiness to writing `scroll_vertical` once per raw
   input event -- touch can deliver many motion samples between
   rendered frames, and each write forces `GridContainer` to re-layout
   all 36 cards. Batched pending drag motion into a single
   `_process()`-driven update per frame instead.

After all four, user report: "feels exactly the same." None of the
above fixes changed the felt experience at all, which suggests the
actual cause is something none of these theories cover -- possibly:

- The manual drag-forward approach is fundamentally the wrong shape
  (e.g. `_gui_input` on the card might not be firing at the rate
  assumed, or `event.position` deltas may not mean what's assumed
  under the `canvas_items`/`expand` stretch transform).
- Something about the "Compatibility" (GL Compatibility) renderer on
  this specific device.
- The card grid's dynamic resizing (`custom_minimum_size` set on 36
  items) interacting badly with `ScrollContainer` in some way not yet
  identified.
- Needs actual profiling on-device (Godot's remote debugger / frame
  profiler over the same ADB connection) rather than further
  theory-then-guess iteration.

**Next step:** stop guessing blind; attach the Godot debugger to the
running device build and actually observe input events / frame timing
before changing code again.

## Feature backlog

- Card art: replace placeholder colored rectangles with real Flux-generated art.
- Meal Planner-style TCG card frame system (deferred until real art exists).
- Gameplay systems beyond the card browser (see `gameplay-notes.md` build order).
