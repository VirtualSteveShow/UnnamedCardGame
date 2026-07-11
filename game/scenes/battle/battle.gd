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

## Draw animation: a "ghost" copy of the drawn card flies from the deck
## pile's on-screen position to its final hand-row slot, growing from a
## small deck-sized card to full hand-card size. Multiple cards drawn at
## once (e.g. the opening hand) are staggered so they read as being
## dealt one at a time instead of all popping in together.
const DRAW_ANIM_DURATION := 0.35
const DRAW_ANIM_STAGGER := 0.1

## Hand focus state: the hand rests small (card-back-pile-sized, and
## non-interactive) along the bottom of the screen until tapped, then
## grows to this taller band and becomes playable. Only anchor_top
## differs between the two -- left/right/bottom stay fixed so the deck
## and discard piles beside the hand never move. Kept as named constants
## (not read from the .tscn) since HandFocusCatcher has to track
## HandRow's anchor_top exactly.
const HAND_ANCHOR_LEFT := 0.02
const HAND_ANCHOR_RIGHT := 0.62
const HAND_ANCHOR_BOTTOM := 0.855
const HAND_UNFOCUSED_TOP := 0.525
const HAND_FOCUSED_TOP := 0.20

## Mixed creature + item cards, per design direction: one deck, not
## separate creature/action decks. A couple of duplicates included so a
## short test battle can actually exercise the reshuffle-on-empty path.
## Suburbs Faction for now (was City) to exercise the new roster -- item
## cards are Suburbs' own tutorial-only pair (Cat Carrier + Band-Aid).
const PLAYER_DECK_CREATURES := ["House Cat", "House Cat", "Family Dog", "Squirrel"]
const PLAYER_DECK_ITEMS := ["Cat Carrier", "Band-Aid", "Band-Aid"]

const ENEMY_TEAM_NAMES := ["Rabbit", "Robin", "Hamster"]

const MAX_LOG_LINES := 5

@onready var enemy_row: HBoxContainer = $EnemyRow
@onready var player_row: HBoxContainer = $PlayerRow
@onready var hand_row: HBoxContainer = $HandRow
@onready var hand_focus_catcher: Button = $HandFocusCatcher
@onready var hand_scrim: Button = $HandScrim
@onready var deck_pile_button := $PileRow/DeckPileButton
@onready var discard_pile_button := $PileRow/DiscardPileButton
@onready var log_label: Label = $LogLabel
@onready var hint_label: Label = $HintLabel
@onready var energy_label: Label = $EnergyLabel
@onready var ability_buttons_row: HBoxContainer = $AbilityButtonsRow
@onready var end_turn_button: Button = $EndTurnButton
@onready var return_button: Button = $ReturnButton
@onready var animation_layer: Control = $AnimationLayer

@onready var result_overlay: Control = $ResultOverlay
@onready var result_label: Label = $ResultOverlay/ResultPanel/ResultLabel
@onready var result_return_button: Button = $ResultOverlay/ResultPanel/ReturnButton

@onready var pile_view_overlay: Control = $PileViewOverlay
@onready var pile_view_title: Label = $PileViewOverlay/PileViewPanel/TitleLabel
@onready var pile_view_grid: GridContainer = $PileViewOverlay/PileViewPanel/ScrollContainer/GridContainer
@onready var pile_view_close_button: Button = $PileViewOverlay/PileViewPanel/CloseButton

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

## Cards from the most recent cards_drawn signal, consumed (and cleared)
## the next time _rebuild_hand_tiles() runs -- lets that rebuild know
## which of the tiles it's about to create should play the fly-in
## animation instead of just appearing instantly.
var _pending_draw_cards: Array = []

var _hand_focused: bool = false


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
	battle.cards_drawn.connect(_on_cards_drawn)

	for combatant in battle.enemy_team:
		var tile := CombatantTileScene.instantiate()
		enemy_row.add_child(tile)
		tile.setup(combatant)
		tile.tapped.connect(_on_enemy_tile_tapped)
		_enemy_tiles.append(tile)

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	return_button.pressed.connect(_return_to_browser)
	result_return_button.pressed.connect(_return_to_browser)
	deck_pile_button.set_label("DRAW PILE")
	deck_pile_button.tapped.connect(_on_deck_pile_tapped)
	discard_pile_button.set_label("DISCARD PILE")
	discard_pile_button.tapped.connect(_on_discard_pile_tapped)
	pile_view_close_button.pressed.connect(func() -> void: pile_view_overlay.visible = false)
	hand_focus_catcher.pressed.connect(func() -> void: _set_hand_focused(true))
	hand_scrim.pressed.connect(func() -> void: _set_hand_focused(false))
	get_viewport().size_changed.connect(_refresh_all)

	battle.start_battle()
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


