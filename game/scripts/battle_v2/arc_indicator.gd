class_name ArcIndicator
extends Control
## Targeting-arc visual for the arc-drag card-play gesture (see
## battle_v2.gd's _begin_arc/_update_arc) -- a curved line with an
## arrowhead from the source card to the pointer. Colored gold while
## aiming and green once a valid target is under the pointer, so the
## player gets feedback on whether releasing here will actually play the
## card. Created directly via .new() (no .tscn) since it's just a _draw()
## shape, matching how battle_v2.gd already builds the ability-pop sprite
## in code.

const LINE_WIDTH := 6.0
const ARROW_SIZE := 20.0
const CURVE_HEIGHT := 70.0
const SEGMENTS := 24

const COLOR_AIMING := Color(1.0, 0.85, 0.3, 0.9)
const COLOR_VALID := Color(0.35, 0.9, 0.4, 0.95)

var _start_point: Vector2 = Vector2.ZERO
var _end_point: Vector2 = Vector2.ZERO
var _valid := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_points(from: Vector2, to: Vector2) -> void:
	_start_point = from
	_end_point = to
	queue_redraw()


func set_valid(is_valid: bool) -> void:
	if _valid == is_valid:
		return
	_valid = is_valid
	queue_redraw()


func _draw() -> void:
	if _start_point.distance_to(_end_point) < 1.0:
		return

	# A cubic bezier with both control points pulled up to the same spot
	# degenerates into a single symmetric hump -- enough to read as an
	# "arc" without needing true quadratic bezier support.
	var control_point: Vector2 = (_start_point + _end_point) / 2.0 - Vector2(0, CURVE_HEIGHT)
	var points := PackedVector2Array()
	for i in SEGMENTS + 1:
		var t := float(i) / float(SEGMENTS)
		points.append(_start_point.bezier_interpolate(control_point, control_point, _end_point, t))

	var color := COLOR_VALID if _valid else COLOR_AIMING
	draw_polyline(points, color, LINE_WIDTH, true)

	var tip_dir: Vector2 = (points[SEGMENTS] - points[SEGMENTS - 1]).normalized()
	var perp := Vector2(-tip_dir.y, tip_dir.x)
	var tip: Vector2 = _end_point
	var left: Vector2 = tip - tip_dir * ARROW_SIZE + perp * ARROW_SIZE * 0.5
	var right: Vector2 = tip - tip_dir * ARROW_SIZE - perp * ARROW_SIZE * 0.5
	draw_colored_polygon(PackedVector2Array([tip, left, right]), color)
