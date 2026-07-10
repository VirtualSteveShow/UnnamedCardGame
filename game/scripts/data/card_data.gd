class_name CardData
extends Resource
## Placeholder data model for a single creature card.
##
## This will grow (evolution paths, capture rules, real ability effects,
## etc.) as gameplay systems come online. For now it holds just enough to
## drive the card browser: identity, level/XP, a placeholder-art color
## standing in for real Flux-generated art, and a list of abilities with
## their energy costs.

## Standard trading-card ratio (2.5in x 3.5in, e.g. MTG/Pokemon TCG),
## width:height. Shared by the grid and detail view so a card reads as
## the same shape everywhere it's shown.
const ASPECT_RATIO := 2.5 / 3.5

## Display name shown on the card.
@export var card_name: String = "Unnamed Creature"

## Current level. Leveling up (not implemented yet) will eventually offer
## a choice of evolution path on the creature's first level-up.
@export var level: int = 1

## Progress toward the next level, 0.0-1.0. Drives the XP bar fill.
@export_range(0.0, 1.0) var xp_progress: float = 0.0

## Real card art, once generated. Null means no art yet -- the browser
## and detail view fall back to a solid-color swatch (placeholder_color)
## instead.
@export var art_texture: Texture2D = null

## Used to tint a placeholder rectangle so cards are still visually
## distinguishable before real art exists (art_texture is null).
@export var placeholder_color: Color = Color.WHITE

## Abilities available to this creature.
@export var abilities: Array[CardAbility] = []


## Shared by the grid and detail view: returns art_texture if set,
## otherwise a flat-color texture built from placeholder_color, so both
## places can always just set a TextureRect's texture without branching
## on whether real art exists yet.
func get_display_texture() -> Texture2D:
	if art_texture:
		return art_texture
	var image := Image.create(4, 4, false, Image.FORMAT_RGB8)
	image.fill(placeholder_color)
	return ImageTexture.create_from_image(image)
