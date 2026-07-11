# Unnamed Card Game — Lore / Backstory

Narrative/worldbuilding notes, kept separate from `gameplay-notes.md` (which
is mechanics/design). Subject to change, very early brainstorm stage.

## Core conceit: cards are a storage/command technology

A "card" isn't a metaphor for the creature -- it's what commanding a
captured animal actually looks like in-universe. Capturing a creature
dematerializes it into a card; playing/summoning that card reprints the
creature back into physical form with directives (the ability being used)
baked into the reprint. This gives the whole TCG mechanic an in-universe
justification instead of being purely an abstraction.

- **Mundane, not just adventuring gear.** The tech is widespread and
  civilian -- an entire farm's livestock could be consolidated into a deck
  of cards for storage/transport. This is a deliberate contrast with
  Pokémon's "adventurer throws a ball at a wild animal" framing: capture
  here reads more like storage-and-care technology than conquest, softened
  ethical texture on the core mechanic. Worth leaning into as a
  differentiator if the game wants one.
- **No aging.** Captured creatures don't age between summons -- every time
  one is reprinted, it comes back with all its memories intact but a fresh
  body. In theory a pet captured once could be kept, unaged, forever.
- **Philosophical hook (not yet used, keep in reserve):** classic
  "transporter problem" territory -- is a reprint *the same* creature, or
  a perfect copy that only feels continuous because it remembers being the
  original? Rich enough to be an actual story theme later (a character who
  doesn't trust reprinted pets, a villain who considers the tech
  monstrous), not just a mechanical justification.

## Working sci-fi plausibility rule

Raised as a concern: energy conservation. Recreating a ~30kg animal's mass
from pure energy via E=mc² would take about 2.7×10^18 joules -- comparable
to a large asteroid impact, not something to hand-wave even loosely.

**The rule to keep consistent:** a card stores the creature's actual
matter, not just information about it. Capturing dematerializes and
*retains* the original mass in some compressed/exotic state; reprinting is
reassembly of that same stored matter using the stored pattern/information
(closer to a Star Trek transporter's pattern buffer than a full
replicator-from-raw-energy). No mass-energy is created or destroyed, just
stored and later reassembled -- an exotic technology, but an internally
consistent one.

- **Cheap consistency test:** anything that implies the tech creates a
  creature *from nothing* (e.g., duplicating a card to get two of the same
  pet) should be off-limits under this rule. Anything that's just "store
  it, retrieve it later, unaged" is fine.
- Totally fine to just brush past this in most player-facing text
  (Pokémon never explains Poké Balls either) -- this rule exists so *we*
  stay internally consistent if the topic ever comes up, not because the
  game needs to lecture the player about it.

## Factions / locations

See `gameplay-notes.md` for the mechanical writeup of City Faction (built)
and Suburbs (in progress). Full location brainstorm, only City and Suburbs
committed to so far:

- **City** (built) -- gritty urban night. First faction, sets the visual
  bar.
- **Suburbs** (in progress) -- daytime, calm counterpart to City. Doubles
  as the natural tutorial location: basic creatures, mostly one ability
  each, gentle difficulty ramp. Also a plausible *second starter option*
  later if the game ends up supporting more than one (see
  gameplay-notes.md's run-structure section) -- undecided for now.
- **Farm/Country** -- ties directly into the "farm consolidated to a deck"
  worldbuilding beat above. Livestock + working animals. Likely a
  herd/numbers or support-flavored mechanical identity, distinct from
  City's stealth/brawn split.
- **Jungle**, **Desert**, **Tundra** -- classic biomes, strong visual
  contrast from each other and from City/Suburbs. Sequence after
  Suburbs/Farm since they're a bigger tonal leap.
- **Savanna/Plains** -- wild herd animals (distinct from Farm's
  domesticated ones), pack-tactics mechanical flavor.
- **Mountain/Alpine** -- goats, eagles; verticality/high-ground flavor,
  distinct from Tundra's cold-endurance angle.
- **Cave/Underground** -- distinct from City's sewer: deeper, more
  primordial, true-darkness/stealth theme.
- **Ocean** -- probably doesn't fit as a normal faction. The friction
  isn't visual, it's mechanical: capture-into-a-card-battlefield implies
  land-based, human-scale combat, and an orca doesn't obviously fit next
  to a raccoon without a separate aquatic-encounter mode. Shelved unless
  that's specifically designed for.
- **Robot/Corporation** -- a corporation manufacturing robotic animals.
  Interesting as more than just another biome: mechanically they wouldn't
  need the dematerialize-and-reprint tech at all (they're just machines,
  power down and box them), which is a natural narrative *foil* to every
  organic faction. Strong candidate as the setting's antagonist faction /
  a late-game reveal rather than an early biome.

**Scope call:** aiming for ~4-6 total factions for a first real release,
prioritized by how mechanically/visually distinct they are from each
other, not biome-completionism. City took a real content investment alone
(starter evolution line, 9-creature roster, item cards) -- a tight
Suburbs -> Farm -> one wild biome -> Robot-as-antagonist arc beats a long
tail of similar-feeling biomes.
