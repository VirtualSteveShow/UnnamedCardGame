extends Control
## Full-screen overlay showing a single card's details: enlarged art,
## name, XP progress, and its full ability list with energy costs.
##
## Lives inside card_browser.tscn as a hidden overlay (start visibility
## is set to false directly on this scene's root node) and is shown on
## demand via show_card(). Tapping the dimmed backdrop hides it again --
## viewing a card is non-destructive, so no confirmation is needed to
## dismiss it, and there's no separate close button.
##
## The panel's own size follows CardData.ASPECT_RATIO (same shape as the
## grid cards, just bigger). The Art node uses the exact same fractional
## anchors as the grid's Art node so the art reads as the same shape in
## both places instead of subtly warping between them; the rest of the
## rows (name/xp/abilities) are positioned with fractional anchors too,
## so resizing the panel here is all that's needed for the whole layout
## to scale together.

const MAX_HEIGHT_FRACTION := 0.88
const MAX_WIDTH_FRACTION := 0.9

## Ability rows are built at runtime (see _build_ability_row), so their
## font size has to be set in code rather than the .tscn.
const ABILITY_ROW_FONT_SIZE := 24

@onready var panel: Panel = $Panel
@onready var art_rect: ColorRect = $Panel/Art
@onready var name_label: Label = $Panel/NameLabel
@onready var xp_bar: ProgressBar = $Panel/XpBar
@onready var ability_list: VBoxContainer = $Panel/AbilityList
@onready var dim_background: ColorRect = $DimBackground


func _ready() -> void:
	dim_background.gui_input.connect(_on_dim_background_gui_input)
	get_viewport().size_changed.connect(_update_panel_size)
	_update_panel_size()


func show_card(data: CardData) -> void:
	art_rect.color = data.placeholder_color
	name_label.text = data.card_name
	xp_bar.value = data.xp_progress * 100.0

	# Clear any ability rows left over from whichever card was shown
	# previously before rebuilding the list for this one.
	for child in ability_list.get_children():
		child.queue_free()
	for ability in data.abilities:
		ability_list.add_child(_build_ability_row(ability))

	visible = true


func _build_ability_row(ability: CardAbility) -> HBoxContainer:
	var row := HBoxContainer.new()

	var name_lbl := Label.new()
	name_lbl.text = ability.ability_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", ABILITY_ROW_FONT_SIZE)
	row.add_child(name_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "%d energy" % ability.energy_cost
	cost_lbl.add_theme_font_size_override("font_size", ABILITY_ROW_FONT_SIZE)
	row.add_child(cost_lbl)

	return row


func _update_panel_size() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var panel_height: float = viewport_size.y * MAX_HEIGHT_FRACTION
	var panel_width: float = panel_height * CardData.ASPECT_RATIO

	var max_width: float = viewport_size.x * MAX_WIDTH_FRACTION
	if panel_width > max_width:
		panel_width = max_width
		panel_height = panel_width / CardData.ASPECT_RATIO

	panel.offset_left = -panel_width / 2.0
	panel.offset_right = panel_width / 2.0
	panel.offset_top = -panel_height / 2.0
	panel.offset_bottom = panel_height / 2.0


func _on_dim_background_gui_input(event: InputEvent) -> void:
	# React on release, not press: if we hid the overlay on press, the
	# matching release event for that same tap would arrive after the
	# overlay (and the grid button underneath it) is already visible
	# again, registering as a full click on whatever card is under the
	# finger -- immediately reopening the detail view instead of closing
	# it. Closing on release means both events are consumed while this
	# overlay is still the topmost control, so nothing leaks through.
	if event is InputEventMouseButton and not event.pressed:
		visible = false