func _on_cards_drawn(cards: Array) -> void:
	_pending_draw_cards.append_array(cards)


func _on_deck_pile_tapped() -> void:
	var cards := battle.player_deck.duplicate()
	cards.sort_custom(func(a, b) -> bool: return a.card_name < b.card_name)
	_show_pile_view("Draw Pile", cards)


func _on_discard_pile_tapped() -> void:
	var cards := battle.player_discard.duplicate()
	cards.sort_custom(func(a, b) -> bool: return a.card_name < b.card_name)
	_show_pile_view("Discard Pile", cards)


func _show_pile_view(title: String, cards: Array) -> void:
	for child in pile_view_grid.get_children():
		child.queue_free()

	pile_view_title.text = "%s (%d)" % [title, cards.size()]
	for card in cards:
		var tile := HandTileScene.instantiate()
		pile_view_grid.add_child(tile)
		tile.setup(card)
		tile.disabled = true

	pile_view_overlay.visible = true


## Hand starts small and non-interactive (resting along the bottom of
## the screen); tapping it (or any hand card) expands it to full size
## and playability. Tapping the scrim behind the expanded hand collapses
## it back. Only anchor_top moves -- see the HAND_* constants.
func _set_hand_focused(focused: bool) -> void:
	if _hand_focused == focused:
		return
	_hand_focused = focused

	hand_row.anchor_top = HAND_FOCUSED_TOP if focused else HAND_UNFOCUSED_TOP
	hand_focus_catcher.anchor_top = hand_row.anchor_top
	hand_focus_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE if focused else Control.MOUSE_FILTER_STOP

	hand_scrim.visible = focused
	hand_scrim.mouse_filter = Control.MOUSE_FILTER_STOP if focused else Control.MOUSE_FILTER_IGNORE

	_refresh_all()


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

	var cards_to_animate := _pending_draw_cards.duplicate()
	_pending_draw_cards.clear()
	var tiles_to_animate: Array = []

	for card in battle.player_hand:
		var tile := HandTileScene.instantiate()
		hand_row.add_child(tile)
		tile.setup(card)
		tile.disabled = not battle.can_play_card(card)
		tile.set_selected(card == _pending_item)
		tile.tapped.connect(_on_hand_card_tapped)
		_hand_tiles.append(tile)
		if card in cards_to_animate:
			tile.modulate.a = 0.0
			tiles_to_animate.append(tile)

	if not tiles_to_animate.is_empty():
		_animate_drawn_cards(tiles_to_animate)


## Waits for the hand row to finish laying out (a Container's sort
## happens on a deferred pass, not the instant a child is added or
## resized) so each tile's global_position/size reflects where it's
## actually about to sit before spawning a ghost to fly there -- then
## staggers each ghost's flight so a multi-card draw reads as cards
## being dealt one at a time rather than all popping in together.
func _animate_drawn_cards(tiles: Array) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	for i in tiles.size():
		var tile = tiles[i]
		if is_instance_valid(tile):
			_fly_card_from_deck(tile, i * DRAW_ANIM_STAGGER)


