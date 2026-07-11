# Unnamed Card Game — Design Notes

Living document for gameplay ideas as we brainstorm. Subject to change.
Narrative/worldbuilding lives separately in `lore.md`.

## Premise (current, subject to change)

Slay the Spire structure/loop, with Pokémon-style creature collecting layered in.
Roguelike run target: **1-2 hours or less per run**, similar to Slay the Spire --
this is the constraint the run-structure decision below has to fit inside.

- **Starter Creature**: pick a starter similar to picking a class in Slay the Spire.
  Only City Faction's starter exists so far; Suburbs is gaining a (much lighter)
  starter of its own, so "only one starter" may not hold long-term -- see the
  Suburbs section below.
- **Creature cards have visible XP bars.** Leveling up makes a creature stronger.
  The *first* level-up presents a choice of evolution path (branching evolutions,
  not a single fixed line).
- **Abilities cost energy.** Each creature ability has a specific energy cost to use.
- **Capturing**: creatures can be captured via a specific item/card type, which adds
  the captured creature to the player's deck. See `lore.md` for why this exists
  in-universe (cards are a storage/command technology, not just a game abstraction).

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

## Faction: Suburbs (second faction, built)

Bright sunny daytime aesthetic -- the calm counterpart to City's grit, and
deliberately the game's tutorial location: basic creatures, mostly
one-ability, gentle difficulty ramp. See `docs/lore.md` for how this fits
into the wider location brainstorm and the ~4-6 faction scope call.

**Starter**: House Cat (Lv1) -> Watchcat (Lv2, red bandana, fence-post pose,
reads as more confident/alert). One evolution, not a branching pair like
City's starter -- deliberately lighter, just enough to show the evolution
mechanic off without a big art investment. `xp_progress` values (0.1 -> 1.0)
match City's starter pacing.

**Roster (built, single-stage except the starter)**: Family Dog (12 HP,
loyal/sturdy flavor), Squirrel (5 HP, quick/erratic), Rabbit (6 HP), Robin (4
HP, garden bird counterpart to City's crow), Hamster (4 HP, smallest in the
roster, pet-cage flavor).

**`simple_abilities` flag (new)**: a `CardDatabase.REAL_CREATURES` entry
key that, when true, gives that creature only a Strike ability and no Guard.
Every Suburbs creature sets it. This reinforces "basic, one-ability" in data,
not just flavor text/art style -- a Suburbs card is mechanically simpler to
play, not just visually calmer. Verified computationally: House Cat has
exactly 1 ability where a City creature (e.g. Raccoon) has 2, and
`get_all_cards()` returns 21 total (14 City + 7 Suburbs).

