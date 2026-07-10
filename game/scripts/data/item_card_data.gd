class_name ItemCardData
extends BaseCardData
## Non-creature card data: items/actions like capture tools and healing.
## Identity/art/aspect-ratio live on BaseCardData (shared with CardData)
## -- this adds what an item needs instead of a creature's level/XP/
## abilities: a short effect description and type-specific numbers.

enum ItemType { CAPTURE, HEALING }

@export var item_type: ItemType = ItemType.HEALING

## Short effect text shown in the detail view, e.g. "Captures a creature
## at or below 25% health. One use per battle."
@export_multiline var description: String = ""

## Capture cards: auto-captures the target if its HP is at or below this
## fraction (0.0-1.0) when played. Unused for non-capture items.
@export_range(0.0, 1.0) var capture_hp_threshold: float = 0.5

## Healing cards: HP restored when played. Unused for non-healing items.
@export var heal_amount: int = 0

@export var one_use_per_battle: bool = true
