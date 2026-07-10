extends Control
## Full-screen overlay showing a single card's details: enlarged art,
## name, level, XP progress, and its full ability list with energy costs.
##
## Lives inside card_browser.tscn as a hidden overlay (start visibility
## is set to false directly on this scene's root node) and is shown on
## demand via show_card(). Tapping the dimmed backdrop or the close
## button hides it again -- viewing a card is non-destructive, so no
## confirmation is needed to dismiss it.

## Panel margin, and vertical space each row of "chrome" below the art
## (name/level/xp/abilities/close button) takes up. The art block itself
## is sized dynamically to fit the screen at CardData.ASPECT_RATIO; these
## stay fixed pixel sizes since they hold roughly fixed amounts of text.
const PANEL_MARGIN := 28.0
const ROW_GAP := 12.0
const NAME_HEIGHT := 44.0
const LEVEL_HEIGHT := 30.0
const XP_HEIGHT := 20.0
const ABILITY_LIST_HEIGHT := 100.0
const CLOSE_BUTTON_HEIGHT := 72.0

## Cap the panel's footprint so it never grows past the screen, even on
## very tall/short viewports.
const MAX_HEIGHT_FRACTION := 0.88
const MAX_WIDTH_FRACTION := 0.9

@onready var panel: Panel = $Panel
@onready var art_rect: ColorRect = $Panel/Art
@onready var name_label: Label = $Panel/NameLabel
@onready var level_label: Label = $Panel/LevelLabel
@onready var xp_bar: ProgressBar = $Panel/XpBar
@onready var ability_list: VBoxContainer = $Panel/AbilityList
@onready var close_button: Button = $Panel/CloseButton
@onready var dim_background: ColorRect = $DimBackground


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	dim_background.gui_input.connect(_on_dim_background_gui_input)
	get_viewport().size_changed.connect(_update_panel_layout)
	_update_panel_layout()


func show_card(data: CardData) -> void:
	art_rect.color = data.placeholder_color
	name_label.text = data.card_name
	level_label.text = "Level %d" % data.level
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
	row.add_child(name_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "%d energy" % ability.energy_cost
	row.add_child(cost_lbl)

	return row


## Sizes the panel around an art block that keeps CardData.ASPECT_RATIO
## (the same shape as the grid cards), fit to the current viewport, then
## lays out the fixed-height rows below it top-to-bottom.
func _update_panel_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var chrome_height: float = PANEL_MARGIN * 2.0 + ROW_GAP * 5.0 \
			+ NAME_HEIGHT + LEVEL_HEIGHT + XP_HEIGHT + ABILITY_LIST_HEIGHT + CLOSE_BUTTON_HEIGHT

	var max_panel_height: float = viewport_size.y * MAX_HEIGHT_FRACTION
	var art_height: float = maxf(max_panel_height - chrome_height, 120.0)
	var art_width: float = art_height * CardData.ASPECT_RATIO

	var max_panel_width: float = viewport_size.x * MAX_WIDTH_FRACTION
	var max_art_width: float = max_panel_width - PANEL_MARGIN * 2.0
	if art_width > max_art_width:
		art_width = max_art_width
		art_height = art_width / CardData.ASPECT_RATIO

	var panel_width: float = art_width + PANEL_MARGIN * 2.0
	var panel_height: float = art_height + chrome_height

	panel.offset_left = -panel_width / 2.0
	panel.offset_right = panel_width / 2.0
	panel.offset_top = -panel_height / 2.0
	panel.offset_bottom = panel_height / 2.0

	var left: float = PANEL_MARGIN
	var right: float = panel_width - PANEL_MARGIN
	var y: float = PANEL_MARGIN

	art_rect.offset_left = left
	art_rect.offset_right = right
	art_rect.offset_top = y
	art_rect.offset_bottom = y + art_height
	y += art_height + ROW_GAP

	name_label.offset_left = left
	name_label.offset_right = right
	name_label.offset_top = y
	name_label.offset_bottom = y + NAME_HEIGHT
	y += NAME_HEIGHT + ROW_GAP

	level_label.offset_left = left
	level_label.offset_right = right
	level_label.offset_top = y
	level_label.offset_bottom = y + LEVEL_HEIGHT
	y += LEVEL_HEIGHT + ROW_GAP

	xp_bar.offset_left = left
	xp_bar.offset_right = right
	xp_bar.offset_top = y
	xp_bar.offset_bottom = y + XP_HEIGHT
	y += XP_HEIGHT + ROW_GAP

	ability_list.offset_left = left
	ability_list.offset_right = right
	ability_list.offset_top = y
	ability_list.offset_bottom = y + ABILITY_LIST_HEIGHT
	y += ABILITY_LIST_HEIGHT + ROW_GAP

	close_button.offset_left = left
	close_button.offset_right = right
	close_button.offset_top = y
	close_button.offset_bottom = y + CLOSE_BUTTON_HEIGHT


func _on_close_pressed() -> void:
	visible = false


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
