class_name CardDatabase
extends RefCounted
## Source of creature cards for the card browser.
##
## Once real content exists for every card (likely authored as individual
## CardData .tres resources), this will be replaced. For now the first
## entries carry real Flux-generated art (REAL_CREATURES below) and the
## rest are fabricated placeholder cards, so the browser has a mix of
## real and stand-in content to lay out.
##
## City Faction (gritty urban night style, the game's first faction):
## starters get a full 3-stage arc (base -> in training -> expert) with
## a branch point between two playstyles; most of the wider roster gets
## at most one evolution, and some (can_evolve = false) get none at all
## by design -- less expressive/intelligent animals like a cockroach or
## opossum don't read as plausible wearing gear or having a "trained"
## personality upgrade the way a raccoon, crow, or dog does. See
## docs/gameplay-notes.md for the full design writeup.
const REAL_CREATURES := [
	{name = "Alley Kitten", path = "res://assets/city_faction/black_cat_base.png",
		xp = 0.1, level = 1, max_health = 10, can_evolve = true},
	{name = "Cutpurse Cat", path = "res://assets/city_faction/black_cat_rogue_lv2.png",
		xp = 0.5, level = 2, max_health = 10, can_evolve = true},
	{name = "Backalley Blade", path = "res://assets/city_faction/black_cat_rogue_lv3.png",
		xp = 1.0, level = 3, max_health = 10, can_evolve = true},
	{name = "Junkyard Scrapper", path = "res://assets/city_faction/black_cat_brawler_lv2.png",
		xp = 0.5, level = 2, max_health = 10, can_evolve = true},
	{name = "Alley Boss", path = "res://assets/city_faction/black_cat_brawler_lv3.png",
		xp = 1.0, level = 3, max_health = 10, can_evolve = true},

	# Wider roster -- can_evolve = true flags creatures earmarked for a
	# future evolution line (not yet drawn); false means single-stage by
	# design, not just "no art yet".
	{name = "Raccoon", path = "res://assets/city_faction/raccoon.png",
		xp = 0.2, level = 1, max_health = 12, can_evolve = true},
	{name = "Crow", path = "res://assets/city_faction/crow.png",
		xp = 0.2, level = 1, max_health = 6, can_evolve = true},
	{name = "Stray Dog", path = "res://assets/city_faction/stray_dog.png",
		xp = 0.2, level = 1, max_health = 14, can_evolve = true},
	{name = "Pigeon", path = "res://assets/city_faction/pigeon.png",
		xp = 0.0, level = 1, max_health = 5, can_evolve = false},
	{name = "Opossum", path = "res://assets/city_faction/opossum.png",
		xp = 0.0, level = 1, max_health = 8, can_evolve = false},
	{name = "Cockroach", path = "res://assets/city_faction/cockroach.png",
		xp = 0.0, level = 1, max_health = 4, can_evolve = false},
	{name = "Sewer Rat", path = "res://assets/city_faction/sewer_rat.png",
		xp = 0.0, level = 1, max_health = 10, can_evolve = false},
	{name = "Sewer Alligator", path = "res://assets/city_faction/sewer_alligator.png",
		xp = 0.0, level = 1, max_health = 30, can_evolve = false},
	{name = "Bat", path = "res://assets/city_faction/bat.png",
		xp = 0.0, level = 1, max_health = 6, can_evolve = false},
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

		if i < REAL_CREATURES.size():
			var entry: Dictionary = REAL_CREATURES[i]
			card.card_name = entry.name
			card.art_texture = load(entry.path)
			card.xp_progress = entry.xp
			card.level = entry.level
			card.max_health = entry.max_health
			card.can_evolve = entry.can_evolve
		else:
			card.card_name = "Creature %02d" % (i + 1)
			card.placeholder_color = PLACEHOLDER_COLORS[i % PLACEHOLDER_COLORS.size()]
			card.level = 1 + (i % 5)
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
