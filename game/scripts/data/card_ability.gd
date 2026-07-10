class_name CardAbility
extends Resource
## A single creature ability: just a name and the energy cost required to
## use it for now. Real effects (damage, status, etc.) will be added once
## the battle system exists.

@export var ability_name: String = "Ability"
@export var energy_cost: int = 1
