extends Control
## Card browser: lays out every known card in a scrolling, wrapping grid
## and opens a detail overlay when one is tapped/clicked. This is the
## current main scene while later gameplay systems are still being built.

const CardItemScene := preload("res://scenes/card_browser/card_item.tscn")

## Target width (px) each grid column should occupy. Used to compute how
## many columns fit at the current viewport width so the layout adapts
## across the aspect ratios called out in the project requirements
## (16:9, 16:10, tall phone screens, etc.) instead of assuming a fixed
## column count.
const CARD_COLUMN_WIDTH := 220

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var version_label: Label = $VersionLabel
@onready var detail_overlay: Control = $CardDetail


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	version_label.text = "v%s" % version

	_populate_grid()

	get_viewport().size_changed.connect(_update_column_count)
	_update_column_count()


func _populate_grid() -> void:
	for card_data in CardDatabase.get_placeholder_cards():
		var item := CardItemScene.instantiate()
		grid.add_child(item)
		item.setup(card_data)
		item.card_selected.connect(_on_card_selected)


func _update_column_count() -> void:
	var available_width: float = scroll_container.size.x
	var columns := maxi(1, int(available_width / CARD_COLUMN_WIDTH))
	grid.columns = columns


func _on_card_selected(card_data: CardData) -> void:
	detail_overlay.show_card(card_data)
