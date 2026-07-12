class_name BattleStateV2
extends RefCounted
## Combat logic for the "hand-based" combat prototype -- see
## docs/gameplay-notes.md for the full design rationale. This is now the
## project's one and only combat system (the original persistent-
## battlefield prototype was removed).
##
## Playing a creature card discards it immediately, gives it a live,
## HP-tracked spot on the field (field_creatures), and generates one
## AbilityCardData per currently-unlocked ability directly into hand
## (bypassing the draw pile -- these are freshly created, not drawn).
## Fielded creatures regenerate their unlocked abilities back into hand
## at the start of every player turn (see _regenerate_field_abilities),
## with higher-index abilities staggered in over a few turns rather than
## all available immediately -- see turns_on_field on BattleCombatant.
## A fielded creature only leaves when its HP reaches 0.
##
## The player has a personal HP/block pool, same as before; enemies now
## pick randomly between the player and any living field creature each
## time they attack, mirroring how a fielded creature can also be
## targeted by the player's own damaging ability/item cards.

const ENERGY_PER_TURN := 3
const HAND_SIZE := 5
const PLAYER_MAX_HP := 20

signal log_message(text: String)
signal state_changed
## Emitted after any draw (initial hand, a turn's refill, OR a creature
## entering/regenerating on the field) with just the newly added cards --
## not the whole hand -- so the UI can play a deck-to-hand (or
## hand-internal) animation for exactly what's new.
signal cards_drawn(cards: Array[BaseCardData])
## Emitted right when an ability card (or an on-summon attack) resolves,
## before state_changed, so the UI can play a "the monster pops out and
## attacks" animation using the source creature's battle sprite before
## the damage/log updates land. source_creature is null for player-only
## ability cards not tied to any creature.
signal ability_played(card: AbilityCardData, target: BattleCombatant)
## Emitted right after a played creature takes up a spot on the field.
signal creature_entered_field(combatant: BattleCombatant)
## Emitted once a fielded creature's HP reaches 0.
signal creature_left_field(combatant: BattleCombatant)

var player_deck: Array[BaseCardData] = []
var player_hand: Array[BaseCardData] = []
var player_discard: Array[BaseCardData] = []

var player_hp: int = PLAYER_MAX_HP
var player_max_hp: int = PLAYER_MAX_HP
var player_block: int = 0

## Creatures currently on the field, alive with their own HP -- see
## BattleCombatant. A played creature stays here until its HP reaches 0.
var field_creatures: Array[BattleCombatant] = []

var enemy_team: Array[BattleCombatant] = []
var energy: int = ENERGY_PER_TURN

var is_player_turn: bool = true
var is_over: bool = false
var player_won: bool = false


func _init(deck_cards: Array[BaseCardData], enemy_data: Array[CardData]) -> void:
	player_deck = deck_cards.duplicate()
	player_deck.shuffle()
	for data in enemy_data:
		enemy_team.append(BattleCombatant.new(data))


## Draws the opening hand. Split out from _init() so the caller can
## connect to cards_drawn (and any other signal) first -- a signal
## emitted mid-constructor would otherwise fire before anything's
## listening.
func start_battle() -> void:
	_draw_hand()


## True if the card is affordable and playable right now. Doesn't check
## card-specific requirements (e.g. a capture card needing a valid
## target) -- callers check those separately before actually resolving
## the play.
func can_play_card(card: BaseCardData) -> bool:
	return is_player_turn and not is_over and energy >= card.energy_cost and player_hand.has(card)


## Playing a creature card doesn't discard it into the void -- it takes a
## live, HP-tracked spot on the field (field_creatures) and its first
## unlocked ability is generated straight into hand as its own playable
## card, always free (0 energy): playing the creature card already costs
## energy, and the hand discards at end of turn regardless of what's left
## unplayed, so without this a creature played late in a turn (or on a
## tight energy budget) could release a card you can't actually afford to
## use before it's discarded unused. Later abilities stagger in via
## _regenerate_field_abilities instead, at full cost.
##
## Creature cards never require a target to play, even ones with a
## damaging on-summon ability -- that ability auto-targets a random
## living enemy (see _resolve_on_summon) instead of making the player aim
## the creature card itself, so playing a creature always uses the same
## "drag it up" gesture regardless of what it does on summon.
func play_creature_card(card: CardData) -> void:
	if not can_play_card(card):
		return

	energy -= card.energy_cost
	player_hand.erase(card)
	player_discard.append(card)

	var combatant := BattleCombatant.new(card)
	field_creatures.append(combatant)
	creature_entered_field.emit(combatant)

	if card.on_summon_ability != null:
		_resolve_on_summon(card, card.on_summon_ability)

	var generated: Array[BaseCardData] = []
	if not card.abilities.is_empty():
		generated.append(_make_ability_card(card, card.abilities[0], true))
		player_hand.append_array(generated)

	log_message.emit("%s enters the field!" % card.card_name)
	if not generated.is_empty():
		cards_drawn.emit(generated)
	_check_battle_over()
	state_changed.emit()


