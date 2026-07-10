extends Control
## Card browser: lays out every known card in a scrolling, wrapping grid
## and opens a detail overlay when one is tapped/clicked. This is the
## current main scene while later gameplay systems are still being built.

const CardItemScene := preload("res://scenes/card_browser/card_item.tscn")

## How many card rows should be visible in the scroll area at once;
## anything beyond that is reached by scrolling rather than shrinking
## cards further to cram more rows in.
const VISIBLE_ROWS := 2

## Minimum edge padding applied on every side even where there's no
## camera cutout, so the layout still looks visually balanced instead
## of lopsided (padded only on whichever edge has a cutout).
const BASE_EDGE_PADDING := 24.0

## Extra vertical space reserved above the grid for the title text,
## on top of the top edge padding.
const TITLE_BAR_HEIGHT := 50.0

const VERSION_LABEL_SIZE := Vector2(160.0, 44.0)

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var title_label: Label = $TitleLabel
@onready var version_bg: ColorRect = $VersionBg
@onready var version_label: Label = $VersionLabel
@onready var detail_overlay: Control = $CardDetail

var _card_items: Array[Control] = []

## ScrollContainer.scroll_vertical is an int, but touch motion arrives as
## a stream of many sub-pixel deltas. Rounding each one individually
## drops almost all of them (round(0.4) == 0 every time), making drags
## feel far slower than the actual finger movement. Accumulating the
## remainder here instead means no movement gets lost, just deferred to
## the next event.
var _scroll_remainder := 0.0

## Touch motion can deliver many samples between rendered frames, and
## each write to scroll_vertical forces the grid to re-layout. Writing
## on every single input event was re-laying-out all 36 cards dozens of
## times per visual frame -- the actual source of the choppiness/flicker.
## Pending drag motion is queued here and applied once per frame in
## _process() instead, decoupling input sampling rate from layout rate.
var _pending_scroll_delta := 0.0


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
		item.drag_scrolled.connect(_on_card_drag_scrolled)
		_card_items.append(item)


func _on_viewport_resized() -> void:
	_apply_safe_area_padding()
	_update_card_layout()


## Phones with camera cutouts/punch-holes report a "safe area" smaller
## than the full screen. We inset the edge-anchored UI by at least that
## gap so cards/text never sit under the cutout -- but never by *less*
## than BASE_EDGE_PADDING either, so edges without a cutout still get a
## matching margin instead of looking unpadded next to the cutout side.
func _apply_safe_area_padding() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var left := BASE_EDGE_PADDING
	var right := BASE_EDGE_PADDING
	var top := BASE_EDGE_PADDING
	var bottom := BASE_EDGE_PADDING

	if screen_size.x > 0 and screen_size.y > 0:
		var safe_area: Rect2i = DisplayServer.get_display_safe_area()
		var viewport_size: Vector2 = get_viewport_rect().size

		# Express the cutout insets as a fraction of the physical screen,
		# then scale into our viewport's own coordinate space -- this
		# holds regardless of stretch mode or device pixel ratio.
		var cutout_left: float = (float(safe_area.position.x) / screen_size.x) * viewport_size.x
		var cutout_right: float = (float(screen_size.x - (safe_area.position.x + safe_area.size.x)) / screen_size.x) * viewport_size.x
		var cutout_top: float = (float(safe_area.position.y) / screen_size.y) * viewport_size.y
		var cutout_bottom: float = (float(screen_size.y - (safe_area.position.y + safe_area.size.y)) / screen_size.y) * viewport_size.y

		left = maxf(BASE_EDGE_PADDING, cutout_left)
		right = maxf(BASE_EDGE_PADDING, cutout_right)
		top = maxf(BASE_EDGE_PADDING, cutout_top)
		bottom = maxf(BASE_EDGE_PADDING, cutout_bottom)

	title_label.offset_left = left
	title_label.offset_top = top

	scroll_container.offset_left = left
	scroll_container.offset_right = -right
	scroll_container.offset_top = top + TITLE_BAR_HEIGHT
	scroll_container.offset_bottom = -bottom

	version_label.offset_right = -right
	version_label.offset_left = -right - VERSION_LABEL_SIZE.x
	version_label.offset_bottom = -bottom
	version_label.offset_top = -bottom - VERSION_LABEL_SIZE.y
	version_bg.offset_right = version_label.offset_right
	version_bg.offset_left = version_label.offset_left
	version_bg.offset_bottom = version_label.offset_bottom
	version_bg.offset_top = version_label.offset_top


## Sizes every card so exactly VISIBLE_ROWS fit in the scroll area's
## height (more are reached by scrolling), keeping the standard card
## aspect ratio, then works out how many columns fit at that width.
func _update_card_layout() -> void:
	var v_separation: float = grid.get_theme_constant("v_separation")
	var h_separation: float = grid.get_theme_constant("h_separation")

	var available_height: float = scroll_container.size.y
	var card_height: float = (available_height - v_separation * (VISIBLE_ROWS - 1)) / VISIBLE_ROWS
	card_height = maxf(card_height, 80.0)
	var card_width: float = card_height * CardData.ASPECT_RATIO

	for item in _card_items:
		item.custom_minimum_size = Vector2(card_width, card_height)

	var available_width: float = scroll_container.size.x
	var columns := int((available_width + h_separation) / (card_width + h_separation))
	grid.columns = maxi(1, columns)


func _on_card_selected(card_data: CardData) -> void:
	detail_overlay.show_card(card_data)


## Cards forward their own drag movement here instead of relying on it
## reaching the ScrollContainer on its own, since a Control sitting on
## top of a ScrollContainer swallowing the hit turned out to block that
## in practice. Just queues the motion -- _process() is what actually
## applies it, once per frame.
func _on_card_drag_scrolled(delta: Vector2) -> void:
	_pending_scroll_delta += delta.y


func _process(_delta: float) -> void:
	if _pending_scroll_delta == 0.0:
		return

	# Content follows the finger, so the scroll offset moves opposite
	# the accumulated drag delta.
	_scroll_remainder += _pending_scroll_delta
	_pending_scroll_delta = 0.0
	var whole_pixels := roundi(_scroll_remainder)
	_scroll_remainder -= whole_pixels
	if whole_pixels != 0:
		scroll_container.scroll_vertical -= whole_pixels
