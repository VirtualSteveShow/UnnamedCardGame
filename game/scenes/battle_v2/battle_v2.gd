extends Control
## Hand-based combat prototype, restyled to closely match Slay the
## Spire's actual UI/interaction -- see docs/gameplay-notes.md's
## Experimental Mode section for the full design rationale. A
## deliberately separate scene from scenes/battle/battle.gd; even the
## tile sub-scenes are now battle_v2-specific (hand_card_tile_v2,
## enemy_tile_v2, energy_orb, corner_pile_button, hex_end_turn_button)
## rather than reusing the original's, so that mode's look and behavior
## stay completely untouched.
##
## Interaction model: press-and-drag, not tap-tap. Pressing a hand card
## lifts it (enlarged, straightened, with a description tooltip);
## dragging it onto an enemy tile plays it targeting that enemy (for
## damaging abilities/capture items); dragging a non-targeted card (a
## creature card, a block-only ability, a healing item) up above the
## hand releases it; releasing anywhere else snaps it back to the hand.
## Handled via a global _input() override rather than per-tile gui_input,
## since gui_input stops firing once the pointer leaves a control's own
## bounds -- not workable for a drag gesture that ranges across the
## whole screen.

const HandCardTileV2Scene := preload("res://scenes/battle_v2/hand_card_tile_v2.tscn")
const EnemyTileV2Scene := preload("res://scenes/battle_v2/enemy_tile_v2.tscn")
const FieldMonsterTileScene := preload("res://scenes/battle_v2/field_monster_tile.tscn")

const DRAW_ANIM_DURATION := 0.35
const DRAW_ANIM_STAGGER := 0.1

const PLAYER_DECK_CREATURES := ["House Cat", "House Cat", "Family Dog", "Squirrel"]
const PLAYER_DECK_ITEMS := ["Cat Carrier", "Band-Aid", "Band-Aid"]

const ENEMY_TEAM_NAMES := ["Rabbit", "Robin", "Hamster"]

const MAX_LOG_LINES := 3

const ABILITY_POP_DURATION := 0.25
const ABILITY_POP_HOLD := 0.25

const FIELD_ENTER_DURATION := 0.25
const FIELD_FLEE_DURATION := 0.3

## Fan layout tuning: how wide a hand card is (fraction of viewport
## width), how far each card rotates at the extremes of the hand, how
## much the outer cards lift relative to the center, and how much each
## card overlaps the last (fraction of card width per step).
const HAND_CARD_WIDTH_FRACTION := 0.085
const HAND_MAX_ROTATION_DEG := 12.0
const HAND_ARC_LIFT := 26.0
const HAND_OVERLAP := 0.62

## Drag gesture tuning: how far the pointer must move from the press
## point before it counts as an actual drag (vs. a tap-to-preview that
## snaps back), and the lifted/dragged card's scale relative to its
## resting size.
const DRAG_THRESHOLD := 14.0
const DRAG_LIFT_SCALE := 1.35

@onready var player_panel := $PlayerPanel
@onready var field_row: VBoxContainer = $PlayerFieldRow
@onready var enemy_row: VBoxContainer = $EnemyRow
@onready var hand_area: Control = $HandArea
@onready var energy_orb := $EnergyOrb
@onready var draw_pile_button := $DrawPileButton
@onready var discard_pile_button := $DiscardPileButton
@onready var end_turn_button := $HexEndTurnButton
@onready var log_label: Label = $LogLabel
@onready var hint_label: Label = $HintLabel
@onready var return_button: Button = $ReturnButton
@onready var animation_layer: Control = $AnimationLayer

@onready var tooltip_panel: Panel = $CardTooltip
@onready var tooltip_title_label: Label = $CardTooltip/TitleLabel
@onready var tooltip_desc_label: Label = $CardTooltip/DescLabel

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

var _pending_draw_cards: Array = []