## Resolves a creature's on-summon ability immediately after it enters
## the field: damage auto-targets a random living enemy (there's no
## living enemy if the enemy team is already wiped, in which case it
## simply doesn't fire), healing always applies to the player. Reuses the
## ability_played signal for the damage case so the UI plays the same
## "pops out and attacks" animation a regular ability card would, without
## needing a real hand card to back it.
func _resolve_on_summon(source: CardData, ability: CardAbility) -> void:
	if ability.damage > 0:
		var target := _pick_random_living_enemy()
		if target != null:
			var anim_card := AbilityCardData.new()
			anim_card.source_creature = source
			anim_card.ability = ability
			anim_card.art_texture = source.get_battle_texture()
			ability_played.emit(anim_card, target)

			var dealt := target.take_damage(ability.damage)
			log_message.emit("%s's %s hits %s for %d damage!" % [
				source.card_name, ability.ability_name, target.data.card_name, dealt])
			_check_battle_over()

	if ability.heal > 0:
		var healed: int = mini(ability.heal, player_max_hp - player_hp)
		player_hp += healed
		log_message.emit("%s's %s heals you for %d HP." % [source.card_name, ability.ability_name, healed])


func _pick_random_living_enemy() -> BattleCombatant:
	var living: Array = enemy_team.filter(func(e): return e.is_alive())
	if living.is_empty():
		return null
	return living[randi() % living.size()]


## Builds one playable AbilityCardData for a creature's ability. The
## first ability a creature ever grants (on summon) is always free; every
## later regeneration costs the ability's normal energy.
func _make_ability_card(source: CardData, ability: CardAbility, free: bool) -> AbilityCardData:
	var ability_card := AbilityCardData.new()
	ability_card.source_creature = source
	ability_card.ability = ability
	ability_card.card_name = "%s: %s" % [source.card_name, ability.ability_name]
	ability_card.art_texture = source.get_battle_texture()
	ability_card.energy_cost = 0 if free else ability.energy_cost
	return ability_card


## Resolves a played ability card: damage lands on target (required for
## damaging abilities), block adds to the player's own block pool.
## source_creature is null for standalone player ability cards not tied
## to any creature (see battle_v2.gd's PLAYER_ABILITY cards) -- handled
## with a generic "You" in the log instead of a creature name.
func play_ability_card(card: AbilityCardData, target: BattleCombatant) -> void:
	if not can_play_card(card):
		return
	if card.ability.damage > 0 and target == null:
		return

	energy -= card.energy_cost
	player_hand.erase(card)
	player_discard.append(card)

	ability_played.emit(card, target)

	var ability := card.ability
	var source_name: String = card.source_creature.card_name if card.source_creature else "You"
	player_block += ability.block
	if ability.damage > 0:
		var dealt := target.take_damage(ability.damage)
		log_message.emit("%s used %s on %s for %d damage!" % [
			source_name, ability.ability_name, target.data.card_name, dealt])
	else:
		log_message.emit("%s used %s -- you gained %d block." % [source_name, ability.ability_name, ability.block])

	_check_battle_over()
	state_changed.emit()


## Plays an item card from hand. Healing always applies to the player
## directly (there's no player creature to choose between anymore) so
## target is only needed for capture attempts, which still target an
## enemy creature exactly as before -- enemies kept their HP.
func play_item_card(card: ItemCardData, target: BattleCombatant) -> void:
	if not can_play_card(card):
		return
	if card.item_type == ItemCardData.ItemType.CAPTURE and target == null:
		return

	energy -= card.energy_cost
	player_hand.erase(card)
	player_discard.append(card)

	match card.item_type:
		ItemCardData.ItemType.HEALING:
			var healed: int = mini(card.heal_amount, player_max_hp - player_hp)
			player_hp += healed
			log_message.emit("You used %s, healing yourself for %d HP." % [card.card_name, healed])
		ItemCardData.ItemType.CAPTURE:
			_attempt_capture(card, target)

	state_changed.emit()


func _attempt_capture(card: ItemCardData, target: BattleCombatant) -> void:
	var hp_fraction: float = float(target.current_hp) / float(target.data.max_health)
	if hp_fraction <= card.capture_hp_threshold and target.is_alive():
		target.current_hp = 0
		log_message.emit("Captured %s with %s!" % [target.data.card_name, card.card_name])
		_check_battle_over()
	else:
		log_message.emit("%s isn't weak enough yet -- %s failed." % [target.data.card_name, card.card_name])


func end_player_turn() -> void:
	if not is_player_turn or is_over:
		return
	is_player_turn = false
	_discard_hand()
	state_changed.emit()
	_run_enemy_turn()


