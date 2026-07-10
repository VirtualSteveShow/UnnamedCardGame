extends Control
## Card browser: lays out every known card in a scrolling, wrapping grid
## and opens a detail overlay when one is tapped/clicked. This is the
## current main scene while later gameplay systems are still being built.

const CardItemScene := preload("res://scenes/card_browser/card_item.tscn")

## Standard trading-card ratio (2.5in x 3.5in, e.g. MTG/Pokemon TCG),
## width:height. Cards are sized off this ratio rather than a fixed
## pixel size so they keep a recognizable "card" silhouette at any
## screen size.
const CARD_ASPECT_RATIO := 2.5 / 3.5

## How many card rows should be visible in the scroll area at once;
## anything beyond that is reached by scrolling rather than shrinking
## cards further to cram more rows in.
const VISIBLE_ROWS := 2

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var title_label: Label = $TitleLabel
@onready var version_label: Label = $VersionLabel
@onready var detail_overlay: Control = $CardDetail

var _card_items: Array[Button] = []


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	version_label.text = "v%s" % version

	_populate_grid()

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _populate_grid() -> void:
	for card_data in CardDatabase.get_placeholder_cards():
		var item := CardItemScene.instantiate()
		grid.add_child(item)
		item.setup(card_data)
		item.card_selected.connect(_on_card_selected)
		_card_items.append(item)


func _on_viewport_resized() -> void:
	_apply_safe_area_padding()
	_update_card_layout()


## Phones with camera cutouts/punch-holes report a "safe area" smaller
## than the full screen. We inset the edge-anchored UI by the gap
## between the two so cards and text never sit under the cutout, no
## matter which edge it's on or how the device is rotated.
func _apply_safe_area_padding() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	if screen_size.x <= 0 or screen_size.y <= 0:
		return

	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var viewport_size: Vector2 = get_viewport_rect().size

	# Express the insets as a fraction of the physical screen, then scale
	# into our viewport's own coordinate space -- this holds regardless
	# of stretch mode or device pixel ratio.
	var left: float = (float(safe_area.position.x) / screen_size.x) * viewport_size.x
	var right: float = (float(screen_size.x - (safe_area.position.x + safe_area.size.x)) / screen_size.x) * viewport_size.x
	var top: float = (float(safe_area.position.y) / screen_size.y) * viewport_size.y
	var bottom: float = (float(screen_size.y - (safe_area.position.y + safe_area.size.y)) / screen_size.y) * viewport_size.y

	title_label.offset_left = 20.0 + left
	title_label.offset_top = 14.0 + top

	scroll_container.offset_left = 8.0 + left
	scroll_container.offset_right = -8.0 - right
	scroll_container.offset_top = 64.0 + top
	scroll_container.offset_bottom = -8.0 - bottom

	version_label.offset_right = -12.0 - right
	version_label.offset_left = -160.0 - right
	version_label.offset_bottom = -12.0 - bottom
	version_label.offset_top = -48.0 - bottom


## Sizes every card so exactly VISIBLE_ROWS fit in the scroll area's
## height (more are reached by scrolling), keeping the standard card
## aspect ratio, then works out how many columns fit at that width.
func _update_card_layout() -> void:
	var v_separation: float = grid.get_theme_constant("v_separation")
	var h_separation: float = grid.get_theme_constant("h_separation")

	var available_height: float = scroll_container.size.y
	var card_height: float = (available_height - v_separation * (VISIBLE_ROWS - 1)) / VISIBLE_ROWS
	card_height = maxf(card_height, 80.0)
	var card_width: float = card_height * CARD_ASPECT_RATIO

	for item in _card_items:
		item.custom_minimum_size = Vector2(card_width, card_height)

	var available_width: float = scroll_container.size.x
	var columns := int((available_width + h_separation) / (card_width + h_separation))
	grid.columns = maxi(1, columns)


func _on_card_selected(card_data: CardData) -> void:
	detail_overlay.show_card(card_data)
