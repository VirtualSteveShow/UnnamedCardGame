extends Button
## One card in the player's hand -- a creature card (tap to summon it
## onto the field) or an item card (tap to start choosing its target).
## battle.gd owns what a tap actually does; this is just the display +
## tap-to-select surface, same division of responsibility as
## battle_combatant_tile.gd for the field.

signal tapped(card: BaseCardData)

@onready var art_rect: TextureRect = $Art
@onready var name_label: Label = $NameLabel
@onready var cost_label: Label = $CostLabel
@onready var selection_overlay: ColorRect = $SelectionOverlay

var card: BaseCardData


func _ready() -> void:
	pressed.connect(func() -> void: tapped.emit(card))


func setup(c: BaseCardData) -> void:
	card = c
	art_rect.texture = c.get_display_texture()
	name_label.text = c.card_name
	cost_label.text = "%d energy" % c.energy_cost


func set_selected(selected: bool) -> void:
	selection_overlay.visible = selected