func _run_enemy_turn() -> void:
	for enemy in enemy_team:
		enemy.block = 0

	for enemy in enemy_team:
		if is_over or not enemy.is_alive() or enemy.data.abilities.is_empty():
			continue

		var ability: CardAbility = enemy.data.abilities[randi() % enemy.data.abilities.size()]
		enemy.block += ability.block
		if ability.damage > 0:
			var target := _pick_enemy_target()
			if target == null:
				var dealt := _damage_player(ability.damage)
				log_message.emit("%s used %s on you for %d damage!" % [enemy.data.card_name, ability.ability_name, dealt])
			else:
				var dealt := target.take_damage(ability.damage)
				log_message.emit("%s used %s on %s for %d damage!" % [
					enemy.data.card_name, ability.ability_name, target.data.card_name, dealt])
				if not target.is_alive():
					_handle_field_creature_defeated(target)
		else:
			log_message.emit("%s used %s and gained %d block." % [enemy.data.card_name, ability.ability_name, ability.block])
		_check_battle_over()

	if not is_over:
		_start_player_turn()
	state_changed.emit()


## Picks who an enemy attacks: the player, or one of the player's living
## field creatures, chosen with equal weight across whichever of those
## are actually available. Returns null to mean "the player".
func _pick_enemy_target() -> BattleCombatant:
	var pool: Array = [null]
	for creature in field_creatures:
		if creature.is_alive():
			pool.append(creature)
	return pool[randi() % pool.size()]


## Removes a field creature whose HP just hit 0: drops it from the field,
## strips any of its ability cards out of both hand AND discard (their
## stats no longer mean anything once the creature that granted them is
## gone -- left in discard, a stale one could otherwise get reshuffled
## back into the draw pile and resurface in a later hand), and fires
## creature_left_field.
func _handle_field_creature_defeated(combatant: BattleCombatant) -> void:
	field_creatures.erase(combatant)
	_strip_ability_cards_for(combatant.data, player_hand)
	_strip_ability_cards_for(combatant.data, player_discard)
	log_message.emit("%s was defeated!" % combatant.data.card_name)
	creature_left_field.emit(combatant)


func _strip_ability_cards_for(source: CardData, pile: Array[BaseCardData]) -> void:
	for i in range(pile.size() - 1, -1, -1):
		var c: BaseCardData = pile[i]
		if c is AbilityCardData and c.source_creature == source:
			pile.remove_at(i)


## Applies incoming damage after subtracting the player's own block, and
## returns the amount that actually landed on HP (for log messages) --
## mirrors BattleCombatant.take_damage's block-then-HP order.
func _damage_player(amount: int) -> int:
	var blocked := mini(player_block, amount)
	player_block -= blocked
	var dealt := amount - blocked
	player_hp = maxi(0, player_hp - dealt)
	return dealt


func _start_player_turn() -> void:
	player_block = 0
	energy = ENERGY_PER_TURN
	is_player_turn = true
	_regenerate_field_abilities()
	_draw_hand()
	log_message.emit("-- Your turn --")


## Every fielded creature ages up by one turn, then regenerates a fresh
## ability card for every ability it's had time to unlock -- ability
## index N unlocks once turns_on_field reaches N, so a 2-ability creature
## only offers its first move the turn after being summoned, and both
## from the turn after that. Bypasses HAND_SIZE the same way the initial
## on-summon ability card does (appended directly, not drawn) -- a full
## hand still crowds out that turn's normal draw via _draw_hand's own
## size check, exactly as before.
func _regenerate_field_abilities() -> void:
	var generated: Array[BaseCardData] = []
	for creature in field_creatures:
		if not creature.is_alive():
			continue
		creature.turns_on_field += 1
		for i in creature.data.abilities.size():
			if i <= creature.turns_on_field:
				generated.append(_make_ability_card(creature.data, creature.data.abilities[i], false))
	if not generated.is_empty():
		player_hand.append_array(generated)
		cards_drawn.emit(generated)


## Discards whatever's left in hand (Slay the Spire convention: unplayed
## cards don't carry over between turns).
func _discard_hand() -> void:
	for card in player_hand:
		player_discard.append(card)
	player_hand.clear()


## Draws up to HAND_SIZE cards. If the draw pile runs dry mid-draw, the
## discard pile is shuffled back into it and drawing continues -- the
## standard deckbuilder reshuffle.
func _draw_hand() -> void:
	var newly_drawn: Array[BaseCardData] = []
	while player_hand.size() < HAND_SIZE:
		if player_deck.is_empty():
			if player_discard.is_empty():
				break # nothing left anywhere to draw
			player_deck = player_discard.duplicate()
			player_deck.shuffle()
			player_discard.clear()
			log_message.emit("Reshuffled discard into the draw pile.")
		var card: BaseCardData = player_deck.pop_back()
		player_hand.append(card)
		newly_drawn.append(card)
	if not newly_drawn.is_empty():
		cards_drawn.emit(newly_drawn)


func _check_battle_over() -> void:
	if _all_defeated(enemy_team):
		is_over = true
		player_won = true
		log_message.emit("Enemy team defeated!")
	elif player_hp <= 0:
		is_over = true
		player_won = false
		log_message.emit("You were defeated...")


func _all_defeated(team: Array[BattleCombatant]) -> bool:
	for c in team:
		if c.is_alive():
			return false
	return true
