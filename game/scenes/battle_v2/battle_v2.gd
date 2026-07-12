extends Control
## Hand-based combat prototype -- see docs/gameplay-notes.md's Experimental
## Mode section for the full design rationale. A deliberately separate
## scene from scenes/battle/battle.gd, sharing only generic sub-scenes
## (pile_button, battle_combatant_tile, battle_hand_card_tile) so the
## original battlefield combat prototype stays completely untouched and
## playable exactly as before.
##
## Enemy team is a fixed HP-based roster on the right, same as the
## original battle scene. There's no player creature row -- the player has
## a personal HP/block pool (PlayerPanel) instead, and enemies attack that
## directly. Every hand card is tapped directly with no "select a
## creature, then pick its ability" step:
##
## - Tap a creature card in hand -> discards it immediately and releases
##   one ability card per ability it has into your hand.
## - Tap a generated ability card -> if it deals damage, waits for an
##   enemy tap to target; if it's block-only, resolves immediately.
## - Tap an item card -> healing resolves immediately (targets the
##   player directly, there's no player creature to choose between
##   anymore); capture waits for an enemy tap to target.
##
## Entry point: the "Deck Battle (Prototype)" button in the card browser,
## separate from the original "Battle Test" button.

const CombatantTileScene := preload("res://scenes/battle/battle_combatant_tile.tscn")
const HandTileScene := preload("res://scenes/battle/battle_hand_card_tile.tscn")
const FieldMonsterTileScene := preload("res://scenes/battle_v2/field_monster_tile.tscn")

const DRAW_ANIM_DURATION := 0.35
const DRAW_ANIM_STAGGER := 0.1

## See battle.gd's identical constant for the full rationale: HandRow's
## rect is fixed at all times, only card size/interactivity change with
## focus, to avoid ever risking overlapping another row.
const HAND_SMALL_HEIGHT_FRACTION := 0.11

## Fixed deck/enemy roster for this prototype, mirroring battle.gd's own
## hardcoded test matchup -- no "build your deck" flow exists yet here
## either. Deliberately smaller than the original Battle Test's deck since
## every creature card now generates extra ability cards on top of itself.
const PLAYER_DECK_CREATURES := ["House Cat", "House Cat", "Family Dog", "Squirrel"]
const PLAYER_DECK_ITEMS := ["Cat Carrier", "Band-Aid", "Band-Aid"]

const ENEMY_TEAM_NAMES := ["Rabbit", "Robin", "Hamster"]

const MAX_LOG_LINES := 5

## How long the "monster pops out and attacks" flourish takes -- see
## _on_ability_played().
const ABILITY_POP_DURATION := 0.25
const ABILITY_POP_HOLD := 0.25

## How long a creature takes to fade/scale onto the field when played, and
## to slide/fade off when it flees -- see _on_creature_entered_field() /
## _on_creature_left_field().
const FIELD_ENTER_DURATION := 0.25
const FIELD_FLEE_DURATION := 0.3

@onready var player_panel := $PlayerPanel
@onready var field_row: VBoxContainer = $PlayerFieldRow
@onready var enemy_row: VBoxContainer = $EnemyRow
@onready var hand_row: HBoxContainer = $HandRow
@onready var hand_focus_catcher: Button = $HandFocusCatcher
@onready var hand_scrim: Button = $HandScrim
@onready var deck_pile_button := $PileRow/DeckPileButton
@onready var discard_pile_button := $PileRow/DiscardPileButton
@onready var log_label: Label = $LogLabel
@onready var hint_label: Label = $HintLabel
@onready var energy_label: Label = $EnergyLabel
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

var battle: BattleStateV2
var _log_lines: Array[String] = []

var _enemy_tiles: Array = []
var _hand_tiles: Array = []
var _field_tiles: Array = []

