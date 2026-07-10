extends Button
## A single card thumbnail shown in the card browser grid.
##
## Extends Button (not a plain Control) so mouse clicks and touch taps
## both work out of the box -- Godot emulates mouse/gui input from touch
## by default, and Button already handles hover/pressed/focus states for
## us instead of us hand-rolling gui_input handling per card.

signal card_selected(card_data: CardData)

@onready var art_rect: ColorRect = $Art
@onready var name_label: Label = $NameLabel
@onready var level_label: Label = $LevelLabel
@onready var xp_bar: ProgressBar = $XpBar

var card_data: CardData


func setup(data: CardData) -> void:
	card_data = data
	art_rect.color = data.placeholder_color
	name_label.text = data.card_name
	level_label.text = "Lv %d" % data.level
	xp_bar.value = data.xp_progress * 100.0


func _pressed() -> void:
	card_selected.emit(card_data)
