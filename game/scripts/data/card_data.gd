class_name CardData
extends BaseCardData
## Creature card data. Identity/art/aspect-ratio live on BaseCardData
## (shared with ItemCardData) -- this adds everything specific to a
## creature: level/XP, health, evolution eligibility, and abilities.

## Current level. Leveling up (not implemented yet) will eventually offer
## a choice of evolution path on the creature's first level-up.
@export var level: int = 1

## Progress toward the next level, 0.0-1.0. Drives the XP bar fill.
@export_range(0.0, 1.0) var xp_progress: float = 0.0

## Max HP. All creatures have health; battle/damage systems aren't built
## yet, but the stat needs to exist on the card now.
@export var max_health: int = 10

## Whether this creature is expressive/intelligent enough to plausibly
## gain personality and gear across an evolution line (a raccoon or crow
## reads fine in a hood; a cockroach or opossum doesn't). Creatures with
## this false are permanent single-stage cards by design, not just
## "no evolution art yet."
@export var can_evolve: bool = false

## Abilities available to this creature.
@export var abilities: Array[CardAbility] = []

## Side-view sprite used on the battlefield when this creature is
## summoned into combat -- a full-body profile pose, distinct from
## art_texture's card-portrait framing. Null means no battle sprite yet
## (most of the roster, for now); get_battle_texture() falls back to the
## card art so battle tiles always have something to show.
@export var battle_texture: Texture2D = null


func get_battle_texture() -> Texture2D:
	return battle_texture if battle_texture else get_display_texture()
