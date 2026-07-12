extends Button
## Compact corner-icon draw/discard pile for the Deck Battle prototype --
## a small card-back + count, matching Slay the Spire's unobtrusive corner
## widgets instead of the original Battle Test's big labeled pile_button.
## Deliberately a separate scene so that mode's look stays untouched. Tap
## to open the same pile-view overlay pattern battle_v2.gd already has.

signal tapped

@onready var count_label: Label = $CountLabel

var _filled_style: StyleBoxFlat
var _empty_style: StyleBoxFlat


func _ready() -> void:
	pressed.connect(func() -> void: tapped.emit())
	_filled_style = get_theme_stylebox("normal").duplicate()
	_empty_style = _filled_style.duplicate()
	_empty_style.bg_color = Color(1, 1, 1, 0.05)
	_empty_style.border_color = Color(1, 1, 1, 0.3)


func set_count(n: int) -> void:
	var is_empty := n <= 0
	count_label.text = str(n)
	add_theme_stylebox_override("normal", _empty_style if is_empty else _filled_style)
