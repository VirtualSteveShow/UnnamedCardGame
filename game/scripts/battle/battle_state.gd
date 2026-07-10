class_name BattleState
extends RefCounted
## Pure combat logic for a team-vs-team battle -- no UI references, just
## state and rules, so the Battle scene can stay a thin presentation
## layer over this. See docs/gameplay-notes.md for what's still not
## built (per-creature ability kits, a real "build your deck" flow,
## enemy-side deck/hand).
##
## The player's whole deck (creature cards AND item cards mixed
## together in one pile, per design direction) is drawn from into a
## hand each turn. Playing a creature card from hand summons it onto
## the field (the player's team starts *empty* and grows as cards are
## played, unlike the enemy team which is just a fixed roster already
## in play). Playing an item card resolves its effect immediately and
## goes to the discard pile; a summoned creature does NOT go to
## discard when played, only when it's later defeated in battle (its
## CardData returns to the discard pile at that point, modeling "the
## card comes back to you, just battered"). The enemy side has no
## deck/hand of its own -- it's a fixed encounter, matching how Slay
## the Spire itself treats enemies vs. the player's deck.
##
## Turn structure (Slay the Spire's convention): a player turn refills
## the shared energy pool, clears every player creature's block, and
## draws a fresh hand (discarding whatever was left unplayed from the
## previous turn first). After the player ends their turn, every
## surviving enemy creature takes one automatic turn in order (its
## block clears first, then it uses a random ability of its own
## against a random living player creature). Block absorbs damage
## before HP does, and always clears at the start of its owner's own
## next turn -- not immediately when the turn that granted it ends --
## so it still protects against the very next incoming hit.

const ENERGY_PER_TURN := 3
const HAND_SIZE := 5

signal log_message(text: String)
signal state_changed
## Emitted right after a creature is summoned onto the player's team,
## so the UI can add a field tile for it without polling every frame.
signal creature_summoned(combatant: BattleCombatant)

var player_deck: Array[BaseCardData] = []
var player_hand: Array[BaseCardData] = []
var player_discard: Array[BaseCardData] = []

var player_team: Array[BattleCombatant] = []
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
	_draw_hand()


## True if the card is affordable and playable right now. Doesn't check
## card-specific requirements (e.g. an item needing a valid target) --
## callers check those separately before actually resolving the play.
func can_play_card(card: BaseCardData) -> bool:
	return is_player_turn and not is_over and energy >= card.energy_cost and player_hand.has(card)


## Summons a creature card from hand onto the player's field. Returns
## the new BattleCombatant (also broadcast via creature_summoned) so
## the UI can add a tile for it, or null if the play wasn't legal.
func play_creature_card(card: CardData) -> BattleCombatant:
	if not can_play_card(card):
		return null

	energy -= card.energy_cost
	player_hand.erase(card)
	var combatant := BattleCombatant.new(card)
	player_team.append(combatant)
	log_message.emit("%s enters the fight!" % card.card_name)
	creature_summoned.emit(combatant)
	state_changed.emit()
	return combatant


## Plays an item card from hand. target is one of your own creatures
## for healing, or an enemy creature for capture attempts. Always
## consumes the card into the discard pile once played, regardless of
## whether a capture attempt actually succeeds (matches the "one use
## per battle" flavor the capture cards were designed with).
func play_item_card(card: ItemCardData, target: BattleCombatant) -> void:
	if not can_play_card(card) or target == null:
		return

	energy -= card.energy_cost
	player_hand.erase(card)
	player_discard.append(card)

	match card.item_type:
		ItemCardData.ItemType.HEALING:
			var healed: int = mini(card.heal_amount, target.data.max_health - target.current_hp)
			target.current_hp += healed
			log_message.emit("%s used %s, healing %s for %d HP." % [
				"You", card.card_name, target.data.card_name, healed])
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


func can_use_ability(source: BattleCombatant, ability: CardAbility) -> bool:
	return is_player_turn and not is_over and source.is_alive() and energy >= ability.energy_cost


## target is only required for damaging abilities; pass null for a
## block-only ability.
func use_creature_ability(source: BattleCombatant, ability: CardAbility, target: BattleCombatant) -> void:
	if not can_use_ability(source, ability):
		return

	energy -= ability.energy_cost
	source.block += ability.block
	if ability.damage > 0 and target != null:
		var dealt := target.take_damage(ability.damage)
		log_message.emit("%s used %s on %s for %d damage!" % [source.data.card_name, ability.ability_name, target.data.card_name, dealt])
	else:
		log_message.emit("%s used %s and gained %d block." % [source.data.card_name, ability.ability_name, ability.block])

	_check_battle_over()
	state_changed.emit()


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

		var living_targets: Array[BattleCombatant] = []
		for p in player_team:
			if p.is_alive():
				living_targets.append(p)
		if living_targets.is_empty():
			break

		var ability: CardAbility = enemy.data.abilities[randi() % enemy.data.abilities.size()]
		var target: BattleCombatant = living_targets[randi() % living_targets.size()]
		enemy.block += ability.block
		if ability.damage > 0:
			var dealt := target.take_damage(ability.damage)
			log_message.emit("%s used %s on %s for %d damage!" % [enemy.data.card_name, ability.ability_name, target.data.card_name, dealt])
		else:
			log_message.emit("%s used %s and gained %d block." % [enemy.data.card_name, ability.ability_name, ability.block])
		_check_battle_over()

	if not is_over:
		_start_player_turn()
	state_changed.emit()


func _start_player_turn() -> void:
	for p in player_team:
		p.block = 0
	energy = ENERGY_PER_TURN
	is_player_turn = true
	_draw_hand()
	log_message.emit("-- Your turn --")


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
	while player_hand.size() < HAND_SIZE:
		if player_deck.is_empty():
			if player_discard.is_empty():
				break # nothing left anywhere to draw
			player_deck = player_discard.duplicate()
			player_deck.shuffle()
			player_discard.clear()
			log_message.emit("Reshuffled discard into the draw pile.")
		player_hand.append(player_deck.pop_back())


func _check_battle_over() -> void:
	if _all_defeated(enemy_team):
		is_over = true
		player_won = true
		log_message.emit("Enemy team defeated!")
	elif _all_defeated(player_team):
		is_over = true
		player_won = false
		log_message.emit("Your team was defeated...")


## A team that's empty (no creature summoned yet) is not "defeated" --
## just not fielding anyone yet. Only a team that fielded at least one
## creature and lost all of them counts.
func _all_defeated(team: Array[BattleCombatant]) -> bool:
	if team.is_empty():
		return false
	for c in team:
		if c.is_alive():
			return false
	return true
