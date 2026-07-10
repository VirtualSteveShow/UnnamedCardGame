class_name ItemDatabase
extends RefCounted
## Source of item/action cards for the card browser.
##
## Capture cards come in tiers by HP-percentage threshold, City Faction
## flavored as scrap-built traps rather than fantasy capture devices. The
## weakest one (Alley Snare) is the version included in every starter
## deck; stronger tiers are found/earned later. Healing is a single
## card for now (Back-Alley Bandage).

const ITEMS := [
	{
		name = "Alley Snare",
		path = "res://assets/city_faction/item_alley_snare.png",
		type = ItemCardData.ItemType.CAPTURE,
		threshold = 0.25,
		description = "Captures a creature at or below 25% health. Comes in every starter deck. One use per battle.",
	},
	{
		name = "Weighted Net",
		path = "res://assets/city_faction/item_weighted_net.png",
		type = ItemCardData.ItemType.CAPTURE,
		threshold = 0.5,
		description = "Captures a creature at or below 50% health. One use per battle.",
	},
	{
		name = "Reinforced Cage",
		path = "res://assets/city_faction/item_reinforced_cage.png",
		type = ItemCardData.ItemType.CAPTURE,
		threshold = 0.75,
		description = "Captures a creature at or below 75% health. One use per battle.",
	},
	{
		name = "Back-Alley Bandage",
		path = "res://assets/city_faction/item_healing_bandage.png",
		type = ItemCardData.ItemType.HEALING,
		heal = 8,
		description = "Restores 8 HP to a creature.",
	},
]

static func get_item_cards() -> Array[ItemCardData]:
	var cards: Array[ItemCardData] = []
	for entry in ITEMS:
		var card := ItemCardData.new()
		card.card_name = entry.name
		card.art_texture = load(entry.path)
		card.item_type = entry.type
		card.description = entry.description
		card.capture_hp_threshold = entry.get("threshold", 0.5)
		card.heal_amount = entry.get("heal", 0)
		cards.append(card)
	return cards
