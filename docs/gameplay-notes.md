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
- **Battle sprites regenerated via img2img (2026-07-11)**: the first batch
  (independent txt2img per creature) looked visibly inconsistent with the
  card art -- same creature, different proportions/shading. Regenerated
  using `/imgedit` (Flux ReferenceLatent) with each creature's *existing
  card art as the reference image* instead, which keeps coloring/markings
  consistent since the model edits the same source rather than
  reinterpreting a text description from scratch. Full writeup of the
  prompt pattern and a bird-specific humanoid-drift incident (Robin's
  reference + "battle-ready stance" produced a muscular armored
  bird-headed warrior, not just a style problem) in `docs/art-pipeline.md`.

## Experimental Mode: hand-based combat (prototype, built 2026-07-12)

A second, deliberately separate combat prototype, built to test a
fundamentally different idea without touching the original battlefield
combat (`scenes/battle/`, `BattleState`) at all -- that system stays fully
intact and reachable exactly as before via the "⚔ Battle Test" button.
This one lives entirely under `scenes/battle_v2/` and
`scripts/battle_v2/`, reached via a new "🐾 Deck Battle (Prototype)"
button on the card browser, and reuses only genuinely generic sub-scenes
from the original (`pile_button`, `battle_combatant_tile`,
`battle_hand_card_tile`) -- nothing battle-rules-specific is shared.

**Core idea**: captured creatures don't have HP and never get summoned
onto a persistent battlefield. Playing a creature card from hand discards
it immediately and releases one new card per ability it has straight into
your hand (`AbilityCardData` -- not drawn from the deck, created fresh).
Playing one of those ability cards shows the source creature's battle
sprite popping out and performing the move (a short animation, purely
cosmetic), resolves its effect, then discards -- the same single-use
lifecycle an item card already has. There's no more "select a creature,
then pick its ability" step: every playable card is just tapped directly,
optionally followed by an enemy tap to target a damaging effect. This
reads much closer to actual Slay the Spire than the original prototype's
Pokémon-style persistent battlefield does.

**Design decisions locked in before building** (see chat for the full
options considered):
- A played monster card is discarded immediately -- it doesn't stick
  around to be replayed, matching how item cards already work.
- One ability card is generated per ability the creature has (so a
  `simple_abilities` Suburbs creature like House Cat, with just Strike,
  releases 1 card; a City creature with Strike+Guard would release 2).
  Reuses each creature's existing `CardAbility` data directly.
- Enemies are unchanged from the original prototype: same fixed
  HP-based roster (`BattleCombatant`, reused as-is), same turn structure
  -- only their target changed, from a player creature to the player's
  own HP pool.

**What's different from `BattleState`, concretely**:
- The player has `player_hp`/`player_max_hp`/`player_block` instead of a
  `player_team` of creatures. Enemies attack that pool directly
  (`_damage_player()`, block-then-HP order same as `BattleCombatant.take_damage`).
- Healing item cards now apply directly to the player (no target needed)
  since there's no player creature to choose between anymore -- tapping
  a healing card resolves it immediately. Capture item cards are
  unchanged (still target an enemy, which still has HP).
- New `BattleStateV2.ability_played` signal fires right when an ability
  card resolves (before the damage/log update), specifically so the UI
  can play the sprite-pop animation without it needing to gate or delay
  the actual rule resolution -- the animation coroutine runs independently.
- `PlayerPanel` (`scenes/battle_v2/player_panel.tscn`/`.gd`) replaces the
  player creature column with a simple HP/block display -- duplicates
  `battle_combatant_tile`'s HP-bar color-by-percentage styling logic
  rather than sharing it, since refactoring that tile to serve both
  scenes risked touching the original system.
- Same test roster/deck as the original Battle Test
  (House Cat/Family Dog/Squirrel vs. Rabbit/Robin/Hamster), but the
  player deck is intentionally smaller (4 creature cards instead of
  needing more) since every creature card now generates extra cards on
  top of itself -- a full deck would flood the hand.