## Drag state -- see _try_start_drag/_update_drag/_end_drag.
var _drag_tile: Control = null
var _drag_started: bool = false
var _drag_start_pointer: Vector2 = Vector2.ZERO


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
		var tile := EnemyTileV2Scene.instantiate()
		enemy_row.add_child(tile)
		_lock_tile_size(tile)
		tile.setup(combatant)
		_enemy_tiles.append(tile)

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	return_button.pressed.connect(_return_to_browser)
	result_return_button.pressed.connect(_return_to_browser)
	draw_pile_button.tapped.connect(_on_deck_pile_tapped)
	discard_pile_button.tapped.connect(_on_discard_pile_tapped)
	pile_view_close_button.pressed.connect(func() -> void: pile_view_overlay.visible = false)
	get_viewport().size_changed.connect(_on_viewport_resized)

	tooltip_panel.visible = false

	battle.start_battle()
	_rebuild_hand_tiles()
	_refresh_all()


func _on_viewport_resized() -> void:
	_layout_hand()
	_refresh_all()


## Global input handling for the drag-to-play gesture -- see the class
## doc comment for why this can't just be per-tile gui_input.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_drag(event.position)
		elif _drag_tile != null:
			_end_drag(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _drag_tile != null:
		_update_drag(event.position)
		get_viewport().set_input_as_handled()


func _try_start_drag(pointer_pos: Vector2) -> void:
	if _drag_tile != null:
		return
	for i in range(_hand_tiles.size() - 1, -1, -1):
		var tile = _hand_tiles[i]
		if tile.disabled:
			continue
		if tile.get_global_rect().has_point(pointer_pos):
			_start_drag(tile, pointer_pos)
			get_viewport().set_input_as_handled()
			return


## Reparents the tile into animation_layer (declared after everything
## else in the scene tree) for the duration of the drag -- z_index alone
## isn't reliable for making a HandArea child render above a LATER
## sibling subtree like EnergyOrb or the pile buttons, since sibling
## subtree draw order is primarily tree-order-based in Godot, not purely
## z_index-based. Reparented back to hand_area on snap-back (see
## _snap_back); if the card gets played instead, it's simply queue_free()'d
## from wherever it currently lives when _rebuild_hand_tiles() runs.
func _start_drag(tile: Control, pointer_pos: Vector2) -> void:
	_drag_tile = tile
	_drag_started = false
	_drag_start_pointer = pointer_pos

	var pos_before_reparent: Vector2 = tile.global_position
	tile.get_parent().remove_child(tile)
	animation_layer.add_child(tile)
	tile.global_position = pos_before_reparent

	var lift_size := _hand_card_size() * DRAG_LIFT_SCALE
	tile.pivot_offset = lift_size / 2.0
	var tween := create_tween()
	tween.tween_property(tile, "size", lift_size, 0.12)
	tween.parallel().tween_property(tile, "rotation_degrees", 0.0, 0.12)
	tween.parallel().tween_property(tile, "global_position", pointer_pos - lift_size / 2.0, 0.12)

	_show_tooltip(tile.card, pointer_pos)


func _update_drag(pointer_pos: Vector2) -> void:
	if _drag_tile == null:
		return
	if not _drag_started and pointer_pos.distance_to(_drag_start_pointer) > DRAG_THRESHOLD:
		_drag_started = true
	var lift_size := _hand_card_size() * DRAG_LIFT_SCALE
	_drag_tile.global_position = pointer_pos - lift_size / 2.0
	_position_tooltip(pointer_pos)


func _end_drag(pointer_pos: Vector2) -> void:
	var tile := _drag_tile
	_drag_tile = null
	_hide_tooltip()
	if tile == null or not is_instance_valid(tile):
		return

	var card: BaseCardData = tile.card
	var needs_target := _card_needs_target(card)
	var played := false

	if needs_target:
		var target := _find_enemy_target_at(pointer_pos)
		if target != null:
			played = _resolve_card_play(card, target)
	elif _drag_started and pointer_pos.y < hand_area.get_global_rect().position.y:
		played = _resolve_card_play(card, null)

	if not played:
		_snap_back(tile)


func _find_enemy_target_at(pointer_pos: Vector2) -> BattleCombatant:
	for tile in _enemy_tiles:
		if tile.combatant.is_alive() and tile.get_global_rect().has_point(pointer_pos):
			return tile.combatant
	return null


func _card_needs_target(card: BaseCardData) -> bool:
	if card is AbilityCardData:
		return card.ability.damage > 0
	if card is ItemCardData:
		return card.item_type == ItemCardData.ItemType.CAPTURE
	return false


func _resolve_card_play(card: BaseCardData, target: BattleCombatant) -> bool:
	if not battle.can_play_card(card):
		return false
	if card is CardData:
		battle.play_creature_card(card)
		return true
	elif card is AbilityCardData:
		if card.ability.damage > 0 and target == null:
			return false
		battle.play_ability_card(card, target)
		return true
	elif card is ItemCardData:
		if card.item_type == ItemCardData.ItemType.CAPTURE and target == null:
			return false
		battle.play_item_card(card, target)
		return true
	return false


func _snap_back(tile: Control) -> void:
	var rest_size := _hand_card_size()
	var rest_pos: Vector2 = tile.get_meta("rest_position", tile.position)
	var rest_rot: float = tile.get_meta("rest_rotation", 0.0)

	var tween := create_tween()
	tween.tween_property(tile, "global_position", hand_area.global_position + rest_pos, 0.15) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(tile, "size", rest_size, 0.15)
	tween.parallel().tween_property(tile, "rotation_degrees", rest_rot, 0.15)
	tween.tween_callback(func() -> void:
		if not is_instance_valid(tile):
			return
		tile.pivot_offset = Vector2(rest_size.x / 2.0, rest_size.y * 1.1)
		var pos_before_reparent: Vector2 = tile.global_position
		tile.get_parent().remove_child(tile)
		hand_area.add_child(tile)
		tile.global_position = pos_before_reparent
		tile.position = rest_pos
	)


func _show_tooltip(card: BaseCardData, near_pointer: Vector2) -> void:
	tooltip_title_label.text = card.card_name
	tooltip_desc_label.text = _describe_card(card)
	tooltip_panel.visible = true
	_position_tooltip(near_pointer)


func _position_tooltip(near_pointer: Vector2) -> void:
	tooltip_panel.global_position = near_pointer + Vector2(90, -160)


func _hide_tooltip() -> void:
	tooltip_panel.visible = false


func _describe_card(card: BaseCardData) -> String:
	if card is AbilityCardData:
		var parts: Array[String] = []
		if card.ability.damage > 0:
			parts.append("Deal %d damage." % card.ability.damage)
		if card.ability.block > 0:
			parts.append("Gain %d Block." % card.ability.block)
		return "\n".join(parts)
	elif card is CardData:
		return "Releases %d move card(s) into your hand." % card.abilities.size()
	elif card is ItemCardData:
		return card.description
	return ""


func _on_end_turn_pressed() -> void:
	battle.end_player_turn()


func _on_log_message(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func _on_cards_drawn(cards: Array) -> void:
	_pending_draw_cards.append_array(cards)


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
		var tile := HandCardTileV2Scene.instantiate()
		pile_view_grid.add_child(tile)
		tile.setup(card)
		tile.set_disabled(true)

	pile_view_overlay.visible = true


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

	for card in battle.player_hand:
		var tile := HandCardTileV2Scene.instantiate()
		hand_area.add_child(tile)
		tile.setup(card)
		tile.set_disabled(not battle.can_play_card(card))
		_hand_tiles.append(tile)

	_layout_hand()

	var tiles_to_animate: Array = []
	for tile in _hand_tiles:
		if tile.card in cards_to_animate:
			tile.modulate.a = 0.0
			tiles_to_animate.append(tile)

	if not tiles_to_animate.is_empty():
		_animate_drawn_cards(tiles_to_animate)


## Fans every hand tile out from a bottom-center pivot: rotation and a
## slight upward arc both increase toward the edges of the hand. Cards
## currently mid-drag are skipped (their position is driven by the drag
## gesture instead) -- each tile's computed resting transform is also
## cached via set_meta so _snap_back can return a released-but-not-played
## card to exactly the right spot without needing to recompute the whole
## layout.
func _layout_hand() -> void:
	var count := _hand_tiles.size()
	if count == 0:
		return

	var card_size := _hand_card_size()
	var step := card_size.x * HAND_OVERLAP
	var total_width := step * (count - 1) + card_size.x
	var start_x := (hand_area.size.x - total_width) / 2.0

	for i in count:
		var tile = _hand_tiles[i]
		var t := 0.0 if count == 1 else (float(i) / float(count - 1)) * 2.0 - 1.0
		var angle_deg := t * HAND_MAX_ROTATION_DEG
		var arc_lift := HAND_ARC_LIFT * (t * t)
		var pos := Vector2(start_x + i * step, hand_area.size.y - card_size.y - arc_lift)

		tile.set_meta("rest_position", pos)
		tile.set_meta("rest_rotation", angle_deg)

		if tile == _drag_tile:
			continue

		tile.size = card_size
		tile.pivot_offset = Vector2(card_size.x / 2.0, card_size.y * 1.1)
		tile.position = pos
		tile.rotation_degrees = angle_deg
		tile.z_index = i


func _hand_card_size() -> Vector2:
	var w := get_viewport_rect().size.x * HAND_CARD_WIDTH_FRACTION
	return Vector2(w, w / BaseCardData.ASPECT_RATIO)


func _animate_drawn_cards(tiles: Array) -> void:
	for i in tiles.size():
		var tile = tiles[i]
		if is_instance_valid(tile):
			_fly_card_from_deck(tile, i * DRAW_ANIM_STAGGER)


func _fly_card_from_deck(tile: Control, delay: float) -> void:
	var ghost := HandCardTileV2Scene.instantiate()
	animation_layer.add_child(ghost)
	ghost.setup(tile.card)
	ghost.set_disabled(true)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.size = tile.size
	ghost.rotation_degrees = tile.rotation_degrees

	var target_pos: Vector2 = tile.global_position
	var target_size: Vector2 = tile.size
	var start_size: Vector2 = target_size * 0.3
	var start_pos: Vector2 = draw_pile_button.global_position \
		+ draw_pile_button.size / 2.0 - start_size / 2.0

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


## See the original battle.gd's identical helper for the full rationale:
## a Container stretches children to fill its cross-axis by default
## regardless of custom_minimum_size, so enemy/field tiles (still
## Container-managed, unlike the manually-positioned hand) need this to
## make custom_minimum_size authoritative.
func _lock_tile_size(tile: Control) -> void:
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER


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


func _refresh_all() -> void:
	_resize_enemy_row()
	_resize_field_row()

	for tile in _enemy_tiles:
		tile.refresh()
	player_panel.refresh(battle.player_hp, battle.player_max_hp, battle.player_block)

	energy_orb.set_energy(battle.energy, BattleStateV2.ENERGY_PER_TURN)
	draw_pile_button.set_count(battle.player_deck.size())
	discard_pile_button.set_count(battle.player_discard.size())

	if battle.is_over:
		hint_label.text = ""
	elif not battle.is_player_turn:
		hint_label.text = "Enemy turn…"
	else:
		hint_label.text = "Drag a card onto an enemy to attack, or drag it up to play"

	for tile in _hand_tiles:
		tile.set_disabled(not battle.can_play_card(tile.card))

	end_turn_button.disabled = not battle.is_player_turn or battle.is_over

	if battle.is_over:
		result_label.text = "You Won!" if battle.player_won else "You Lost..."
		result_overlay.visible = true


func _return_to_browser() -> void:
	get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")