var _pending_ability_card: AbilityCardData = null
var _pending_item: ItemCardData = null

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

	battle = BattleStateV2.new(deck_cards, enemy_data)
	battle.log_message.connect(_on_log_message)
	battle.state_changed.connect(_on_state_changed)
	battle.cards_drawn.connect(_on_cards_drawn)
	battle.ability_played.connect(_on_ability_played)
	battle.creature_entered_field.connect(_on_creature_entered_field)
	battle.creature_left_field.connect(_on_creature_left_field)

	for combatant in battle.enemy_team:
		var tile := CombatantTileScene.instantiate()
		enemy_row.add_child(tile)
		_lock_tile_size(tile)
		tile.setup(combatant, true)
		tile.tapped.connect(_on_enemy_tile_tapped)
		_enemy_tiles.append(tile)

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	return_button.pressed.connect(_return_to_browser)
	result_return_button.pressed.connect(_return_to_browser)
	_lock_tile_size(deck_pile_button)
	deck_pile_button.set_label("DRAW PILE")
	deck_pile_button.tapped.connect(_on_deck_pile_tapped)
	_lock_tile_size(discard_pile_button)
	discard_pile_button.set_label("DISCARD PILE")
	discard_pile_button.tapped.connect(_on_discard_pile_tapped)
	pile_view_close_button.pressed.connect(func() -> void: pile_view_overlay.visible = false)
	hand_focus_catcher.pressed.connect(func() -> void: _set_hand_focused(true))
	hand_scrim.pressed.connect(func() -> void: _set_hand_focused(false))
	get_viewport().size_changed.connect(_refresh_all)

	battle.start_battle()
	_rebuild_hand_tiles()
	_refresh_all()


func _on_hand_card_tapped(card: BaseCardData) -> void:
	if not battle.can_play_card(card):
		return

	if card is CardData:
		battle.play_creature_card(card)
	elif card is AbilityCardData:
		if card.ability.damage > 0:
			_pending_item = null
			_pending_ability_card = card
			_refresh_all()
		else:
			battle.play_ability_card(card, null)
	elif card is ItemCardData:
		if card.item_type == ItemCardData.ItemType.HEALING:
			battle.play_item_card(card, null)
		else:
			_pending_ability_card = null
			_pending_item = card
			_refresh_all()


func _on_enemy_tile_tapped(combatant: BattleCombatant) -> void:
	if not combatant.is_alive():
		return
	if _pending_ability_card != null:
		battle.play_ability_card(_pending_ability_card, combatant)
		_pending_ability_card = null
	elif _pending_item != null:
		battle.play_item_card(_pending_item, combatant)
		_pending_item = null


func _on_end_turn_pressed() -> void:
	_pending_ability_card = null
	_pending_item = null
	battle.end_player_turn()