**Verified**: headless editor import (both new script classes registered
as global classes cleanly), all three scenes (card browser, original
Battle Test, new Deck Battle) play-tested headless with zero errors, and
a temporary script exercised the full loop programmatically -- playing a
monster card correctly nets the hand back to the same size (discard one,
gain one ability card), the generated ability card deals damage to the
targeted enemy, a healing item card heals the player directly, and ending
the turn correctly damages the player's HP pool instead of a creature.

**First on-device pass, two fixes (2026-07-12)**:
- **Player sprite**: `PlayerPanel` was text-only ("YOU" + HP bar), no
  actual character. Generated a generic pixel-art trainer sprite (young
  character holding a hand of cards, side profile facing right, same
  style/pipeline as the creature battle sprites -- txt2img on a flat
  white background, then `/bgremove` for real transparency) and added it
  to the panel. Lives at `game/assets/player/player_battle_sprite.png`,
  not tied to any faction since the player isn't faction-specific.
- **Free first ability per creature**: on-device testing surfaced a real
  economy problem -- the hand discards at end of turn (intentional, Slay
  the Spire convention), and playing a creature card already costs
  energy just to release its ability cards into hand. If the abilities
  themselves also cost energy, a creature played without enough energy
  left over would release cards you couldn't afford before they got
  discarded unused. Fixed by making the *first* ability card generated
  by `play_creature_card()` always cost 0 energy, regardless of what
  `CardAbility.energy_cost` says on the source data -- guarantees every
  played creature nets at least one usable move the same turn. Overridden
  in `BattleStateV2` itself (not `CardDatabase`'s shared ability data) so
  it's scoped to this mode's economy only; the original battlefield
  combat's repeat-use-across-turns economy doesn't have the same problem
  and wasn't touched.

**Temporary field presence (built 2026-07-12)**: a played creature now
gets a non-HP visual presence on the field (`field_monsters` on
`BattleStateV2`, a new `PlayerFieldRow` column below `PlayerPanel` in the
UI) instead of just flashing into existence for each ability play and
otherwise being invisible. A creature stays on the field for as long as
at least one of the ability cards it released is still somewhere in
`player_hand` -- checked by scanning hand contents
(`_prune_fled_monsters()`), not a manually-decremented counter, so it
correctly covers both ways a card can leave hand: being played, or being
discarded unplayed at end of turn. The moment none are left, the creature
"flees" -- `creature_left_field` fires and the UI fades/slides the tile
out. `_on_ability_played`'s "pops out and attacks" animation now starts
from the creature's field tile when it has one, instead of always from
the player panel, so the flourish reads as "the fielded monster attacks"
rather than "a card generically pops out." New scene:
`scenes/battle_v2/field_monster_tile.tscn`/`.gd` -- deliberately simpler
than `battle_combatant_tile` (no HP bar, no tap interaction, since field
monsters have neither) rather than repurposing that tile.

Verified computationally: playing a creature adds it to `field_monsters`
and fires `creature_entered_field`; for a 2-ability creature (Raccoon),
playing only one of its two ability cards leaves it on the field, and
playing the second causes it to flee; a 1-ability creature (House Cat)
flees immediately after its single ability is played.

**Slay the Spire visual/interaction pass (2026-07-12)**: user provided a
side-by-side reference screenshot and asked Deck Battle to match Slay the
Spire's actual UI as closely as reasonably possible. Went through the
reference element by element; skipped gold/potion-slots/floor-counter
(the meta UI in Slay the Spire's top bar) since those need systems that
don't exist yet -- user confirmed an equivalent (a backpack/items system,
and definitely a currency) is wanted eventually, just not now, so this is
flagged as a real future to-do rather than dropped. Everything else was
buildable as pure UI/interaction work:

- **New battle_v2-only tile scenes**, not restyles of the shared ones --
  `hand_card_tile_v2` (StS-style card: rounded rect, border color-coded by
  inferred type -- red Attack for damage>0 ability cards, blue Skill for
  block-only, green Monster for creature cards, gold Item for item cards
  -- plus a circular cost badge) and `enemy_tile_v2` (sprite with a slim
  *always-red* HP bar directly underneath, no boxed name/HP panel --
  Slay the Spire's HP bars are always red for both sides, not
  color-by-percentage the way this project's other tiles are).
  `PlayerPanel` restyled the same way: no more boxed background/"YOU"
  label, just the sprite with a slim red bar under its feet. Same
  rationale as `field_monster_tile` earlier -- keeps the original Battle
  Test's look completely untouched rather than repurposing shared scenes.
- **Fanned hand** (`_layout_hand()` in battle_v2.gd): `HandRow` stopped
  being an `HBoxContainer` -- hand cards are now manually positioned
  Controls in a plain `HandArea`, each given a rotation and a slight
  upward arc lift that both scale with distance from the center card
  (`t*t` for the arc, matching a real fanned hand rather than a linear
  ramp). Dropped the hand-focus/collapse mechanic entirely -- Slay the
  Spire's hand has no collapsed state, and the fan + drag interaction
  replaces what that feature was solving anyway.
- **Drag-to-target play, replacing tap-tap**: pressing a hand card lifts
  it (enlarged, rotation straightened, a description tooltip appears);
  dragging it onto an enemy tile plays it targeting that enemy (for
  damaging abilities and capture items); dragging a non-targeted card
  (creature cards, block-only abilities, healing items) up above the
  hand's own top edge releases it; anything else snaps back. Implemented
  via a global `_input()` override on the scene root rather than
  per-tile `gui_input`, since `gui_input` stops firing the instant the
  pointer leaves that control's own bounds -- not workable for a drag
  that ranges across the whole screen. The root only marks an event
  handled (blocking normal button clicks) when a press actually lands on
  a playable hand tile, so End Turn/Return/pile buttons keep working
  normally. The dragged tile is reparented into `AnimationLayer` for the
  duration of the drag and back into `HandArea` on snap-back, since
  sibling draw order in Godot is primarily tree-order-based -- z_index
  alone isn't reliable for making a `HandArea` child render above a
  *later* sibling subtree like the energy orb.
- **Procedural energy orb** (`energy_orb.tscn`): a circular ring +
  bright fill + count label built entirely from `StyleBoxFlat` circles,
  no art asset, replacing the plain "Energy: 3/3" text.
- **Corner pile icons** (`corner_pile_button.tscn`): small card-back +
  count widgets in the bottom corners, replacing the big labeled
  `DRAW PILE`/`DISCARD PILE` boxes -- same tap-to-view-contents behavior
  as before, just restyled.
- **Hexagonal End Turn button** (`hex_end_turn_button.tscn`/`.gd`): a
  custom `_draw()` polygon, since `StyleBoxFlat` only supports rounded
  rectangles, not angled/hex corners -- no art asset needed for a simple
  flat-sided hex shape.

**Deferred to a follow-up pass**: enemy intent icons (the flame icon in
Slay the Spire telegraphing an enemy's next move) -- our enemies currently
pick a random ability live when their turn actually runs
(`_run_enemy_turn()`), so showing an intent icon during the *player's*
turn would need pre-rolling each enemy's chosen move a turn ahead and
storing it, not just a visual addition.

**Verified**: headless editor import (all new scenes/scripts registered
cleanly), all three scenes (card browser, original Battle Test, new Deck
Battle) play-tested headless with zero errors. Since a real press-drag-
release gesture can't be synthesized headlessly, verified the underlying
logic directly instead: a temporary script confirmed the fan layout
produces symmetric, varying positions/rotations across the hand (not all
stacked at one spot), that card-type target-requirement classification is
correct (a creature card needs no target, a damaging ability card does),
that a point at an enemy tile's own center correctly resolves to that
enemy via `_find_enemy_target_at()`, and that resolving a play through
`_resolve_card_play()` correctly damages the target. **Not yet tested
on-device with a real finger-drag gesture** -- the interaction timing/feel
can only really be confirmed there.

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
