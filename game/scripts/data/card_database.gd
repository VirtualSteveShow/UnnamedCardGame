class_name CardDatabase
extends RefCounted
## Source of creature cards for the card browser.
##
## Once real content exists for every card (likely authored as individual
## CardData .tres resources), this will be replaced. For now it just
## builds a CardData per REAL_CREATURES entry -- no-art placeholder
## filler cards were removed from the browser once there was a real
## enough roster to look at instead.
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

	# Suburbs Faction (calm daytime counterpart to City; doubles as the
	# tutorial location -- see docs/lore.md). Deliberately lighter than
	# City: the starter gets a single evolution (not a branching pair) to
	# show the mechanic off without a big art investment, and every
	# Suburbs creature sets simple_abilities = true (Strike only, no
	# Guard) to reinforce "basic, one-ability" tutorial simplicity in
	# data, not just flavor text.
	{name = "House Cat", path = "res://assets/suburbs/house_cat_base.png",
		battle_path = "res://assets/suburbs/battle_house_cat.png",
		xp = 0.1, level = 1, max_health = 10, can_evolve = true, simple_abilities = true,
		on_summon = {name = "Nuzzle", heal = 2}},
	{name = "Watchcat", path = "res://assets/suburbs/house_cat_evolved.png",
		xp = 1.0, level = 2, max_health = 10, can_evolve = true, simple_abilities = true},
	{name = "Family Dog", path = "res://assets/suburbs/family_dog.png",
		battle_path = "res://assets/suburbs/battle_family_dog.png",
		xp = 0.0, level = 1, max_health = 12, can_evolve = false, simple_abilities = true,
		on_summon = {name = "Warning Bite", damage = 2}, taunt = true},
	{name = "Squirrel", path = "res://assets/suburbs/squirrel.png",
		battle_path = "res://assets/suburbs/battle_squirrel.png",
		xp = 0.0, level = 1, max_health = 5, can_evolve = false, simple_abilities = true},
	{name = "Rabbit", path = "res://assets/suburbs/rabbit.png",
		battle_path = "res://assets/suburbs/battle_rabbit.png",
		xp = 0.0, level = 1, max_health = 6, can_evolve = false, simple_abilities = true},
	{name = "Robin", path = "res://assets/suburbs/robin.png",
		battle_path = "res://assets/suburbs/battle_robin.png",
		xp = 0.0, level = 1, max_health = 4, can_evolve = false, simple_abilities = true},
	{name = "Hamster", path = "res://assets/suburbs/hamster.png",
		battle_path = "res://assets/suburbs/battle_hamster.png",
		xp = 0.0, level = 1, max_health = 4, can_evolve = false, simple_abilities = true},
]

## Ability art lives at res://assets/<faction>/ability_<slug>_<ability>.png,
## generated in bulk by tools/gen_ability_art.py (see docs/gameplay-notes.md)
## -- named by convention off the creature's own slug rather than authored
## per entry above, so this stays in sync automatically as art is added.
## ResourceLoader.exists() guards against art that hasn't been generated
## yet, so a creature with no ability art yet just falls back to its
## battle/card portrait (CardAbility.art_texture staying null) instead of
## a load error.
static func _load_ability_art(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


static func get_all_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for i in range(REAL_CREATURES.size()):
		var entry: Dictionary = REAL_CREATURES[i]
		var card := CardData.new()
		card.card_name = entry.name
		card.art_texture = load(entry.path)
		card.xp_progress = entry.xp
		card.level = entry.level
		card.max_health = entry.max_health
		card.can_evolve = entry.can_evolve
		card.taunt = entry.get("taunt", false)
		if entry.has("battle_path"):
			card.battle_texture = load(entry.battle_path)

		var faction_folder: String = entry.path.split("/")[3]
		var slug: String = entry.name.to_lower().replace(" ", "_")

		if entry.has("on_summon"):
			var on_summon_data: Dictionary = entry.on_summon
			var on_summon := CardAbility.new()
			on_summon.ability_name = on_summon_data.get("name", "On Summon")
			on_summon.damage = on_summon_data.get("damage", 0)
			on_summon.heal = on_summon_data.get("heal", 0)
			on_summon.energy_cost = 0
			var on_summon_slug: String = on_summon.ability_name.to_lower().replace(" ", "_")
			on_summon.art_texture = _load_ability_art(
				"res://assets/%s/ability_%s_%s.png" % [faction_folder, slug, on_summon_slug])
			card.on_summon_ability = on_summon

		var strike := CardAbility.new()
		strike.ability_name = "Strike"
		strike.energy_cost = 1 + (i % 3)
		strike.damage = strike.energy_cost * 3
		strike.art_texture = _load_ability_art(
			"res://assets/%s/ability_%s_strike.png" % [faction_folder, slug])

		if entry.get("simple_abilities", false):
			card.abilities = [strike]
		else:
			var guard := CardAbility.new()
			guard.ability_name = "Guard"
			guard.energy_cost = 1
			guard.block = 3
			guard.art_texture = _load_ability_art(
				"res://assets/%s/ability_%s_guard.png" % [faction_folder, slug])
			card.abilities = [strike, guard]

		cards.append(card)
	return cards


## Finds a single real creature by its display name (e.g. for hardcoding
## a test battle matchup). Returns null if not found.
static func get_real_creature_by_name(creature_name: String) -> CardData:
	for card in get_all_cards():
		if card.card_name == creature_name:
			return card
	return null
