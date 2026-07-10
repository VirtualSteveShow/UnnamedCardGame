extends Control
## Battlefield: enemy team on one row (fixed roster, already in play),
## player's field on another (starts empty, grows as creature cards are
## summoned from hand), and a hand row of playable cards drawn from the
## player's deck. See BattleState for the actual rules -- this is
## purely presentation plus the tap-interpretation state machine:
##
## - Tap a hand creature card -> summons it onto your field immediately.
## - Tap a hand item card -> waits for a target (ally for healing,
##   enemy for capture), then resolves.
## - Tap one of your own field creatures -> selects it as the acting
##   creature; its abilities appear as buttons.
## - Tap an ability -> block-only abilities resolve immediately;
##   damaging ones wait for an enemy tap to target.
##
## Entry point only for now: reached via the "Battle Test" button in
## the card browser. A real "choose your team, then fight" flow doesn't
## exist yet.

const CombatantTileScene := preload("res://scenes/battle/battle_combatant_tile.tscn")
const HandTileScene := preload("res://scenes/battle/battle_hand_card_tile.tscn")

## Mixed creature + item cards, per design direction: one deck, not
## separate creature/action decks. A couple of duplicates included so a
## short test battle can actually exercise the reshuffle-on-empty path.
const PLAYER_DECK_CREATURES := ["Alley Kitten", "Alley Kitten", "Raccoon", "Crow"]
const PLAYER_DECK_ITEMS := ["Alley Snare", "Weighted Net", "Back-Alley Bandage", "Back-Alley Bandage"]

const ENEMY_TEAM_NAMES := ["Sewer Rat", "Cockroach", "Opossum"]

const MAX_LOG_LINES := 5

@onready var enemy_row: HBoxContainer = $EnemyRow
@onready var player_row: HBoxContainer = $PlayerRow
@onready var hand_row: HBoxContainer = $HandRow
@onready var log_label: Label = $LogLabel
@onready var hint_label: Label = $HintLabel
@onready var energy_label: Label = $EnergyLabel
@onready var pile_counts_label: Label = $PileCountsLabel
@onready var ability_buttons_row: HBoxContainer = $AbilityButtonsRow
@onready var end_turn_button: Button = $EndTurnButton
@onready var return_button: Button = $ReturnButton

@onready var result_overlay: Control = $ResultOverlay
@onready var result_label: Label = $ResultOverlay/ResultPanel/ResultLabel
@onready var result_return_button: Button = $ResultOverlay/ResultPanel/ReturnButton

var battle: BattleState
var _log_lines: Array[String] = []

## All three of these are tracked ourselves rather than read back from
## their container's live children -- queue_free()'d nodes linger in
## the tree until the end of the frame, so reading a container's
## children right after a rebuild could transiently include stale
## nodes and desync from whatever array we're indexing against.
var _player_tiles: Array = []
var _enemy_tiles: Array = []
var _hand_tiles: Array = []
var _ability_buttons: Array[Button] = []

var _selected_source: BattleCombatant = null
var _pending_ability: CardAbility = null
var _pending_item: ItemCardData = null


func _ready() -> void:
	var deck_cards: Array[BaseCardData] = []
	for creature_name in PLAYER_DECK_CREATURES:
		deck_cards.append(CardDatabase.get_real_creature_by_name(creature_name))
	for item_name in PLAYER_DECK_ITEMS:
		for item in ItemDatabase.get_item_cards():
			if item.card_name == item_name:
				deck_cards.append(item)
				break

	var enemy_data: Array[CardData] = []
	for creature_name in ENEMY_TEAM_NAMES:
		enemy_data.append(CardDatabase.get_real_creature_by_name(creature_name))

	battle = BattleState.new(deck_cards, enemy_data)
	battle.log_message.connect(_on_log_message)
	battle.state_changed.connect(_on_state_changed)
	battle.creature_summoned.connect(_on_creature_summoned)

	for combatant in battle.enemy_team:
		var tile := CombatantTileScene.instantiate()
		enemy_row.add_child(tile)
		tile.setup(combatant)
		tile.tapped.connect(_on_enemy_tile_tapped)
		_enemy_tiles.append(tile)

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	return_button.pressed.connect(_return_to_browser)
	result_return_button.pressed.connect(_return_to_browser)
	get_viewport().size_changed.connect(_refresh_all)

	_rebuild_hand_tiles()
	_refresh_all()


func _on_creature_summoned(combatant: BattleCombatant) -> void:
	var tile := CombatantTileScene.instantiate()
	player_row.add_child(tile)
	tile.setup(combatant)
	tile.tapped.connect(_on_player_tile_tapped)
	_player_tiles.append(tile)
	_select_source(combatant)


func _on_hand_card_tapped(card: BaseCardData) -> void:
	if not battle.can_play_card(card):
		return
	if card is CardData:
		battle.play_creature_card(card)
	elif card is ItemCardData:
		_pending_ability = null
		_pending_item = card
		_refresh_all()


func _on_player_tile_tapped(combatant: BattleCombatant) -> void:
	if _pending_item != null:
		if _pending_item.item_type == ItemCardData.ItemType.HEALING:
			battle.play_item_card(_pending_item, combatant)
			_pending_item = null
		return
	if not battle.is_player_turn or battle.is_over or not combatant.is_alive():
		return
	_select_source(combatant)
	_refresh_all()


