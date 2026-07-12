extends Control
## Slay-the-Spire-styled hand card tile for the Deck Battle prototype --
## rounded card, border color-coded by inferred type, circular energy-cost
## badge, art, name banner, type label. Deliberately a separate scene from
## the shared battle_hand_card_tile (used by the original Battle Test) so
## that mode's look and behavior stay completely untouched.
##
## A plain Control, not a Button -- battle_v2.gd owns all input
## interpretation (lift-to-preview, drag-to-target) via this node's
## built-in `gui_input` signal, and drives this tile's position/scale/
## rotation directly during a drag. This scene only knows how to display
## a card and report raw input, nothing about game rules.

@onready var card_panel: Panel = $CardPanel
@onready var cost_badge: Panel = $CostBadge
@onready var cost_label: Label = $CostBadge/CostLabel
@onready var art_rect: TextureRect = $Art
@onready var name_label: Label = $NameLabel
@onready var type_label: Label = $TypeLabel

var card: BaseCardData
var disabled: bool = false

const COLOR_ATTACK := Color(0.75, 0.18, 0.16)
const COLOR_SKILL := Color(0.18, 0.45, 0.78)
const COLOR_MONSTER := Color(0.22, 0.62, 0.28)
const COLOR_ITEM := Color(0.7, 0.55, 0.22)

var _border_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_border_style = card_panel.get_theme_stylebox("panel").duplicate()
	card_panel.add_theme_stylebox_override("panel", _border_style)


func setup(c: BaseCardData) -> void:
	card = c
	art_rect.texture = c.get_display_texture()
	name_label.text = c.card_name
	cost_label.text = str(c.energy_cost)

	var border_color: Color
	var type_text: String
	if c is AbilityCardData:
		if c.ability.damage > 0:
			border_color = COLOR_ATTACK
			type_text = "Attack"
		else:
			border_color = COLOR_SKILL
			type_text = "Skill"
	elif c is CardData:
		border_color = COLOR_MONSTER
		type_text = "Monster"
	else:
		border_color = COLOR_ITEM
		type_text = "Item"

	_border_style.border_color = border_color
	type_label.text = type_text
	type_label.add_theme_color_override("font_color", border_color)


func set_disabled(value: bool) -> void:
	disabled = value
	modulate.a = 0.45 if value else 1.0
