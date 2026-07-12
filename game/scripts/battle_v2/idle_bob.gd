class_name IdleBob
extends RefCounted
## Shared looping bob/squash idle animation for battle art, applied to a
## Control (usually a TextureRect) via a looping Tween. Reused by the
## player panel, enemy tiles, and field creature tiles so their idle
## motion feels consistent without duplicating the tween setup three
## times. Purely cosmetic -- doesn't touch layout-critical properties
## like size or anchors, only position/scale on top of whatever layout
## already placed the node at.

const BOB_HEIGHT := 5.0
const BOB_DURATION := 1.1
const SQUASH_AMOUNT := 0.04


## Starts the loop on `target`. Safe to call before the node's first
## layout pass -- pivot_offset (needed so the squash anchors at the
## node's center rather than its top-left corner) is kept in sync via
## the resized signal instead of being computed once up front, since
## `target.size` isn't reliable yet inside most callers' _ready().
static func start(target: Control) -> void:
	_update_pivot(target)
	target.resized.connect(_update_pivot.bind(target))

	var base_pos: Vector2 = target.position
	var base_scale: Vector2 = target.scale
	# Randomized start delay so multiple creatures on screen don't bob in
	# lockstep.
	var phase := randf() * BOB_DURATION

	var tween := target.create_tween()
	tween.set_loops()
	tween.tween_interval(phase)
	tween.tween_property(target, "position:y", base_pos.y - BOB_HEIGHT, BOB_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(target, "scale", base_scale * Vector2(1.0 - SQUASH_AMOUNT, 1.0 + SQUASH_AMOUNT), BOB_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "position:y", base_pos.y, BOB_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(target, "scale", base_scale, BOB_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


static func _update_pivot(target: Control) -> void:
	target.pivot_offset = target.size / 2.0
