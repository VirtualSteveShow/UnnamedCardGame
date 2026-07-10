extends Control
## First playable combat screen: a single 1v1 duel between a hardcoded
## test matchup, driven by BattleState (see that file for the actual
## rules). This scene is purely presentation -- it just reflects
## whatever BattleState says and forwards button presses into it.
##
## Entry point only for now: reached via the "Battle Test" button in
## the card browser. A real "choose your creature, then fight" flow
## doesn't exist yet.

const PLAYER_CREATURE_NAME := "Alley Kitten"
const ENEMY_CREATURE_NAME := "Sewer Rat"

const MAX_LOG_LINES := 5

@onready var player_art: TextureRect = $PlayerPanel/Art
@onready var player_name_label: Label = $PlayerPanel/NameLabel
@onready var player_hp_bar: ProgressBar = $PlayerPanel/HpBar
@onready var player_status_label: Label = $PlayerPanel/StatusLabel

@onready var enemy_art: TextureRect = $EnemyPanel/Art
@onready var enemy_name_label: Label = $EnemyPanel/NameLabel
@onready var enemy_hp_bar: ProgressBar = $EnemyPanel/HpBar
@onready var enemy_status_label: Label = $EnemyPanel/StatusLabel

@onready var log_label: Label = $LogLabel
@onready var energy_label: Label = $EnergyLabel
@onready var ability_buttons_row: HBoxContainer = $AbilityButtonsRow
@onready var end_turn_button: Button = $EndTurnButton
@onready var return_button: Button = $ReturnButton

@onready var result_overlay: Control = $ResultOverlay
@onready var result_label: Label = $ResultOverlay/ResultPanel/ResultLabel
@onready var result_return_button: Button = $ResultOverlay/ResultPanel/ReturnButton

var battle: BattleState
var _log_lines: Array[String] = []


func _ready() -> void:
	var player_data := CardDatabase.get_real_creature_by_name(PLAYER_CREATURE_NAME)
	var enemy_data := CardDatabase.get_real_creature_by_name(ENEMY_CREATURE_NAME)
	battle = BattleState.new(player_data, enemy_data)
	battle.log_message.connect(_on_log_message)
	battle.state_changed.connect(_refresh_ui)

	player_art.texture = player_data.get_display_texture()
	player_name_label.text = player_data.card_name
	enemy_art.texture = enemy_data.get_display_texture()
	enemy_name_label.text = enemy_data.card_name

	for ability in player_data.abilities:
		var btn := Button.new()
		btn.pressed.connect(_on_ability_pressed.bind(ability, btn))
		ability_buttons_row.add_child(btn)

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	return_button.pressed.connect(_return_to_browser)
	result_return_button.pressed.connect(_return_to_browser)

	_refresh_ui()


func _on_ability_pressed(ability: CardAbility, _btn: Button) -> void:
	battle.use_player_ability(ability)


func _on_end_turn_pressed() -> void:
	battle.end_player_turn()


func _on_log_message(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func _refresh_ui() -> void:
	player_hp_bar.max_value = battle.player_data.max_health
	player_hp_bar.value = battle.player_hp
	player_status_label.text = _status_text(battle.player_hp, battle.player_data.max_health, battle.player_block)

	enemy_hp_bar.max_value = battle.enemy_data.max_health
	enemy_hp_bar.value = battle.enemy_hp
	enemy_status_label.text = _status_text(battle.enemy_hp, battle.enemy_data.max_health, battle.enemy_block)

	energy_label.text = "Energy: %d/%d" % [battle.energy, BattleState.ENERGY_PER_TURN]

	for i in ability_buttons_row.get_child_count():
		var btn: Button = ability_buttons_row.get_child(i)
		var ability: CardAbility = battle.player_data.abilities[i]
		btn.text = _ability_button_text(ability)
		btn.disabled = not battle.can_use_ability(ability)

	end_turn_button.disabled = not battle.is_player_turn or battle.is_over

	if battle.is_over:
		result_label.text = "You Won!" if battle.player_won else "You Lost..."
		result_overlay.visible = true


func _status_text(hp: int, max_hp: int, block: int) -> String:
	var text := "%d/%d HP" % [hp, max_hp]
	if block > 0:
		text += "  ·  Block %d" % block
	return text


func _ability_button_text(ability: CardAbility) -> String:
	var parts := ["%s (%d energy)" % [ability.ability_name, ability.energy_cost]]
	if ability.damage > 0:
		parts.append("%d dmg" % ability.damage)
	if ability.block > 0:
		parts.append("%d block" % ability.block)
	return "\n".join(parts)


func _return_to_browser() -> void:
	get_tree().change_scene_to_file("res://scenes/card_browser/card_browser.tscn")
