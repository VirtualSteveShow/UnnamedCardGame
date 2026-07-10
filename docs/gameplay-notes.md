# Unnamed Card Game — Design Notes

Living document for gameplay ideas as we brainstorm. Subject to change.

## Premise (current, subject to change)

Slay the Spire structure/loop, with Pokémon-style creature collecting layered in.

- **Starter Creature**: pick a starter similar to picking a class in Slay the Spire.
  Only one starter will exist for the initial build.
- **Creature cards have visible XP bars.** Leveling up makes a creature stronger.
  The *first* level-up presents a choice of evolution path (branching evolutions,
  not a single fixed line).
- **Abilities cost energy.** Each creature ability has a specific energy cost to use.
- **Capturing**: creatures can be captured via a specific item/card type, which adds
  the captured creature to the player's deck.

## Technical requirements

- Runs on **mobile and PC** — touch input on mobile, mouse on PC.
- **Forced landscape** orientation on mobile.
- Must support all standard aspect ratios: 16:9, 16:10, tall phone screens
  (e.g. Samsung S23 Ultra full-screen), etc.
- All code is written by Claude Code, so it must be **well commented**.
- A **version number is always visible in-game** so it's easy to tell whether
  you're on the latest build.

## Build order

1. **Card browser** — build this first. Lets us iterate on card look/feel and
   view/select cards in detail before any gameplay systems exist.
2. (TBD — everything after this comes from ongoing brainstorming)

## Open questions / not yet decided

- How many starter creatures eventually, and how they're chosen.
- Full evolution tree shape (how many branches, how many stages).
- Energy system details (regen rate, max energy, per-turn vs per-encounter).
- Capture item rules (success rate? one-time use? tied to creature HP/state?).
