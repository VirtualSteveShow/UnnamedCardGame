class_name SlashEffect
extends Control
## Hit-impact visual drawn over a struck combatant's tile -- a tapered
## diagonal slash stroke that sweeps in (progress 0 -> 1), holds a beat,
## then fades out, paired with a tile shake driven by battle_v2.gd. The
## default hit animation for damaging abilities (CardAbility.hit_animation
## == "slash"); other ability-specific hit animations will join it later.
## Created directly via .new() (no .tscn) since it's just a _draw() shape,
## same as ArcIndicator.

const SLASH_WIDTH := 16.0
## Bright near-white core so it reads over both dark City and bright
## Suburbs tiles.
const SLASH_COLOR := Color(1.0, 0.96, 0.88, 0.95)
const SLASH_COLOR_EDGE := Color(1.0, 0.55, 0.3, 0.85)

## How far the slash tip has swept from its start corner toward its end
## corner, 0-1. Tweened by battle_v2.gd; each step redraws.
var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if progress <= 0.0:
		return

	# Top-right to bottom-left, inset from the tile edges so the stroke
	# reads as cutting across the creature, not the whole UI tile.
	var from := Vector2(size.x * 0.82, size.y * 0.12)
	var to := Vector2(size.x * 0.18, size.y * 0.88)
	var tip := from.lerp(to, progress)

	_draw_tapered_stroke(from, tip, SLASH_WIDTH * 1.6, SLASH_COLOR_EDGE)
	_draw_tapered_stroke(from, tip, SLASH_WIDTH, SLASH_COLOR)


## A polygon that's pointed at both ends and widest in the middle -- reads
## as a blade arc rather than a uniform line.
func _draw_tapered_stroke(from: Vector2, tip: Vector2, width: float, color: Color) -> void:
	if from.distance_to(tip) < 1.0:
		return
	var dir := (tip - from).normalized()
	var perp := Vector2(-dir.y, dir.x)

	const STEPS := 12
	var side_a := PackedVector2Array()
	var side_b := PackedVector2Array()
	for i in STEPS + 1:
		var t := float(i) / float(STEPS)
		var point := from.lerp(tip, t)
		var half_width := width * 0.5 * sin(PI * t)
		side_a.append(point + perp * half_width)
		side_b.append(point - perp * half_width)

	side_b.reverse()
	draw_colored_polygon(side_a + side_b, color)
