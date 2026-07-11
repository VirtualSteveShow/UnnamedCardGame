extends Panel
## Shows the player's personal HP/block pool in the hand-based combat
## prototype (BattleStateV2) -- replaces the player creature column from
## the original battle scene, since the player no longer fields creatures
## with their own HP; the player IS the thing enemies attack now.

@onready var hp_bar: ProgressBar = $HpBar
@onready var status_label: Label = $StatusLabel

var _hp_bg_style: StyleBoxFlat
var _hp_fill_style: StyleBoxFlat

const HP_COLOR_HIGH := Color(0.3, 0.8, 0.3)
const HP_COLOR_MID := Color(0.9, 0.75, 0.2)
const HP_COLOR_LOW := Color(0.85, 0.25, 0.25)


func _ready() -> void:
	_hp_bg_style = StyleBoxFlat.new()
	_hp_bg_style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	_hp_bg_style.corner_radius_top_left = 6
	_hp_bg_style.corner_radius_top_right = 6
	_hp_bg_style.corner_radius_bottom_left = 6
	_hp_bg_style.corner_radius_bottom_right = 6
	_hp_bg_style.border_width_left = 2
	_hp_bg_style.border_width_right = 2
	_hp_bg_style.border_width_top = 2
	_hp_bg_style.border_width_bottom = 2
	_hp_bg_style.border_color = Color(0, 0, 0, 0.8)
	hp_bar.add_theme_stylebox_override("background", _hp_bg_style)

	_hp_fill_style = StyleBoxFlat.new()
	_hp_fill_style.corner_radius_top_left = 6
	_hp_fill_style.corner_radius_top_right = 6
	_hp_fill_style.corner_radius_bottom_left = 6
	_hp_fill_style.corner_radius_bottom_right = 6
	hp_bar.add_theme_stylebox_override("fill", _hp_fill_style)


func refresh(hp: int, max_hp: int, block: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp

	var hp_fraction := float(hp) / float(max_hp)
	if hp_fraction > 0.6:
		_hp_fill_style.bg_color = HP_COLOR_HIGH
	elif hp_fraction > 0.25:
		_hp_fill_style.bg_color = HP_COLOR_MID
	else:
		_hp_fill_style.bg_color = HP_COLOR_LOW

	var text := "%d/%d HP" % [hp, max_hp]
	if block > 0:
		text += "  ·  Block %d" % block
	status_label.text = text
