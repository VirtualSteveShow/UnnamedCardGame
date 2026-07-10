extends Control
## Full-screen overlay showing a single card's details: enlarged art,
## name, level, XP progress, and its full ability list with energy costs.
##
## Lives inside card_browser.tscn as a hidden overlay (start visibility
## is set to false directly on this scene's root node) and is shown on
## demand via show_card(). Tapping the dimmed backdrop or the close
## button hides it again -- viewing a card is non-destructive, so no
## confirmation is needed to dismiss it.

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


func _on_close_pressed() -> void:
	visible = false


func _on_dim_background_gui_input(event: InputEvent) -> void:
	# Tapping/clicking anywhere on the dimmed backdrop closes the detail
	# view, same as tapping the explicit close button.
	if event is InputEventMouseButton and event.pressed:
		visible = false
