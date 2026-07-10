class_name BattleState
extends RefCounted
## Pure combat logic for a single 1v1 duel -- no UI references, just
## state and rules, so the Battle scene can stay a thin presentation
## layer over this. First version: one creature per side, no switching/
## bench/capture -- see docs/gameplay-notes.md for what's next.
##
## Turn structure (matches Slay the Spire's convention): each player
## turn refills energy and clears the *player's* block, abilities spend
## energy to deal damage and/or grant block, then the enemy takes one
## automatic turn (its own block clears first, then it uses a random
## ability of its own). Block absorbs damage before HP does, and always
## clears at the start of its owner's own next turn -- not immediately
## when the turn that granted it ends -- so it still protects against
## the very next incoming hit.

const ENERGY_PER_TURN := 3

signal log_message(text: String)
signal state_changed

var player_data: CardData
var enemy_data: CardData

var player_hp: int
var enemy_hp: int
var player_block: int = 0
var enemy_block: int = 0
var energy: int = ENERGY_PER_TURN

var is_player_turn: bool = true
var is_over: bool = false
var player_won: bool = false


func _init(p_player: CardData, p_enemy: CardData) -> void:
	player_data = p_player
	enemy_data = p_enemy
	player_hp = p_player.max_health
	enemy_hp = p_enemy.max_health


func can_use_ability(ability: CardAbility) -> bool:
	return is_player_turn and not is_over and energy >= ability.energy_cost


func use_player_ability(ability: CardAbility) -> void:
	if not can_use_ability(ability):
		return

	energy -= ability.energy_cost
	player_block += ability.block
	if ability.damage > 0:
		var dealt := _apply_damage(ability.damage, "enemy")
		log_message.emit("%s used %s for %d damage!" % [player_data.card_name, ability.ability_name, dealt])
	else:
		log_message.emit("%s used %s and gained %d block." % [player_data.card_name, ability.ability_name, ability.block])

	_check_battle_over()
	state_changed.emit()


func end_player_turn() -> void:
	if not is_player_turn or is_over:
		return
	is_player_turn = false
	state_changed.emit()
	_run_enemy_turn()


func _run_enemy_turn() -> void:
	enemy_block = 0
	if enemy_data.abilities.is_empty():
		_start_player_turn()
		return

	var ability: CardAbility = enemy_data.abilities[randi() % enemy_data.abilities.size()]
	enemy_block += ability.block
	if ability.damage > 0:
		var dealt := _apply_damage(ability.damage, "player")
		log_message.emit("%s used %s for %d damage!" % [enemy_data.card_name, ability.ability_name, dealt])
	else:
		log_message.emit("%s used %s and gained %d block." % [enemy_data.card_name, ability.ability_name, ability.block])

	_check_battle_over()
	if not is_over:
		_start_player_turn()
	state_changed.emit()


func _start_player_turn() -> void:
	player_block = 0
	energy = ENERGY_PER_TURN
	is_player_turn = true
	log_message.emit("-- Your turn --")


## Applies damage to whichever side's block/HP after subtracting its
## current block, and returns the amount that actually landed (for the
## log message). target is "player" or "enemy".
func _apply_damage(amount: int, target: String) -> int:
	var block: int = player_block if target == "player" else enemy_block
	var blocked := mini(block, amount)
	var dealt := amount - blocked

	if target == "player":
		player_block -= blocked
		player_hp = maxi(0, player_hp - dealt)
	else:
		enemy_block -= blocked
		enemy_hp = maxi(0, enemy_hp - dealt)

	return dealt


func _check_battle_over() -> void:
	if enemy_hp <= 0:
		is_over = true
		player_won = true
		log_message.emit("%s defeated!" % enemy_data.card_name)
	elif player_hp <= 0:
		is_over = true
		player_won = false
		log_message.emit("%s was defeated..." % player_data.card_name)