func _on_enemy_tile_tapped(combatant: BattleCombatant) -> void:
	if _pending_item != null:
		if _pending_item.item_type == ItemCardData.ItemType.CAPTURE:
			battle.play_item_card(_pending_item, combatant)
			_pending_item = null
		return
	if _pending_ability == null or not combatant.is_alive():
		return
	battle.use_creature_ability(_selected_source, _pending_ability, combatant)
	_pending_ability = null


func _on_ability_pressed(ability: CardAbility) -> void:
	if _selected_source == null or not battle.can_use_ability(_selected_source, ability):
		return
	if ability.damage > 0:
		_pending_item = null
		_pending_ability = ability
		_refresh_all()
	else:
		battle.use_creature_ability(_selected_source, ability, null)


func _on_end_turn_pressed() -> void:
	_pending_ability = null
	_pending_item = null
	battle.end_player_turn()


func _on_log_message(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func _on_state_changed() -> void:
	_remove_dead_tiles()
	if _selected_source == null or not _selected_source.is_alive():
		_select_source(_first_alive(battle.player_team))
	else:
		_pending_ability = null
	_rebuild_hand_tiles()
	_refresh_all()


func _select_source(combatant: BattleCombatant) -> void:
	_selected_source = combatant
	_pending_ability = null
	for tile in _player_tiles:
		tile.set_selected(tile.combatant == combatant)
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


func _rebuild_hand_tiles() -> void:
	for tile in _hand_tiles:
		tile.queue_free()
	_hand_tiles.clear()

	for card in battle.player_hand:
		var tile := HandTileScene.instantiate()
		hand_row.add_child(tile)
		tile.setup(card)
		tile.disabled = not battle.can_play_card(card)
		tile.set_selected(card == _pending_item)
		tile.tapped.connect(_on_hand_card_tapped)
		_hand_tiles.append(tile)


## Removes the field tile for any combatant whose HP hit 0, on either
## side -- BattleState itself never removes a defeated combatant from
## its own team arrays (targeting/turn logic already skips them via
## is_alive() checks), this is purely the visual "leaves play" effect.
func _remove_dead_tiles() -> void:
	_prune_dead(_player_tiles)
	_prune_dead(_enemy_tiles)


func _prune_dead(tiles: Array) -> void:
	for i in range(tiles.size() - 1, -1, -1):
		if not tiles[i].combatant.is_alive():
			tiles[i].queue_free()
			tiles.remove_at(i)


## Sizes every tile in a row to fill as much of the row's available
## space as possible while keeping the standard card aspect ratio and
## fitting every tile side by side -- mirrors the card browser's
## approach instead of a fixed pixel size, so battle tiles actually use
## the space available (especially on wide/high-res phone screens)
## rather than sitting small in the middle of a mostly-empty row.
func _resize_row(row: HBoxContainer, tiles: Array) -> void:
	if tiles.is_empty():
		return

	var separation: float = row.get_theme_constant("separation")
	var count: int = tiles.size()

	# Two candidate sizes: as big as the row's full height allows, or as
	# big as fitting every tile side-by-side in the row's width allows.
	# Whichever is smaller is the actual limit -- using the larger of
	# the two would overflow the other dimension.
	var height_from_height_limit: float = row.size.y
	var width_from_height_limit: float = height_from_height_limit * BaseCardData.ASPECT_RATIO

	var width_from_width_limit: float = (row.size.x - separation * (count - 1)) / count
	var height_from_width_limit: float = width_from_width_limit / BaseCardData.ASPECT_RATIO

	var tile_width: float
	var tile_height: float
	if height_from_height_limit <= height_from_width_limit:
		tile_height = height_from_height_limit
		tile_width = width_from_height_limit
	else:
		tile_width = width_from_width_limit
		tile_height = height_from_width_limit

	var tile_size := Vector2(maxf(tile_width, 40.0), maxf(tile_height, 60.0))
	for tile in tiles:
		tile.custom_minimum_size = tile_size


func _refresh_all() -> void:
	_resize_row(enemy_row, _enemy_tiles)
	_resize_row(player_row, _player_tiles)
	_resize_row(hand_row, _hand_tiles)

	for tile in _player_tiles:
		tile.refresh()
	for tile in _enemy_tiles:
		tile.refresh()

	energy_label.text = "Energy: %d/%d" % [battle.energy, BattleState.ENERGY_PER_TURN]
	pile_counts_label.text = "Deck: %d  ·  Discard: %d  ·  Hand: %d" % [
		battle.player_deck.size(), battle.player_discard.size(), battle.player_hand.size()]

	if battle.is_over:
		hint_label.text = ""
	elif _pending_ability != null:
		hint_label.text = "Choose an enemy to target with %s" % _pending_ability.ability_name
	elif _pending_item != null:
		hint_label.text = "Choose a target for %s" % _pending_item.card_name
	elif not battle.is_player_turn:
		hint_label.text = "Enemy turn…"
	else:
		hint_label.text = "Pick a creature and an ability, or play a card from your hand"

	if _selected_source != null:
		for i in _ability_buttons.size():
			var ability: CardAbility = _selected_source.data.abilities[i]
			_ability_buttons[i].text = _ability_button_text(ability)
			_ability_buttons[i].disabled = not battle.can_use_ability(_selected_source, ability)

	for tile in _hand_tiles:
		tile.disabled = not battle.can_play_card(tile.card)
		tile.set_selected(tile.card == _pending_item)

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
