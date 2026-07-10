class_name BattleState
extends RefCounted
## Pure combat logic for a team-vs-team battle -- no UI references, just
## state and rules, so the Battle scene can stay a thin presentation
## layer over this. Each side fields a small team of creatures shown as
## cards on their side of the field; the player picks which of their own
## creatures acts and, for damaging abilities, which enemy card to
## target. See docs/gameplay-notes.md for what's still not built
## (per-creature ability kits, capture integration, a real "choose your
## team" flow).
##
## Turn structure (matches Slay the Spire's convention): each player
## turn refills a single shared energy pool and clears every *player*
## creature's block, abilities spend energy to deal damage and/or grant
## block to their user, then every surviving enemy creature takes one
## automatic turn in order (its block clears first, then it uses a
## random ability of its own against a random living player creature).
## Block absorbs damage before HP does, and always clears at the start
## of its owner's own next turn -- not immediately when the turn that
## granted it ends -- so it still protects against the very next
## incoming hit.

const ENERGY_PER_TURN := 3

signal log_message(text: String)
signal state_changed

var player_team: Array[BattleCombatant] = []
var enemy_team: Array[BattleCombatant] = []
var energy: int = ENERGY_PER_TURN

var is_player_turn: bool = true
var is_over: bool = false
var player_won: bool = false


func _init(player_data: Array[CardData], enemy_data: Array[CardData]) -> void:
	for data in player_data:
		player_team.append(BattleCombatant.new(data))
	for data in enemy_data:
		enemy_team.append(BattleCombatant.new(data))


func can_use_ability(source: BattleCombatant, ability: CardAbility) -> bool:
	return is_player_turn and not is_over and source.is_alive() and energy >= ability.energy_cost


## target is only required for damaging abilities; pass null for a
## block-only ability.
func use_player_ability(source: BattleCombatant, ability: CardAbility, target: BattleCombatant) -> void:
	if not can_use_ability(source, ability):
		return

	energy -= ability.energy_cost
	source.block += ability.block
	if ability.damage > 0 and target != null:
		var dealt := target.take_damage(ability.damage)
		log_message.emit("%s used %s on %s for %d damage!" % [source.data.card_name, ability.ability_name, target.data.card_name, dealt])
	else:
		log_message.emit("%s used %s and gained %d block." % [source.data.card_name, ability.ability_name, ability.block])

	_check_battle_over()
	state_changed.emit()


func end_player_turn() -> void:
	if not is_player_turn or is_over:
		return
	is_player_turn = false
	state_changed.emit()
	_run_enemy_turn()


func _run_enemy_turn() -> void:
	for enemy in enemy_team:
		enemy.block = 0

	for enemy in enemy_team:
		if is_over or not enemy.is_alive() or enemy.data.abilities.is_empty():
			continue

		var living_targets: Array[BattleCombatant] = []
		for p in player_team:
			if p.is_alive():
				living_targets.append(p)
		if living_targets.is_empty():
			break

		var ability: CardAbility = enemy.data.abilities[randi() % enemy.data.abilities.size()]
		var target: BattleCombatant = living_targets[randi() % living_targets.size()]
		enemy.block += ability.block
		if ability.damage > 0:
			var dealt := target.take_damage(ability.damage)
			log_message.emit("%s used %s on %s for %d damage!" % [enemy.data.card_name, ability.ability_name, target.data.card_name, dealt])
		else:
			log_message.emit("%s used %s and gained %d block." % [enemy.data.card_name, ability.ability_name, ability.block])
		_check_battle_over()

	if not is_over:
		_start_player_turn()
	state_changed.emit()


func _start_player_turn() -> void:
	for p in player_team:
		p.block = 0
	energy = ENERGY_PER_TURN
	is_player_turn = true
	log_message.emit("-- Your turn --")


func _check_battle_over() -> void:
	if _all_defeated(enemy_team):
		is_over = true
		player_won = true
		log_message.emit("Enemy team defeated!")
	elif _all_defeated(player_team):
		is_over = true
		player_won = false
		log_message.emit("Your team was defeated...")


func _all_defeated(team: Array[BattleCombatant]) -> bool:
	for c in team:
		if c.is_alive():
			return false
	return true