func _on_log_message(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func _on_cards_drawn(cards: Array) -> void:
	_pending_draw_cards.append_array(cards)


## Plays a brief "the monster pops out and attacks" flourish using the
## ability card's own art (already set to the source creature's battle
## sprite when the ability card was created) -- flies from the hand
## toward the target enemy tile (or hovers over the player panel for a
## block-only ability), then fades out. Purely cosmetic: fires from
## BattleStateV2.ability_played, which is emitted before the actual
## damage/log resolution, but this coroutine runs independently and
## doesn't block or delay that resolution.
func _on_ability_played(card: AbilityCardData, target: BattleCombatant) -> void:
	var start_pos: Vector2 = player_panel.global_position + player_panel.size / 2.0
	for tile in _field_tiles:
		if tile.source_creature == card.source_creature:
			start_pos = tile.global_position + tile.size / 2.0
			break

	var end_pos: Vector2 = start_pos
	if target != null:
		for tile in _enemy_tiles:
			if tile.combatant == target:
				end_pos = tile.global_position + tile.size / 2.0
				break

	var sprite := TextureRect.new()
	sprite.texture = card.art_texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	animation_layer.add_child(sprite)

	var small_size := Vector2(50, 50)
	var big_size := Vector2(280, 280)
	sprite.size = small_size
	sprite.global_position = start_pos - small_size / 2.0
	sprite.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(sprite, "size", big_size, ABILITY_POP_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "global_position", end_pos - big_size / 2.0, ABILITY_POP_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(ABILITY_POP_HOLD)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(sprite.queue_free)


## Adds a field tile for a newly played creature and fades it in --
## BattleStateV2.field_monsters is already updated by the time this
## fires, this is purely the visual side.
func _on_creature_entered_field(card: CardData) -> void:
	var tile := FieldMonsterTileScene.instantiate()
	field_row.add_child(tile)
	_lock_tile_size(tile)
	tile.setup(card)
	_field_tiles.append(tile)

	tile.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(tile, "modulate:a", 1.0, FIELD_ENTER_DURATION)

	_refresh_all()


## Removes the field tile for a creature whose ability cards are all gone
## from hand (played or discarded) -- fades and slides it out ("flees")
## rather than vanishing instantly. Reparents into animation_layer (a
## plain Control, not a container) before animating: the tile is dropped
## from _field_tiles first, so the very next _refresh_all() would resize
## the remaining field tiles and re-sort the container, which would fight
## a position/opacity tween running on a tile still parented inside it.
func _on_creature_left_field(card: CardData) -> void:
	var tile_to_remove = null
	for tile in _field_tiles:
		if tile.source_creature == card:
			tile_to_remove = tile
			break
	if tile_to_remove == null:
		return

	_field_tiles.erase(tile_to_remove)

	var global_pos: Vector2 = tile_to_remove.global_position
	var tile_size: Vector2 = tile_to_remove.size
	tile_to_remove.get_parent().remove_child(tile_to_remove)
	animation_layer.add_child(tile_to_remove)
	tile_to_remove.global_position = global_pos
	tile_to_remove.size = tile_size

	_refresh_all()

	var tween := create_tween()
	tween.tween_property(tile_to_remove, "modulate:a", 0.0, FIELD_FLEE_DURATION)
	tween.parallel().tween_property(tile_to_remove, "global_position:x", global_pos.x - 60, FIELD_FLEE_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(tile_to_remove.queue_free)


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
		_lock_tile_size(tile)
		tile.setup(card)
		tile.disabled = true

	pile_view_overlay.visible = true


func _set_hand_focused(focused: bool) -> void:
	if _hand_focused == focused:
		return
	_hand_focused = focused

	hand_focus_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE if focused else Control.MOUSE_FILTER_STOP

	hand_scrim.visible = focused
	hand_scrim.mouse_filter = Control.MOUSE_FILTER_STOP if focused else Control.MOUSE_FILTER_IGNORE

	_refresh_all()


func _on_state_changed() -> void:
	_remove_dead_enemy_tiles()
	_rebuild_hand_tiles()
	_refresh_all()


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
		_lock_tile_size(tile)
		tile.setup(card)
		tile.disabled = not battle.can_play_card(card)
		tile.set_selected(card == _pending_ability_card or card == _pending_item)
		tile.tapped.connect(_on_hand_card_tapped)
		_hand_tiles.append(tile)
		if card in cards_to_animate:
			tile.modulate.a = 0.0
			tiles_to_animate.append(tile)

	if not tiles_to_animate.is_empty():
		_animate_drawn_cards(tiles_to_animate)


func _animate_drawn_cards(tiles: Array) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	for i in tiles.size():
		var tile = tiles[i]
		if is_instance_valid(tile):
			_fly_card_from_deck(tile, i * DRAW_ANIM_STAGGER)


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


func _remove_dead_enemy_tiles() -> void:
	for i in range(_enemy_tiles.size() - 1, -1, -1):
		if not _enemy_tiles[i].combatant.is_alive():
			_enemy_tiles[i].queue_free()
			_enemy_tiles.remove_at(i)


## See battle.gd's identical helper for the full rationale: a Container
## stretches children to fill its cross-axis by default regardless of
## custom_minimum_size, so every dynamically created tile needs this to
## make custom_minimum_size actually authoritative.
func _lock_tile_size(tile: Control) -> void:
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER


## See battle.gd's identical helper for the full rationale (vertical_stack
## picks which axis the tile count divides).
func _fit_tile_size(available: Vector2, count: int, separation: float, vertical_stack: bool = false) -> Vector2:
	var tile_width: float
	var tile_height: float

	if vertical_stack:
		var height_from_count_limit: float = (available.y - separation * (count - 1)) / count
		var width_from_count_limit: float = height_from_count_limit * BaseCardData.ASPECT_RATIO

		var width_from_cross_limit: float = available.x
		var height_from_cross_limit: float = width_from_cross_limit / BaseCardData.ASPECT_RATIO

		if width_from_cross_limit <= width_from_count_limit:
			tile_width = width_from_cross_limit
			tile_height = height_from_cross_limit
		else:
			tile_width = width_from_count_limit
			tile_height = height_from_count_limit
	else:
		var height_from_cross_limit: float = available.y
		var width_from_cross_limit: float = height_from_cross_limit * BaseCardData.ASPECT_RATIO

		var width_from_count_limit: float = (available.x - separation * (count - 1)) / count
		var height_from_count_limit: float = width_from_count_limit / BaseCardData.ASPECT_RATIO

		if height_from_cross_limit <= height_from_count_limit:
			tile_height = height_from_cross_limit
			tile_width = width_from_cross_limit
		else:
			tile_width = width_from_count_limit
			tile_height = height_from_count_limit

	return Vector2(maxf(tile_width, 40.0), maxf(tile_height, 60.0))


func _resize_row(row: HBoxContainer, tiles: Array) -> void:
	if tiles.is_empty():
		return
	var separation: float = row.get_theme_constant("separation")
	var tile_size := _fit_tile_size(row.size, tiles.size(), separation)
	for tile in tiles:
		tile.custom_minimum_size = tile_size


func _resize_enemy_row() -> void:
	if _enemy_tiles.is_empty():
		return
	var tile_size := _fit_tile_size(
		enemy_row.size, _enemy_tiles.size(), enemy_row.get_theme_constant("separation"), true)
	for tile in _enemy_tiles:
		tile.custom_minimum_size = tile_size


func _resize_field_row() -> void:
	if _field_tiles.is_empty():
		return
	var tile_size := _fit_tile_size(
		field_row.size, _field_tiles.size(), field_row.get_theme_constant("separation"), true)
	for tile in _field_tiles:
		tile.custom_minimum_size = tile_size


func _small_hand_tile_size() -> Vector2:
	var h := get_viewport_rect().size.y * HAND_SMALL_HEIGHT_FRACTION
	return Vector2(h * BaseCardData.ASPECT_RATIO, h)


func _refresh_all() -> void:
	_resize_enemy_row()
	_resize_field_row()

	var pile_size := _small_hand_tile_size()
	if _hand_focused:
		_resize_row(hand_row, _hand_tiles)
	else:
		for tile in _hand_tiles:
			tile.custom_minimum_size = pile_size

	deck_pile_button.custom_minimum_size = pile_size
	discard_pile_button.custom_minimum_size = pile_size

	for tile in _enemy_tiles:
		tile.refresh()
	player_panel.refresh(battle.player_hp, battle.player_max_hp, battle.player_block)

	energy_label.text = "Energy: %d/%d" % [battle.energy, BattleStateV2.ENERGY_PER_TURN]
	deck_pile_button.set_count(battle.player_deck.size())
	discard_pile_button.set_count(battle.player_discard.size())

	if battle.is_over:
		hint_label.text = ""
	elif _pending_ability_card != null:
		hint_label.text = "Choose an enemy to target with %s" % _pending_ability_card.ability.ability_name
	elif _pending_item != null:
		hint_label.text = "Choose an enemy to target with %s" % _pending_item.card_name
	elif not battle.is_player_turn:
		hint_label.text = "Enemy turn…"
	elif not _hand_focused:
		hint_label.text = "Tap your hand to play a card"
	else:
		hint_label.text = "Play a monster to release its moves, or play a move card"

	for tile in _hand_tiles:
		tile.disabled = not battle.can_play_card(tile.card)
		tile.set_selected(tile.card == _pending_ability_card or tile.card == _pending_item)

	end_turn_button.disabled = not battle.is_player_turn or battle.is_over

	if battle.is_over:
		result_label.text = "You Won!" if battle.player_won else "You Lost..."
		result_overlay.visible = true


func _return_to_browser() -> void:
	get_tree().change_scene_to_file("res://scenes/card_browser/card_browser.tscn")
