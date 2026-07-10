class_name BaseCardData
extends Resource
## Shared foundation for every card type (creature, item, etc.): identity,
## art (with a placeholder-color fallback), and the aspect ratio every
## card type uses so the frame reads as the same physical card no matter
## what's on it.

## Standard trading-card ratio (2.5in x 3.5in, e.g. MTG/Pokemon TCG),
## width:height. Shared across every card type so a creature card and an
## item card read as the same shape.
const ASPECT_RATIO := 2.5 / 3.5

## Display name shown on the card.
@export var card_name: String = "Unnamed Card"

## Real card art, once generated. Null means no art yet -- the browser
## and detail view fall back to a solid-color swatch (placeholder_color)
## instead.
@export var art_texture: Texture2D = null

## Used to tint a placeholder rectangle so cards are still visually
## distinguishable before real art exists (art_texture is null).
@export var placeholder_color: Color = Color.WHITE


## Shared by every card's grid tile and detail view: returns art_texture
## if set, otherwise a flat-color texture built from placeholder_color,
## so callers can always just set a TextureRect's texture without
## branching on whether real art exists yet.
func get_display_texture() -> Texture2D:
	if art_texture:
		return art_texture
	var image := Image.create(4, 4, false, Image.FORMAT_RGB8)
	image.fill(placeholder_color)
	return ImageTexture.create_from_image(image)