**Item cards (built)**: Cat Carrier (capture, 25% HP threshold, comes in
every Suburbs starter deck -- same tier/role as City's Alley Snare) and
Band-Aid (healing, 8 HP -- same amount as City's Back-Alley Bandage).
Tutorial-only for now: just one capture tier and one healing card, no
progression tiers like City's Weighted Net/Reinforced Cage, matching
Suburbs' "basic" identity. Only used by the Suburbs Battle Test matchup.

**Art learnings**: the first art pass (bright/cheerful variant of City's
style prompt) came back visibly too soft/cartoonish compared to City's
grittier pixel work -- more "mobile game mascot icon" than "16-bit game
asset." Regenerated 2026-07-11 with the rendering-fidelity wording tightened
(explicit "not chibi, not kawaii, not a cute mascot," "detailed
pixel-dithered shading," "no soft gradients," "clear hard directional
sunlight with defined shadows") while keeping the daytime setting -- pulled
the *texture/rendering* back toward City's fidelity. Some residual
cuteness is just inherent to the content (a rabbit's big eyes, a hamster in
a cage) rather than a rendering problem; flagged for the user to confirm
whether another pass is needed. Item card art reused City's proven
close-up-hero-shot item template (blurred bokeh background, centered
object, thick outline) with the same daytime-palette swap. Same explicit
"no anthropomorphic humanoid pose" guard clause carried over from the City
starter's brawler-pose lesson -- no new pose problems hit this time.

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
- **Test deck**: 4 creature cards (2x House Cat, Family Dog, Squirrel) + 3
  item cards (Cat Carrier, 2x Band-Aid, Suburbs' own tutorial-only items)
  vs. a Suburbs enemy roster (Rabbit/Robin/Hamster) -- swapped from the
  original City matchup (Alley Kitten/Raccoon/Crow vs.
  Sewer Rat/Cockroach/Opossum) once the Suburbs roster existed, to actually
  exercise the new faction.
- Verified computationally: initial draw size, summoning correctly costs
  energy and does *not* discard the card, a defeated summon's card *does*
  land in discard, healing heals and consumes the item, capture at low HP
  succeeds and removes the target, end-of-turn correctly discards the
  leftover hand and draws a fresh one -- and the reshuffle-on-empty path
  fired naturally as a side effect of the same test run.
- **Entry point unchanged**: the "⚔ Battle Test" button in the card
  browser's top bar. Still no real "build your deck" flow -- the deck
  composition above is hardcoded in battle.gd.
- **Deck + discard piles (built 2026-07-11, revised 2026-07-11)**: a shared
  `pile_button.tscn` component (generalized from an earlier draw-pile-only
  version) renders both the draw pile and a new discard pile as clickable
  stacked-card widgets side by side beside the hand row. Tapping either
  opens a full-screen overlay (`PileViewOverlay`, reused for both) listing
  every card currently in that pile (read-only `battle_hand_card_tile`
  instances, sorted alphabetically, in a scrolling grid). An empty pile
  (the discard pile at battle start, or in principle the draw pile at the
  instant it's fully depleted) drops the stacked-card look and count number
  for a flat bordered outline instead, so "empty" reads clearly rather than
  showing a stack of zero. No card-back art yet -- placeholder stack look,
  swap in real art on the pile button's `FrontPanel` once it exists. Both
  piles are always sized to match the hand's *resting* (unfocused) card
  size/aspect ratio, never the enlarged focused size -- they're fixed
  furniture on the table, not part of the hand itself. `PileCountsLabel`
  (the old "Discard: N · Hand: N" text) was removed entirely now that the
  discard pile shows its own count and the hand's size is visible directly.
- **Hand focus/collapse (built 2026-07-11, fixed same day)**: the hand
  rests small and non-interactive along the bottom of the screen until
  tapped; tapping it (`HandFocusCatcher`, a transparent button layered on
  top of the hand while unfocused) expands its cards to full size and
  playability, and dims the rest of the board behind them (`HandScrim`).
  Tapping the scrim collapses it back.
  **Bug found on first phone test**: the first version grew `HandRow`'s
  own rect (`anchor_top`) between a small and large band, but the small
  band's top (0.525) sat *above* `PlayerRow`'s bottom (0.62) -- a real
  overlap, not just a sizing complaint -- and "unfocused" cards were sized
  by filling that band to max rather than actually being small, so the
  resting hand rendered nearly full-size and visibly covered/obscured the
  player's creature row. Caught via an on-device screenshot (both my own
  ADB screencap and ones the user sent) showing a half-hidden creature
  tile poking out from behind the hand.
  **Fix**: `HandRow`'s rect is now fixed at all times (the same band it
  always occupied, safely below `PlayerRow`) -- only card size and
  interactivity change with focus, never the rect itself. Unfocused cards
  use a small fixed size (`HAND_SMALL_HEIGHT_FRACTION` of viewport height,
  not a fill-to-max fit), so they stay genuinely small regardless of how
  much room is technically available; focused cards still use the normal
  fill-to-max fit (`_resize_row`) against that same fixed rect. This also
  eliminated the whole *class* of overlap risk, not just this instance,
  since HandRow can no longer grow into space another row already owns.
  The deck/discard piles and hand-card-name font size were also tuned to
  match (names were clipping at the new small card size -- shrunk the
  font and enabled wrapping).
- **Creature tile size consistency (fixed 2026-07-11)**: enemy and player
  creature tiles used to size independently per row (`_resize_row` called
  separately on each), so they visibly mismatched whenever the two rows'
  rect heights or creature counts differed -- which they usually do, since
  the enemy roster is fixed at battle start while the player's field starts
  empty and grows. `_resize_creature_rows()` now computes a candidate size
  for each row and applies the smaller of the two to *both*, so every
  creature on the board is the same size regardless of which side it's on.
- **Draw animation (built 2026-07-11)**: `BattleState` gained a
  `cards_drawn` signal that fires with just the newly drawn cards (not the
  whole hand) after any draw -- the opening hand and every subsequent
  turn's refill both go through the same `_draw_hand()` path, so one signal
  covers both. Required splitting the initial draw out of `BattleState`'s
  constructor into an explicit `start_battle()` call: the constructor used
  to draw immediately, which fired the signal before battle.gd had a chance
  to connect to it. On the UI side, newly drawn hand tiles start invisible
  and a throwaway "ghost" copy flies from the deck pile's on-screen
  position to the tile's real (already laid-out) position, growing from
  deck-sized to full hand-card size; multiple cards (e.g. the 5-card
  opening hand) stagger by 0.1s each so they read as being dealt one at a
  time. The ghost animates, never the real tile, so it can't desync from
  whatever the hand row's container decides the actual layout is.
- **Health bars restyled (built 2026-07-11)**: the HP `ProgressBar` on
  each battlefield tile now uses a custom rounded/bordered background plus
  a fill color that switches green (>60% HP) / yellow (25-60%) / red
  (<25%) instead of the flat default ProgressBar look, so HP state reads at
  a glance during a fight.
- **Left/right battlefield + dedicated battle sprites (built 2026-07-11)**:
  player creatures now occupy a column on the left (`PlayerRow`, a
  `VBoxContainer`), enemy creatures a column on the right (`EnemyRow`,
  same), instead of two horizontal rows stacked top/bottom. `_fit_tile_size`
  gained a `vertical_stack` parameter so the same "fit N tiles into the
  available space" math works for a column, not just a row --
  `_resize_creature_rows()` passes `vertical_stack=true` for both sides so
  they still match in size.
  Creatures also get a dedicated battle sprite (`CardData.battle_texture`,
  falls back to the card art via `get_battle_texture()` if unset) instead
  of reusing the card-portrait art on the battlefield -- a full-body side
  profile pose facing right, distinct from the card's portrait framing.
  Enemy tiles flip the same sprite horizontally (`TextureRect.flip_h`) to
  face the player side rather than needing separate left/right-facing art.
  Scoped to just the 6 creatures the Suburbs Battle Test actually uses
  (House Cat, Family Dog, Squirrel, Rabbit, Robin, Hamster) to prove the
  pipeline/layout before committing to art for the full 21-creature roster;
  everything else still falls back to card art on the battlefield.
  **Two real bugs found and fixed during this pass, both from phone
  screenshots**: (1) the battlefield tile's art `TextureRect` used
  `stretch_mode = 6` (`STRETCH_KEEP_ASPECT_COVERED`), which crops to fill
  the frame -- fine for card art already composed to fill a portrait
  frame, but it zoomed absurdly far into the new landscape-composed battle
  sprites, showing only a cropped fur patch instead of the whole creature.
  Changed to `stretch_mode = 5` (`STRETCH_KEEP_ASPECT_CENTERED`), which
  letterboxes instead of cropping. (2) The first battle-sprite batch was
  generated with painted sky/grass backgrounds (matching the card art
  style), which combined with the crop bug to look especially broken, and
  wasn't what was wanted anyway -- regenerated on flat white backgrounds
  and ran each through the existing rembg background-removal pipeline
  (`/bgremove` on the ComfyUI Phone App, already used elsewhere in this
  project) to get real transparent PNGs, confirmed via direct alpha-channel
  inspection (not just visual check) before wiring them in.
- **Third real bug, found the same way (fixed 2026-07-11)**: even after
  the crop/transparency fixes, creature tiles still rendered enormous --
  a `Container` (here, `PlayerRow`/`EnemyRow` as `VBoxContainer`s) gives
  each child its own minimum size along the stacking axis, but by default
  stretches every child to fill the full *cross*-axis size regardless of
  that child's `custom_minimum_size` -- for a vertical column, the cross
  axis is width, so tiles were stretching out to the column's full width
  (the whole left or right half of the screen) no matter what
  `_fit_tile_size` computed. Fixed by setting `size_flags_horizontal` and
  `size_flags_vertical` to `SIZE_SHRINK_CENTER` on every dynamically
  created tile (`_lock_tile_size()`, called for creature tiles, hand
  tiles, pile-view tiles, and the deck/discard pile buttons) so
  `custom_minimum_size` is authoritative on both axes instead of just
  being a floor the container could stretch past. Verified computationally
  (not just visually) by comparing `tile.size` to `tile.custom_minimum_size`
  after layout settles -- they now match exactly.
- **Card detail battle-sprite comparison (built 2026-07-11)**: the card
  browser's detail overlay (`card_detail.tscn`/`.gd`) now shows a small
  inset of the creature's battle sprite next to its card art, when it has
  one (`CardData.battle_texture`), specifically so a style mismatch
  between the two is obvious while browsing instead of only showing up
  once the creature hits the battlefield. Hidden entirely for the vast
  majority of the roster that doesn't have a battle sprite yet.

## Run structure (discussed, not yet decided/built)

Two options on the table for how a run is actually navigated:

1. **Slay the Spire-style branching path** -- a node-graph map (fights,
   events, shops, elites, boss) traversed per act, with player choice at
   each branch. Well-understood pattern, fast to build, and its pacing is
   *exactly* what "1-2 hours per run" is optimized for -- that's literally
   what Slay the Spire's structure is built to do.
2. **Pokémon-style explorable overworld** -- free movement, wander into
   encounters, non-linear discovery. A dramatically bigger build (level
   design, movement/collision, camera, possibly NPCs/quests -- an order of
   magnitude more production than anything built so far combined), and in
   tension with the 1-2 hour run target: Pokémon-style exploration is
   paced for 20-40+ hour completion, not a repeatable short run, so
   reconciling the two would itself be a real design problem, not just an
   engineering one.

**Recommendation: branching path (option 1) as the primary structure.**
The "own flair" doesn't have to come from the map shape -- it can come
from tying map *nodes* directly to the location/faction system (each node
is literally a place: a City node, a Suburbs node, etc., making the path
feel like a road trip across biomes rather than an abstract StS map), plus
the creature-collecting layer itself (deck of captured creatures,
evolution, capture-in-battle) is already a big enough differentiator from
Slay the Spire on its own. A lighter middle ground exists too, for later:
small hand-crafted or procedural explorable *rooms* per node (closer to
Hades/Enter the Gungeon than a full overworld) layered on top of the
branching structure once it exists, without committing to a full overworld
now.

This also gives the Suburbs-as-tutorial idea a clean home: if the map is
faction-node-based, Suburbs can simply *be* the first node cluster every
run passes through, without needing a separate "choose your starter"
system to introduce it.

Not built, not locked in -- flagging here so it doesn't get lost.

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
