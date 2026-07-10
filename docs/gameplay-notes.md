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
- **Most other creatures get at most one evolution**, and some get none at all
  -- gated by `CardData.can_evolve`. Deciding factor: whether the animal reads
  as expressive/intelligent enough to plausibly gain personality and gear
  (raccoon, crow, dog = yes; cockroach, opossum, pigeon, sewer rat, sewer
  alligator, bat = no, permanently single-stage by design, not just "no art
  yet"). Keeps the art budget sane while still making starters feel special.
- Evolution mechanics (actually leveling up / choosing a path in-game) aren't
  built yet -- each stage currently exists as its own separate CardData entry
  so the art can be reviewed as a line.
- **Future UX idea (not built)**: the browser currently lists every evolution
  stage as its own card in the grid. Eventually collapse each line down to a
  single card (e.g. just "Black Cat"), with evolutions viewable/selectable
  from within that card's detail view instead of cluttering the main grid.

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

**Roster (built, base/Lv1 art only except the starter)**, organized by where
they live:
- *Street*: raccoon (`can_evolve`, built-in bandit-mask look, own line rather
  than folded into the cat's rogue path -- evolved form would carry a
  stolen-goods bindle), crow (`can_evolve`, night-omen scout), pigeon
  (single-stage, rooftop utility flavor), stray dog (`can_evolve`,
  brawler-flavored parallel line)
- *Sewer*: opossum (single-stage; "plays dead" is a built-in mechanical hook
  for a future defensive/feign-death ability), cockroach (single-stage,
  near-unkillable flavor -> persistence/revive mechanic), sewer rat
  (single-stage, mutated/toxic flavor, distinct from a plain street rat --
  dropped the separate street rat for now, sewer rat covers the "rat" niche),
  sewer alligator (single-stage, urban legend, rare/boss-tier, big scale
  departure -- 30 max_health vs. everything else in the 4-14 range)
- *Night sky*: bat (single-stage, reinforces the night theme, echolocation ->
  future reveal/scout mechanic)
- Decision confirmed: **not** every creature needs a Rogue/Brawler branch --
  just the starter cat. The rest lean into one archetype or the other through
  flavor/stats without a full branching tree each.
- Still not built: actual evolution art for raccoon/crow/dog (flagged
  `can_evolve = true`, waiting on it) and the "street rat" swarm-flavor card
  if we still want it alongside sewer rat.

**Item/action cards (built)** -- deliberately distinct visual layout from
creature cards (no XP bar, no abilities list; a description block instead) to
prove out how non-creature cards read. See `ItemCardData`/`ItemDatabase`.
- **Capture cards**, tiered by HP% threshold, City-Faction-flavored as
  scrap-built traps rather than fantasy capture devices: Alley Snare (25%,
  the version in every starter deck), Weighted Net (50%), Reinforced Cage
  (75%). One use per battle (`ItemCardData.one_use_per_battle`).
- **Healing**: Back-Alley Bandage, restores 8 HP. All creatures now carry a
  `max_health` stat (shown on the card detail view) to give healing/damage
  something to act on once battle systems exist.

## Combat (third version built)

Deck/hand/discard on top of the team battlefield -- Slay the Spire's actual
economy, not just its turn structure. One unified deck (creature cards and
item cards mixed together, per design direction -- not two separate decks),
drawn into a hand each turn. Playing a creature card from hand summons it
onto your field (which now starts *empty* at battle start and grows as you
play cards, rather than a fixed pre-populated team); playing an item card
resolves its effect and goes to discard. The enemy side still has no deck of
its own -- fixed roster already in play, same as Slay the Spire's own
enemies vs. the player's deck.

See `BattleState` (deck/hand/discard + team logic) + `BattleCombatant` (live
per-battle HP/block wrapper around a CardData/ItemCardData) for the rules;
`scenes/battle/battle.gd` + the three tile scenes (`battle_combatant_tile`
for the field, `battle_hand_card_tile` for hand cards) for the presentation
layer.

- **BaseCardData.energy_cost** (new): the cost to *play* a card from hand --
  summon a creature or use an item. Separate from a creature's own in-play
  ability costs (`CardAbility.energy_cost`), spent on a later turn once
  already summoned. Same energy pool pays for both.
- **Hand size 5**, Slay the Spire's convention: unplayed hand cards discard
  at end of turn (don't carry over), a fresh hand is drawn at the start of
  the next one. When the draw pile empties mid-draw, the discard pile
  shuffles back into it automatically.
- **Healing wired up**: playing Back-Alley Bandage on one of your own
  creatures restores HP, capped at its max.
- **Capture wired up**: playing a capture card on an enemy at or below its
  HP% threshold removes that enemy from the fight (same "leaves play"
  mechanic as a normal defeat) and logs a capture message; below the
  threshold, the card is still consumed but the attempt just fails. Not yet
  connected to any persistent collection outside battle -- captured
  creatures don't currently go anywhere afterward.
- **Creatures/enemies leave play when defeated**: BattleState never removes
  a dead combatant from its own team arrays (targeting/turn logic already
  skips them via `is_alive()`), but battle.gd removes that combatant's field
  tile the moment it dies, so the row visually shrinks instead of just
  graying the card out. A defeated creature's card returns to the discard
  pile at that point (modeling "the card comes back to you, just battered").
- **Test deck**: 4 creature cards (2x Alley Kitten, Raccoon, Crow) + 4 item
  cards (Alley Snare, Weighted Net, 2x Back-Alley Bandage) vs. the same
  enemy roster as before (Sewer Rat/Cockroach/Opossum).
- Verified computationally: initial draw size, summoning correctly costs
  energy and does *not* discard the card, a defeated summon's card *does*
  land in discard, healing heals and consumes the item, capture at low HP
  succeeds and removes the target, end-of-turn correctly discards the
  leftover hand and draws a fresh one -- and the reshuffle-on-empty path
  fired naturally as a side effect of the same test run.
- **Entry point unchanged**: the "⚔ Battle Test" button in the card
  browser's top bar. Still no real "build your deck" flow -- the deck
  composition above is hardcoded in battle.gd.

## Open questions / not yet decided

- How many starter creatures eventually, and how they're chosen (currently
  just the City Faction black cat).
- Per-creature ability kits (right now every card shares the same generic
  Strike/Guard pair -- no differentiation between a Rogue and a Brawler in
  actual combat yet, even though the art and flavor clearly diverge).
- A real deck-building flow (currently a hardcoded test deck in battle.gd,
  not tied to an actual collection/deckbuilding screen).
- Captured creatures don't go anywhere yet -- no persistent player
  collection outside of a single battle for them to join.
- Actual evolution *mechanic* (leveling up / choosing a path in real gameplay,
  vs. today's separate-CardData-per-stage placeholder approach).
- Enemy turn has no pacing/animation -- resolves instantly, which may feel
  abrupt with a multi-creature team all acting in the same instant.
- No summoning sickness -- a creature can act the same turn it's summoned,
  if energy allows. Simple by design for now, worth revisiting for balance.
