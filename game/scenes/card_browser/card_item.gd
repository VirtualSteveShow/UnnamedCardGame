extends Control
## A single card thumbnail shown in the card browser grid.
##
## Deliberately NOT a Button: BaseButton calls accept_event() when it
## handles a press, which stops that input from bubbling up to the
## parent ScrollContainer -- so dragging to scroll never worked if the
## drag started on top of a card. This tracks press/release itself and
## only fires card_selected if the pointer didn't move past
## DRAG_CANCEL_DISTANCE between them, letting anything past that count
## as a scroll drag instead and fall through to the ScrollContainer.
## Same "touch slop" behavior any native scrollable list uses.

signal card_selected(card_data: CardData)

## How far (px, in this Control's local space) the pointer can move
## between press and release before it counts as a drag instead of a
## tap.
const DRAG_CANCEL_DISTANCE := 24.0

@onready var art_rect: ColorRect = $Art
@onready var name_label: Label = $NameLabel
@onready var level_label: Label = $LevelLabel
@onready var xp_bar: ProgressBar = $XpBar

var card_data: CardData

var _press_position := Vector2.ZERO
var _is_pressed := false


func setup(data: CardData) -> void:
	card_data = data
	art_rect.color = data.placeholder_color
	name_label.text = data.card_name
	level_label.text = "Lv %d" % data.level
	xp_bar.value = data.xp_progress * 100.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_press_position = event.position
		elif _is_pressed:
			_is_pressed = false
			if event.position.distance_to(_press_position) <= DRAG_CANCEL_DISTANCE:
				card_selected.emit(card_data)
	elif event is InputEventMouseMotion and _is_pressed:
		if event.position.distance_to(_press_position) > DRAG_CANCEL_DISTANCE:
			# Moved too far to still be a tap; stop tracking so a
			# release back near the start doesn't fire a stale click.
			_is_pressed = false
