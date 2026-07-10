class_name CardDatabase
extends RefCounted
## Temporary source of placeholder creature cards for the card browser.
##
## Once real content exists (likely authored as individual CardData
## .tres resources once art is ready), this will be replaced. For now it
## fabricates a handful of varied placeholder cards so the browser has
## something to lay out and the detail view has something to show.

const PLACEHOLDER_COLORS: Array[Color] = [
	Color(0.85, 0.35, 0.35), # red
	Color(0.35, 0.55, 0.85), # blue
	Color(0.40, 0.75, 0.40), # green
	Color(0.85, 0.75, 0.30), # yellow
	Color(0.65, 0.40, 0.80), # purple
	Color(0.85, 0.55, 0.30), # orange
]

const PLACEHOLDER_COUNT := 36

static func get_placeholder_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for i in range(PLACEHOLDER_COUNT):
		var card := CardData.new()
		card.card_name = "Creature %02d" % (i + 1)
		card.level = 1 + (i % 5)
		# Spread XP values out deterministically so cards look varied
		# without needing real progression data yet.
		card.xp_progress = fmod(i * 0.37, 1.0)
		card.placeholder_color = PLACEHOLDER_COLORS[i % PLACEHOLDER_COLORS.size()]

		var strike := CardAbility.new()
		strike.ability_name = "Strike"
		strike.energy_cost = 1 + (i % 3)

		var guard := CardAbility.new()
		guard.ability_name = "Guard"
		guard.energy_cost = 1

		card.abilities = [strike, guard]
		cards.append(card)
	return cards
