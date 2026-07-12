class_name BattleCombatant
extends RefCounted
## Live battle state for one creature on the field: which CardData it is,
## how much HP it has left, and its current block. Kept separate from
## CardData itself since CardData is static card info (shared with the
## browser) and this is per-battle, mutable, and thrown away when the
## battle ends.
##
## Shared by both sides in Deck Battle: the enemy team, and (since player
## creature HP came back) the player's own field_creatures in
## BattleStateV2. turns_on_field only means anything for the latter --
## it drives staggered ability-card unlock (see
## BattleStateV2._regenerate_field_abilities) and is simply left at 0 and
## ignored for enemies.

var data: CardData
var current_hp: int
var block: int = 0

## How many of the player's turns this creature has been on the field
## for, incremented at the start of each such turn. Gates which of its
## abilities have regenerated into hand yet -- ability index N unlocks
## once this reaches N.
var turns_on_field: int = 0


func _init(card_data: CardData) -> void:
	data = card_data
	current_hp = card_data.max_health


func is_alive() -> bool:
	return current_hp > 0


## Applies damage after subtracting current block, and returns the
## amount that actually landed on HP (for log messages).
func take_damage(amount: int) -> int:
	var blocked := mini(block, amount)
	block -= blocked
	var dealt := amount - blocked
	current_hp = maxi(0, current_hp - dealt)
	return dealt
