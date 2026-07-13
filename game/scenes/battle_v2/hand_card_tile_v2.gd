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
@onready var effect_label: RichTextLabel = $EffectLabel

var card: BaseCardData
var disabled: bool = false

const COLOR_ATTACK := Color(0.75, 0.18, 0.16)
const COLOR_SKILL := Color(0.18, 0.45, 0.78)
const COLOR_MONSTER := Color(0.22, 0.62, 0.28)
const COLOR_ITEM := Color(0.7, 0.55, 0.22)

## Slay the Spire-style short/wide art band used by every card type except
## creature cards (which keep their original tall art -- see setup()).
## Each entry is [anchor_left, anchor_top, anchor_right, anchor_bottom].
const ART_ANCHORS_STS: Array[float] = [0.06, 0.16, 0.94, 0.44]
const TYPE_ANCHORS_STS: Array[float] = [0.0, 0.46, 1.0, 0.53]

## Creature cards keep their original full-height art (explicitly asked
## to stay the same size) since there's no on-card effect text competing
## for space -- their abilities are summarized in TypeLabel instead and
## explained in full by the focus tooltip.
const ART_ANCHORS_CREATURE: Array[float] = [0.08, 0.16, 0.92, 0.8]
const TYPE_ANCHORS_CREATURE: Array[float] = [0.0, 0.83, 1.0, 0.96]

## Card-face keyword highlight color, matching the cost badge's gold.
const KEYWORD_COLOR := "#FFD94D"
const KEYWORDS := ["Block", "Vulnerable", "Taunt", "Weak"]

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

	var is_creature := c is CardData
	_apply_anchors(art_rect, ART_ANCHORS_CREATURE if is_creature else ART_ANCHORS_STS)
	_apply_anchors(type_label, TYPE_ANCHORS_CREATURE if is_creature else TYPE_ANCHORS_STS)
	type_label.autowrap_mode = TextServer.AUTOWRAP_WORD if is_creature else TextServer.AUTOWRAP_OFF
	effect_label.visible = not is_creature

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
		var names: Array[String] = []
		for ability in c.abilities:
			names.append(ability.ability_name)
		type_text = ", ".join(names) if not names.is_empty() else "Monster"
	else:
		border_color = COLOR_ITEM
		type_text = "Item"

	_border_style.border_color = border_color
	type_label.text = type_text
	type_label.add_theme_color_override("font_color", border_color)

	if not is_creature:
		effect_label.text = "[center]%s[/center]" % _highlight_keywords(_build_effect_text(c))


## Card-face effect text for ability/item cards -- the same numbers the
## focus tooltip used to show, now printed directly on the card so the
## tooltip doesn't have to duplicate it (Slay the Spire puts the effect
## on the card itself and reserves tooltips for keyword glossary entries).
func _build_effect_text(c: BaseCardData) -> String:
	if c is AbilityCardData:
		var parts: Array[String] = []
		if c.ability.damage > 0:
			parts.append("Deal %d damage." % c.ability.damage)
		if c.ability.block > 0:
			parts.append("Gain %d Block." % c.ability.block)
		if c.ability.heal > 0:
			parts.append("Heal %d HP." % c.ability.heal)
		return "\n".join(parts)
	elif c is ItemCardData:
		return c.description
	return ""


func _highlight_keywords(text: String) -> String:
	for keyword in KEYWORDS:
		text = text.replace(keyword, "[color=%s]%s[/color]" % [KEYWORD_COLOR, keyword])
	return text


func _apply_anchors(control: Control, anchors: Array[float]) -> void:
	control.anchor_left = anchors[0]
	control.anchor_top = anchors[1]
	control.anchor_right = anchors[2]
	control.anchor_bottom = anchors[3]


func set_disabled(value: bool) -> void:
	disabled = value
	modulate.a = 0.45 if value else 1.0
