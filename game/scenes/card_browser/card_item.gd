extends Control
## A single card thumbnail shown in the card browser grid.
##
## Deliberately NOT a Button, and deliberately does NOT rely on the
## touch/drag reaching the parent ScrollContainer on its own (that
## turned out to be unreliable in practice). Instead this tracks
## press/motion/release itself: small movement counts as a tap
## (card_selected), anything past DRAG_CANCEL_DISTANCE counts as a
## scroll drag and is forwarded frame-by-frame via drag_scrolled so
## card_browser.gd can scroll the list on our behalf. Same "touch slop"
## behavior any native scrollable list uses.

signal card_selected(card_data: CardData)
## Emitted with the pointer's movement (this frame) once a press has
## moved past DRAG_CANCEL_DISTANCE, so the browser can apply it to the
## ScrollContainer directly.
signal drag_scrolled(delta: Vector2)

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
var _last_position := Vector2.ZERO
var _is_pressed := false
var _is_dragging := false


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
			_is_dragging = false
			_press_position = event.position
			_last_position = event.position
		elif _is_pressed:
			_is_pressed = false
			if not _is_dragging:
				card_selected.emit(card_data)
			_is_dragging = false
	elif event is InputEventMouseMotion and _is_pressed:
		if not _is_dragging and event.position.distance_to(_press_position) > DRAG_CANCEL_DISTANCE:
			_is_dragging = true
		if _is_dragging:
			drag_scrolled.emit(event.position - _last_position)
		_last_position = event.position
