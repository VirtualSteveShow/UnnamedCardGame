extends Control
## Slim Slay-the-Spire-style enemy tile for the Deck Battle prototype --
## sprite with a thin HP bar directly underneath, no boxed name/HP panel.
## Deliberately a separate scene from the shared battle_combatant_tile
## (used by the original Battle Test) so that mode's look stays untouched.
##
## No tap interaction -- targeting is drag-and-drop (see battle_v2.gd),
## which checks get_global_rect() against the drag position directly
## rather than relying on Godot's own input routing.

@onready var art_rect: TextureRect = $Art
@onready var name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HpBar
@onready var hp_label: Label = $HpBar/HpLabel

var combatant: BattleCombatant

var _hp_bg_style: StyleBoxFlat
var _hp_fill_style: StyleBoxFlat

## Slay the Spire's enemy HP bars are always red regardless of
## percentage remaining (only the player's own resources use a
## color-by-percentage scheme) -- matched here rather than reusing the
## green/yellow/red logic the other tiles use.
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


func setup(c: BattleCombatant) -> void:
	combatant = c
	art_rect.texture = c.data.get_battle_texture()
	art_rect.flip_h = true
	name_label.text = c.data.card_name
	refresh()


func refresh() -> void:
	hp_bar.max_value = combatant.data.max_health
	hp_bar.value = combatant.current_hp
	hp_label.text = "%d/%d" % [maxi(combatant.current_hp, 0), combatant.data.max_health]
	var alive := combatant.is_alive()
	modulate = Color.WHITE if alive else Color(0.35, 0.35, 0.35)
