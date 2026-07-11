extends Button
## Visual card-pile stack (draw pile or discard pile) shown beside the
## hand row. Tap to open an overlay listing every card currently in the
## pile. The draw pile also doubles as the on-screen "origin point"
## battle.gd's draw animation flies cards away from -- see
## battle.gd's _fly_card_from_deck.
##
## Shows a stacked-card look when the pile has cards, or a flat empty
## outline (no stack shadow, no fill) when it's empty -- most noticeable
## for the discard pile, which starts every battle empty. No card-back
## art yet (placeholder stack look) -- swap in real art on FrontPanel
## once it exists.

signal tapped

@onready var back_rect: ColorRect = $BackRect
@onready var mid_rect: ColorRect = $MidRect
@onready var front_panel: Panel = $FrontPanel
@onready var pile_label: Label = $FrontPanel/PileLabel
@onready var count_label: Label = $FrontPanel/CountLabel

var _filled_style: StyleBoxFlat
var _empty_style: StyleBoxFlat


func _ready() -> void:
	pressed.connect(func() -> void: tapped.emit())

	_filled_style = front_panel.get_theme_stylebox("panel").duplicate()
	_empty_style = _filled_style.duplicate()
	_empty_style.bg_color = Color(1, 1, 1, 0.05)
	_empty_style.border_color = Color(1, 1, 1, 0.35)


func set_label(text: String) -> void:
	pile_label.text = text


func set_count(n: int) -> void:
	var is_empty := n <= 0
	count_label.text = str(n)
	count_label.visible = not is_empty
	back_rect.visible = not is_empty
	mid_rect.visible = not is_empty
	front_panel.add_theme_stylebox_override("panel", _empty_style if is_empty else _filled_style)
