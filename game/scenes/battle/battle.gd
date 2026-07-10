extends Control
## Battlefield: enemy team on one row, player team on the other. See
## BattleState for the actual combat rules -- this is purely
## presentation plus the tap-interpretation state machine: tap one of
## your own creatures to select it as the actor, tap an ability (block-
## only abilities resolve immediately; damaging ones wait for a target),
## then tap an enemy creature to resolve the attack against it.
##
## Entry point only for now: reached via the "Battle Test" button in
## the card browser. A real "choose your team, then fight" flow doesn't
## exist yet.

const TileScene := preload("res://scenes/battle/battle_combatant_tile.tscn")

const PLAYER_TEAM_NAMES := ["Alley Kitten", "Raccoon", "Crow"]
const ENEMY_TEAM_NAMES := ["Sewer Rat", "Cockroach", "Opossum"]

const MAX_LOG_LINES := 5

@onready var enemy_row: HBoxContainer = $EnemyRow
@onready var player_row: HBoxContainer = $PlayerRow
@onready var log_label: Label = $LogLabel
@onready var hint_label: Label = $HintLabel
@onready var energy_label: Label = $EnergyLabel
@onready var ability_buttons_row: HBoxContainer = $AbilityButtonsRow
@onready var end_turn_button: Button = $EndTurnButton
@onready var return_button: Button = $ReturnButton

@onready var result_overlay: Control = $ResultOverlay
@onready var result_label: Label = $ResultOverlay/ResultPanel/ResultLabel
@onready var result_return_button: Button = $ResultOverlay/ResultPanel/ReturnButton

var battle: BattleState
var _log_lines: Array[String] = []

## Parallel to battle.player_team / battle.enemy_team.
var _player_tiles: Array = []
var _enemy_tiles: Array = []

## Tracked ourselves rather than read back from ability_buttons_row's
## live children -- queue_free()'d nodes linger in the tree until the
## end of the frame, so reading get_children() right after rebuilding
## could transiently include stale buttons and desync from
## _selected_source.data.abilities by index.
var _ability_buttons: Array[Button] = []

var _selected_source: BattleCombatant = null
var _pending_ability: CardAbility = null


func _ready() -> void:
	var player_data: Array[CardData] = []
	for creature_name in PLAYER_TEAM_NAMES:
		player_data.append(CardDatabase.get_real_creature_by_name(creature_name))
	var enemy_data: Array[CardData] = []
	for creature_name in ENEMY_TEAM_NAMES:
		enemy_data.append(CardDatabase.get_real_creature_by_name(creature_name))

	battle = BattleState.new(player_data, enemy_data)
	battle.log_message.connect(_on_log_message)
	battle.state_changed.connect(_on_state_changed)

	for combatant in battle.player_team:
		var tile := TileScene.instantiate()
		player_row.add_child(tile)
		tile.setup(combatant)
		tile.tapped.connect(_on_player_tile_tapped)
		_player_tiles.append(tile)

	for combatant in battle.enemy_team:
		var tile := TileScene.instantiate()
		enemy_row.add_child(tile)
		tile.setup(combatant)
		tile.tapped.connect(_on_enemy_tile_tapped)
		_enemy_tiles.append(tile)

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	return_button.pressed.connect(_return_to_browser)
	result_return_button.pressed.connect(_return_to_browser)

	_select_source(_first_alive(battle.player_team))
	_refresh_all()


func _on_player_tile_tapped(combatant: BattleCombatant) -> void:
	if not battle.is_player_turn or battle.is_over or not combatant.is_alive():
		return
	_select_source(combatant)
	_refresh_all()


func _on_enemy_tile_tapped(combatant: BattleCombatant) -> void:
	if _pending_ability == null or not combatant.is_alive():
		return
	battle.use_player_ability(_selected_source, _pending_ability, combatant)
	_pending_ability = null


func _on_ability_pressed(ability: CardAbility) -> void:
	if _selected_source == null or not battle.can_use_ability(_selected_source, ability):
		return
	if ability.damage > 0:
		_pending_ability = ability
		hint_label.text = "Choose an enemy to target with %s" % ability.ability_name
	else:
		battle.use_player_ability(_selected_source, ability, null)


func _on_end_turn_pressed() -> void:
	_pending_ability = null
	battle.end_player_turn()


func _on_log_message(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func _on_state_changed() -> void:
	# If the acting creature died (or none was ever picked), fall back
	# to whichever of ours is still standing so the ability buttons
	# always reflect someone alive rather than a dead/stale selection.
	if _selected_source == null or not _selected_source.is_alive():
		_select_source(_first_alive(battle.player_team))
	else:
		_pending_ability = null
	_refresh_all()


func _select_source(combatant: BattleCombatant) -> void:
	_selected_source = combatant
	_pending_ability = null
	for i in _player_tiles.size():
		_player_tiles[i].set_selected(battle.player_team[i] == combatant)
	_rebuild_ability_buttons()


func _rebuild_ability_buttons() -> void:
	for btn in _ability_buttons:
		btn.queue_free()
	_ability_buttons.clear()

	if _selected_source == null:
		return
	for ability in _selected_source.data.abilities:
		var btn := Button.new()
		btn.pressed.connect(_on_ability_pressed.bind(ability))
		ability_buttons_row.add_child(btn)
		_ability_buttons.append(btn)


func _refresh_all() -> void:
	for tile in _player_tiles:
		tile.refresh()
	for tile in _enemy_tiles:
		tile.refresh()

	energy_label.text = "Energy: %d/%d" % [battle.energy, BattleState.ENERGY_PER_TURN]

	if battle.is_over:
		hint_label.text = ""
	elif _pending_ability == null:
		hint_label.text = "Your turn -- pick a creature and an ability" if battle.is_player_turn else "Enemy turn…"

	if _selected_source != null:
		for i in _ability_buttons.size():
			var ability: CardAbility = _selected_source.data.abilities[i]
			_ability_buttons[i].text = _ability_button_text(ability)
			_ability_buttons[i].disabled = not battle.can_use_ability(_selected_source, ability)

	end_turn_button.disabled = not battle.is_player_turn or battle.is_over

	if battle.is_over:
		result_label.text = "You Won!" if battle.player_won else "You Lost..."
		result_overlay.visible = true


func _ability_button_text(ability: CardAbility) -> String:
	var parts := ["%s (%d energy)" % [ability.ability_name, ability.energy_cost]]
	if ability.damage > 0:
		parts.append("%d dmg" % ability.damage)
	if ability.block > 0:
		parts.append("%d block" % ability.block)
	return "\n".join(parts)


func _first_alive(team: Array[BattleCombatant]) -> BattleCombatant:
	for c in team:
		if c.is_alive():
			return c
	return null


func _return_to_browser() -> void:
	get_tree().change_scene_to_file("res://scenes/card_browser/card_browser.tscn")
