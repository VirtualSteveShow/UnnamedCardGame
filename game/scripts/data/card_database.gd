class_name CardDatabase
extends RefCounted
## Temporary source of creature cards for the card browser.
##
## Once real content exists for every card (likely authored as individual
## CardData .tres resources), this will be replaced. For now the first
## few entries carry real Flux-generated art (REAL_CREATURES below) and
## the rest are fabricated placeholder cards, so the browser has a mix
## of real and stand-in content to lay out.

## Real creature art generated so far: [display name, texture path, xp
## progress]. Add to this as more art gets finished; anything beyond
## this list still falls back to a placeholder-color swatch.
##
## The original style-test roster (fox/owl/turtle/wolf/dragon/rabbit)
## was removed once the City Faction (gritty urban night style) replaced
## it as the actual first faction -- see game/assets/city_faction/.
##
## City Faction starter: a stray black cat with two evolution paths,
## Rogue and Brawler. Evolution mechanics aren't built yet -- these are
## just the three art pieces as separate cards for now, so the empty
## (barely-started) vs. full (just-evolved) XP bar hints at where each
## one sits without needing real progression logic yet.
const REAL_CREATURES := [
	["Black Cat", "res://assets/city_faction/black_cat_base.png", 0.1],
	["Black Cat (Rogue)", "res://assets/city_faction/black_cat_rogue.png", 1.0],
	["Black Cat (Brawler)", "res://assets/city_faction/black_cat_brawler.png", 1.0],
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

		if i < REAL_CREATURES.size():
			card.card_name = REAL_CREATURES[i][0]
			card.art_texture = load(REAL_CREATURES[i][1])
			card.xp_progress = REAL_CREATURES[i][2]
		else:
			card.card_name = "Creature %02d" % (i + 1)
			card.placeholder_color = PLACEHOLDER_COLORS[i % PLACEHOLDER_COLORS.size()]
			# Spread placeholder XP values out deterministically so cards
			# look varied without needing real progression data yet.
			card.xp_progress = fmod(i * 0.37, 1.0)

		var strike := CardAbility.new()
		strike.ability_name = "Strike"
		strike.energy_cost = 1 + (i % 3)

		var guard := CardAbility.new()
		guard.ability_name = "Guard"
		guard.energy_cost = 1

		card.abilities = [strike, guard]
		cards.append(card)
	return cards
