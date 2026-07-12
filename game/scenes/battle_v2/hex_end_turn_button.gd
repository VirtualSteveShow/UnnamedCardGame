extends Control
## Custom-drawn hexagonal "End Turn" button approximating Slay the
## Spire's end-turn button shape. Godot's StyleBoxFlat only supports
## rounded rectangles, not angled/hex corners, so this draws its own
## polygon rather than using a Button + theme override.

signal pressed

@export var button_text: String = "End Turn":
	set(value):
		button_text = value
		queue_redraw()

@export var disabled: bool = false:
	set(value):
		disabled = value
		queue_redraw()

const FILL_COLOR := Color(0.55, 0.42, 0.18, 1.0)
const DISABLED_COLOR := Color(0.3, 0.3, 0.32, 1.0)
const BORDER_COLOR := Color(0.85, 0.7, 0.35, 1.0)

var _pressed_down := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var points := _hexagon_points(size)
	var fill := DISABLED_COLOR if disabled else FILL_COLOR
	if _pressed_down and not disabled:
		fill = fill.lightened(0.15)
	draw_colored_polygon(points, fill)
	for i in points.size():
		draw_line(points[i], points[(i + 1) % points.size()], BORDER_COLOR, 3.0, true)

	var font := ThemeDB.fallback_font
	var font_size := 22
	var text_size := font.get_string_size(button_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := (size - text_size) / 2.0 + Vector2(0, text_size.y * 0.75)
	draw_string(font, text_pos, button_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size,
		Color.WHITE if not disabled else Color(0.6, 0.6, 0.6))


## Flat-top, elongated hexagon inscribed in the control's own rect.
func _hexagon_points(rect_size: Vector2) -> PackedVector2Array:
	var w := rect_size.x
	var h := rect_size.y
	var notch := w * 0.18
	return PackedVector2Array([
		Vector2(notch, 0),
		Vector2(w - notch, 0),
		Vector2(w, h / 2.0),
		Vector2(w - notch, h),
		Vector2(notch, h),
		Vector2(0, h / 2.0),
	])


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed_down = true
			queue_redraw()
		elif _pressed_down:
			_pressed_down = false
			queue_redraw()
			pressed.emit()
