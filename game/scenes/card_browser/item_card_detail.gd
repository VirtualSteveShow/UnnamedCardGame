extends Control
## Full-screen overlay showing a single item card's details: enlarged
## art, name, and its effect description. Mirrors card_detail.gd's
## panel-sizing and dismiss-on-release logic (see that file's comments
## for why) -- the only real difference is the content below the art:
## a description block instead of an XP bar and ability list, since
## items don't level up or have abilities.

const MAX_HEIGHT_FRACTION := 0.88
const MAX_WIDTH_FRACTION := 0.9

@onready var panel: Panel = $Panel
@onready var art_rect: TextureRect = $Panel/Art
@onready var name_label: Label = $Panel/NameLabel
@onready var description_label: Label = $Panel/DescriptionLabel
@onready var dim_background: ColorRect = $DimBackground


func _ready() -> void:
	dim_background.gui_input.connect(_on_dim_background_gui_input)
	get_viewport().size_changed.connect(_update_panel_size)
	_update_panel_size()


func show_item(data: ItemCardData) -> void:
	art_rect.texture = data.get_display_texture()
	name_label.text = data.card_name
	description_label.text = data.description
	visible = true


func _update_panel_size() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var panel_height: float = viewport_size.y * MAX_HEIGHT_FRACTION
	var panel_width: float = panel_height * BaseCardData.ASPECT_RATIO

	var max_width: float = viewport_size.x * MAX_WIDTH_FRACTION
	if panel_width > max_width:
		panel_width = max_width
		panel_height = panel_width / BaseCardData.ASPECT_RATIO

	panel.offset_left = -panel_width / 2.0
	panel.offset_right = panel_width / 2.0
	panel.offset_top = -panel_height / 2.0
	panel.offset_bottom = panel_height / 2.0


func _on_dim_background_gui_input(event: InputEvent) -> void:
	# Close on release, not press -- see card_detail.gd's identical
	# handler for the full explanation of why press would leak the
	# matching release event onto whatever's exposed underneath.
	if event is InputEventMouseButton and not event.pressed:
		visible = false
