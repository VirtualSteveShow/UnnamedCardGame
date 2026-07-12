extends Control
## App entry point. Bare-bones hub screen: three buttons launch Battle
## (starts a fresh run and opens the map -- see RunState), the card
## browser, or a placeholder Options screen. Every other screen's "Back"
## button returns here directly (hub-and-spoke navigation) rather than
## to whichever screen launched it.

const VERSION_LABEL_SIZE := Vector2(160.0, 44.0)
const BASE_EDGE_PADDING := 24.0

@onready var battle_button: Button = $CenterContainer/VBoxContainer/BattleButton
@onready var view_cards_button: Button = $CenterContainer/VBoxContainer/ViewCardsButton
@onready var options_button: Button = $CenterContainer/VBoxContainer/OptionsButton
@onready var version_bg: ColorRect = $VersionBg
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	version_label.text = "v%s" % version

	battle_button.pressed.connect(_on_battle_pressed)
	view_cards_button.pressed.connect(_on_view_cards_pressed)
	options_button.pressed.connect(_on_options_pressed)

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _on_viewport_resized() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var right := BASE_EDGE_PADDING
	var bottom := BASE_EDGE_PADDING

	if screen_size.x > 0 and screen_size.y > 0:
		var safe_area: Rect2i = DisplayServer.get_display_safe_area()
		var viewport_size: Vector2 = get_viewport_rect().size
		var cutout_right: float = (float(screen_size.x - (safe_area.position.x + safe_area.size.x)) / screen_size.x) * viewport_size.x
		var cutout_bottom: float = (float(screen_size.y - (safe_area.position.y + safe_area.size.y)) / screen_size.y) * viewport_size.y
		right = maxf(BASE_EDGE_PADDING, cutout_right)
		bottom = maxf(BASE_EDGE_PADDING, cutout_bottom)

	version_label.offset_right = -right
	version_label.offset_left = -right - VERSION_LABEL_SIZE.x
	version_label.offset_bottom = -bottom
	version_label.offset_top = -bottom - VERSION_LABEL_SIZE.y
	version_bg.offset_right = version_label.offset_right
	version_bg.offset_left = version_label.offset_left
	version_bg.offset_bottom = version_label.offset_bottom
	version_bg.offset_top = version_label.offset_top


## Battle always begins a fresh run (see RunState) -- there's no
## save/resume concept yet, so this discards any previous run's progress
## and starts back at the map's first node.
func _on_battle_pressed() -> void:
	Run.start_new_run()
	get_tree().change_scene_to_file("res://scenes/map/map_screen.tscn")


func _on_view_cards_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/card_browser/card_browser.tscn")


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options/options_screen.tscn")