## Spawns a throwaway "ghost" copy of the tile's card that visually
## travels from the deck pile to the tile's real (already laid-out)
## position, then reveals the real tile and discards the ghost. The
## real tile never moves -- only the ghost animates -- so this can't
## desync from whatever the hand row's container decides the layout is.
func _fly_card_from_deck(tile: Control, delay: float) -> void:
	var ghost := HandTileScene.instantiate()
	animation_layer.add_child(ghost)
	ghost.setup(tile.card)
	ghost.disabled = true
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.size = tile.size

	var target_pos: Vector2 = tile.global_position
	var target_size: Vector2 = tile.size
	var start_size: Vector2 = target_size * 0.3
	var start_pos: Vector2 = deck_pile_button.global_position \
		+ deck_pile_button.size / 2.0 - start_size / 2.0

	ghost.global_position = start_pos
	ghost.size = start_size
	ghost.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(ghost, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(ghost, "global_position", target_pos, DRAW_ANIM_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "size", target_size, DRAW_ANIM_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if is_instance_valid(tile):
			tile.modulate.a = 1.0
		ghost.queue_free()
	)


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


## Shared sizing math: the largest tile that fits `count` copies of it
## side by side (with `separation` gaps) inside `available`, while
## keeping the standard card aspect ratio. Two candidate sizes -- as big
## as the full height allows, or as big as fitting every tile in the
## available width allows -- whichever is smaller is the real limit
## (the larger one would overflow the other dimension).
func _fit_tile_size(available: Vector2, count: int, separation: float) -> Vector2:
	var height_from_height_limit: float = available.y
	var width_from_height_limit: float = height_from_height_limit * BaseCardData.ASPECT_RATIO

	var width_from_width_limit: float = (available.x - separation * (count - 1)) / count
	var height_from_width_limit: float = width_from_width_limit / BaseCardData.ASPECT_RATIO

	var tile_width: float
	var tile_height: float
	if height_from_height_limit <= height_from_width_limit:
		tile_height = height_from_height_limit
		tile_width = width_from_height_limit
	else:
		tile_width = width_from_width_limit
		tile_height = height_from_width_limit

	return Vector2(maxf(tile_width, 40.0), maxf(tile_height, 60.0))


## Sizes every tile in a row to fill as much of the row's available
## space as possible -- mirrors the card browser's approach instead of a
## fixed pixel size, so battle tiles actually use the space available
## (especially on wide/high-res phone screens) rather than sitting small
## in the middle of a mostly-empty row.
func _resize_row(row: HBoxContainer, tiles: Array) -> void:
	if tiles.is_empty():
		return
	var separation: float = row.get_theme_constant("separation")
	var tile_size := _fit_tile_size(row.size, tiles.size(), separation)
	for tile in tiles:
		tile.custom_minimum_size = tile_size


## Enemy and player creature tiles used to be sized independently per
## row, so they visibly mismatched whenever the two rows' rect heights
## or creature counts differed (which they usually do -- the enemy
## roster is fixed at battle start, the player's field starts empty and
## grows). Compute one candidate per row, then use the smaller of the
## two for both, so every creature on the board -- either side -- is the
## same size.
func _resize_creature_rows() -> void:
	var enemy_candidate := _fit_tile_size(
		enemy_row.size, maxi(_enemy_tiles.size(), 1), enemy_row.get_theme_constant("separation"))
	var player_candidate := _fit_tile_size(
		player_row.size, maxi(_player_tiles.size(), 1), player_row.get_theme_constant("separation"))
	var shared_size := Vector2(
		minf(enemy_candidate.x, player_candidate.x), minf(enemy_candidate.y, player_candidate.y))

	for tile in _enemy_tiles:
		tile.custom_minimum_size = shared_size
	for tile in _player_tiles:
		tile.custom_minimum_size = shared_size


## The deck/discard piles always sit at their resting size -- the same
## size the hand's cards are when the hand itself is unfocused/resting --
## regardless of whether the hand is currently focused/enlarged. Computed
## against the fixed unfocused anchor rect rather than hand_row's actual
## current rect, since that rect is whatever the current focus state made
## it (possibly the enlarged one).
func _resting_hand_tile_size() -> Vector2:
	var vp := get_viewport_rect().size
	var available := Vector2(
		vp.x * (HAND_ANCHOR_RIGHT - HAND_ANCHOR_LEFT),
		vp.y * (HAND_ANCHOR_BOTTOM - HAND_UNFOCUSED_TOP))
	return _fit_tile_size(available, maxi(_hand_tiles.size(), 1), hand_row.get_theme_constant("separation"))


func _refresh_all() -> void:
	_resize_creature_rows()
	_resize_row(hand_row, _hand_tiles)

	var pile_size := _resting_hand_tile_size()
	deck_pile_button.custom_minimum_size = pile_size
	discard_pile_button.custom_minimum_size = pile_size

	for tile in _player_tiles:
		tile.refresh()
	for tile in _enemy_tiles:
		tile.refresh()

	energy_label.text = "Energy: %d/%d" % [battle.energy, BattleState.ENERGY_PER_TURN]
	deck_pile_button.set_count(battle.player_deck.size())
	discard_pile_button.set_count(battle.player_discard.size())

	if battle.is_over:
		hint_label.text = ""
	elif _pending_ability != null:
		hint_label.text = "Choose an enemy to target with %s" % _pending_ability.ability_name
	elif _pending_item != null:
		hint_label.text = "Choose a target for %s" % _pending_item.card_name
	elif not battle.is_player_turn:
		hint_label.text = "Enemy turn…"
	elif not _hand_focused:
		hint_label.text = "Tap your hand to play a card"
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
