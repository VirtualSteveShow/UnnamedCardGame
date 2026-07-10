# Unnamed Card Game — To-Do / Known Issues

Project-specific task list. For gameplay ideas/premise, see `gameplay-notes.md`.

## Resolved issues

### ✅ Card browser scroll felt sketchy/slow/choppy on-device (S23 Ultra)

Root cause: cards measured drag distance using `event.position`, which
is local to the card itself. The card's on-screen position shifts every
time the list scrolls (it's a grid child), so its local coordinate
frame moved as a direct result of the very scrolling being driven from
these events -- each frame's scroll correction fed back into the next
frame's delta calculation, corrupting it. Three earlier fixes (dropping
`Button`, accumulating the rounding remainder, batching to one
`scroll_vertical` write per frame) all addressed real but secondary
issues and had zero effect on the actual feel, because none of them
touched the feedback loop. Switched to `event.global_position`
(viewport space, doesn't move just because the card did) -- confirmed
fixed on-device 2026-07-10.

## Feature backlog

- Card art: replace placeholder colored rectangles with real Flux-generated art.
- Meal Planner-style TCG card frame system (deferred until real art exists).
- Gameplay systems beyond the card browser (see `gameplay-notes.md` build order).
