class_name CardAbility
extends Resource
## A single creature ability: a name, the energy cost required to use it,
## and its effect. Kept intentionally simple for the first version of
## combat -- an ability either deals damage, grants block, or both.
## Status effects, multi-target, etc. can extend this later.

@export var ability_name: String = "Ability"
@export var energy_cost: int = 1

## Unique art for this specific ability (e.g. a raccoon's Strike shows it
## lunging to attack, distinct from its Guard art or its card portrait).
## Null falls back to the source creature's battle/card art -- see
## AbilityCardData construction in battle_state_v2.gd.
@export var art_texture: Texture2D = null

## Damage dealt to the opposing creature when this ability is used.
@export var damage: int = 0

## Block granted to the user; reduces the next hit taken before combat
## resets it back to 0 at the start of the user's following turn (same
## convention Slay the Spire uses).
@export var block: int = 0

## HP restored to the player when this ability resolves. Currently only
## used by on-summon abilities (CardData.on_summon_ability) -- regular
## creature abilities don't heal yet.
@export var heal: int = 0
