extends Panel
## Shows the player's personal HP/block pool in the hand-based combat
## prototype (BattleStateV2) -- replaces the player creature column from
## the original battle scene, since the player no longer fields creatures
## with their own HP; the player IS the thing enemies attack now.
##
## Styled to match Slay the Spire: no boxed background, a big sprite, and
## a slim HP bar directly under it -- always red, not color-by-percentage
## (Slay the Spire's own HP bars are always red for both player and
## enemies; only this project's OTHER, non-StS-styled tiles use a
## green/yellow/red scheme).

@onready var art_rect: TextureRect = $Art
@onready var hp_bar: ProgressBar = $HpBar
@onready var status_label: Label = $StatusLabel

var _hp_bg_style: StyleBoxFlat
var _hp_fill_style: StyleBoxFlat

const HP_COLOR := Color(0.8, 0.2, 0.2)


func _ready() -> void:
	IdleBob.start(art_rect)

	_hp_bg_style = StyleBoxFlat.new()
	_hp_bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	_hp_bg_style.corner_radius_top_left = 4
	_hp_bg_style.corner_radius_top_right = 4
	_hp_bg_style.corner_radius_bottom_left = 4
	_hp_bg_style.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("background", _hp_bg_style)

	_hp_fill_style = StyleBoxFlat.new()
	_hp_fill_style.bg_color = HP_COLOR
	_hp_fill_style.corner_radius_top_left = 4
	_hp_fill_style.corner_radius_top_right = 4
	_hp_fill_style.corner_radius_bottom_left = 4
	_hp_fill_style.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("fill", _hp_fill_style)


func refresh(hp: int, max_hp: int, block: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp

	var text := "%d/%d HP" % [hp, max_hp]
	if block > 0:
		text += "  ·  Block %d" % block
	status_label.text = text
