class_name CardDatabase
extends RefCounted
## Temporary source of creature cards for the card browser.
##
## Once real content exists for every card (likely authored as individual
## CardData .tres resources), this will be replaced. For now the first
## few entries carry real Flux-generated art (REAL_CREATURES below) and
## the rest are fabricated placeholder cards, so the browser has a mix
## of real and stand-in content to lay out.

## Real creature art generated so far: [display name, texture path].
## Add to this as more art gets finished; anything beyond this list
## still falls back to a placeholder-color swatch.
const REAL_CREATURES := [
	["Fox", "res://assets/creatures/fox.png"],
	["Owl", "res://assets/creatures/owl.png"],
	["Turtle", "res://assets/creatures/turtle.png"],
	["Wolf", "res://assets/creatures/wolf.png"],
	["Dragon", "res://assets/creatures/dragon.png"],
	["Rabbit", "res://assets/creatures/rabbit.png"],
]

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
		card.level = 1 + (i % 5)
		# Spread XP values out deterministically so cards look varied
		# without needing real progression data yet.
		card.xp_progress = fmod(i * 0.37, 1.0)

		if i < REAL_CREATURES.size():
			card.card_name = REAL_CREATURES[i][0]
			card.art_texture = load(REAL_CREATURES[i][1])
		else:
			card.card_name = "Creature %02d" % (i + 1)
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
