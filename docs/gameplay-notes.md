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
2. Art pipeline proven end-to-end (ComfyUI Phone App -> art/wip -> game/assets ->
   CardData/CardDatabase). See `art-pipeline.md` for the reusable how-to.
3. First faction (City Faction) art in progress -- see below.
4. (TBD — everything after this comes from ongoing brainstorming)

## Evolution structure

- **Starters get a full 3-stage arc**: base (no gear, untrained) -> in training
  (partial gear, learning their path) -> expert (full gear, path fully realized).
  The first level-up is a *branch point* -- the player picks which path to train
  toward, not a fixed single line.
- **Most other creatures get at most one evolution**, and some get none at all.
  Keeps the art budget sane while still making starters feel special.
- Evolution mechanics (actually leveling up / choosing a path in-game) aren't
  built yet -- each stage currently exists as its own separate CardData entry
  so the art can be reviewed as a line.

## Faction: City Faction (first faction, in progress)

Gritty urban night aesthetic — deep shadows, streetlight/neon glow, wet
pavement, chain-link fences, dumpsters, graffiti. Deliberately darker/grittier
than the original art-pipeline style test (which was removed once this
replaced it as the real first faction).

**Starter**: stray black cat, two evolution paths —
- **Rogue** (stealth/evasion/single-target): Alley Kitten (Lv1) -> Cutpurse Cat
  (Lv2, bandana mask, shiv, unsure posture) -> Backalley Blade (Lv3, full hood
  + domino mask, confident, fire escape/rooftop vibe)
- **Brawler** (tanky/close-range/intimidation): Alley Kitten (Lv1) -> Junkyard
  Scrapper (Lv2, plain collar, one bandaged paw, still lean) -> Alley Boss (Lv3,
  spiked collar, scarred, both paws bandaged, standoff pose)
- Learned the hard way: describing a "muscular" cat as "standing defiantly"
  pushes Flux toward an upright bipedal/humanoid pose. Explicit "on all fours" /
  "quadruped stance" wording is needed to keep it reading as an actual animal.
  A vest draped over an upright torso doesn't work anatomically on a quadruped
  either — bandaged paws work much better as the "brawler" tell.

**Roster brainstorm (not yet built)**, organized by where they live:
- *Street*: rat (swarm/numbers flavor), raccoon (built-in bandit-mask look,
  own line rather than folded into the cat's rogue path — evolved form carries
  a stolen-goods bindle), pigeon (scruffy -> rooftop lookout/scout), crow/raven
  (night-omen scout, moodier than the pigeon), stray dog (brawler-flavored
  rival line)
- *Sewer*: opossum ("plays dead" is a built-in mechanical hook — defensive/
  feign-death ability), cockroach (near-unkillable flavor, persistence/revive),
  sewer rat (bigger/mutated, poison flavor, distinct from the street rat),
  sewer alligator (urban legend, rare/boss-tier, big scale departure)
- *Night sky*: bat (reinforces the night theme, echolocation -> reveal/scout
  mechanic)
- Decision: **not** every creature needs a Rogue/Brawler branch — just the
  starter cat (and maybe the dog as a Brawler-flavored parallel line). Let
  the rest of the roster lean into one archetype or the other through flavor/
  stats without a full branching tree each.

**Item/action card ideas** (to test non-creature card layout, not yet built):
Switchblade (crit/attack item), Trash Lid Shield (defense item), Smoke Bomb
(evasion action), Nine Lives (cat-flavored cheat-death action).

## Open questions / not yet decided

- How many starter creatures eventually, and how they're chosen (currently
  just the City Faction black cat).
- Energy system details (regen rate, max energy, per-turn vs per-encounter).
- Capture item rules (success rate? one-time use? tied to creature HP/state?).
- Actual evolution *mechanic* (leveling up / choosing a path in real gameplay,
  vs. today's separate-CardData-per-stage placeholder approach).
