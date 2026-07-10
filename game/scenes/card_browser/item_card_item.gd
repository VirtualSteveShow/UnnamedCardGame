extends Control
## A single item/action card thumbnail shown in the card browser grid.
##
## Same tap-vs-drag handling as card_item.gd (see that file's header for
## why event.global_position is used and why this isn't a Button) --
## items sit in the same scrollable grid as creature cards, so they need
## the same "don't block scrolling" behavior. The only real difference
## from a creature tile is what's displayed: no level badge or XP bar,
## since items don't level up.

signal item_selected(item_data: ItemCardData)
signal drag_scrolled(delta: Vector2)

const DRAG_CANCEL_DISTANCE := 24.0

@onready var art_rect: TextureRect = $Art
@onready var name_label: Label = $NameLabel

var item_data: ItemCardData

var _press_position := Vector2.ZERO
var _last_position := Vector2.ZERO
var _is_pressed := false
var _is_dragging := false


func setup(data: ItemCardData) -> void:
	item_data = data
	art_rect.texture = data.get_display_texture()
	name_label.text = data.card_name


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_is_dragging = false
			_press_position = event.global_position
			_last_position = event.global_position
		elif _is_pressed:
			_is_pressed = false
			if not _is_dragging:
				item_selected.emit(item_data)
			_is_dragging = false
	elif event is InputEventMouseMotion and _is_pressed:
		if not _is_dragging and event.global_position.distance_to(_press_position) > DRAG_CANCEL_DISTANCE:
			_is_dragging = true
		if _is_dragging:
			drag_scrolled.emit(event.global_position - _last_position)
		_last_position = event.global_position
