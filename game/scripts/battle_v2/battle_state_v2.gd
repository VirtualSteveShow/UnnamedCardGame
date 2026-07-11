class_name BattleStateV2
extends RefCounted
## Combat logic for the "hand-based" combat prototype -- see
## docs/gameplay-notes.md's Experimental Mode section for the full design
## rationale. A deliberately PARALLEL system to BattleState, not a
## replacement or refactor of it: nothing here is shared with or touches
## the original battlefield combat, so that mode stays fully intact and
## playable exactly as before.
##
## The core difference from BattleState: captured creatures don't have HP
## and never get summoned onto a persistent battlefield. Playing a
## creature card discards it immediately and generates one
## AbilityCardData per ability it has directly into hand (bypassing the
## draw pile -- these are freshly created, not drawn). Playing one of
## those ability cards resolves its effect (damage to a chosen enemy, or
## block for the player) then discards, same single-use lifecycle an item
## card already has. There's no "select a creature, then pick its
## ability" step anymore since abilities ARE hand cards now -- every
## playable card just gets tapped directly, optionally followed by a
## target tap for damaging effects.
##
## The player has a personal HP/block pool instead of a battlefield of
## creatures; enemies attack that pool directly. Enemies themselves are
## unchanged from BattleState -- same fixed HP-based roster (BattleCombatant),
## same turn structure -- only their target changed.

const ENERGY_PER_TURN := 3
const HAND_SIZE := 5
const PLAYER_MAX_HP := 30

signal log_message(text: String)
signal state_changed
## Emitted after any draw (initial hand, a turn's refill, OR a creature
## card releasing its ability cards into hand) with just the newly added
## cards -- not the whole hand -- so the UI can play a deck-to-hand (or
## hand-internal) animation for exactly what's new.
signal cards_drawn(cards: Array[BaseCardData])
## Emitted right when an ability card resolves, before state_changed, so
## the UI can play a "the monster pops out and attacks" animation using
## the source creature's battle sprite before the damage/log updates land.
signal ability_played(card: AbilityCardData, target: BattleCombatant)

var player_deck: Array[BaseCardData] = []
var player_hand: Array[BaseCardData] = []
var player_discard: Array[BaseCardData] = []

var player_hp: int = PLAYER_MAX_HP
var player_max_hp: int = PLAYER_MAX_HP
var player_block: int = 0

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


## Playing a creature card doesn't summon it -- it's discarded immediately
## and one AbilityCardData per ability it has is created straight into
## hand instead, so each of the creature's moves becomes its own playable
## card.
func play_creature_card(card: CardData) -> void:
	if not can_play_card(card):
		return

	energy -= card.energy_cost
	player_hand.erase(card)
	player_discard.append(card)

	var generated: Array[BaseCardData] = []
	for ability in card.abilities:
		var ability_card := AbilityCardData.new()
		ability_card.source_creature = card
		ability_card.ability = ability
		ability_card.card_name = "%s: %s" % [card.card_name, ability.ability_name]
		ability_card.art_texture = card.get_battle_texture()
		ability_card.energy_cost = ability.energy_cost
		player_hand.append(ability_card)
		generated.append(ability_card)

	log_message.emit("%s's moves enter your hand!" % card.card_name)
	if not generated.is_empty():
		cards_drawn.emit(generated)
	state_changed.emit()


## Resolves a generated ability card: damage lands on target (required for
## damaging abilities), block adds to the player's own block pool. Always
## consumes the card into discard once played.
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
	player_block += ability.block
	if ability.damage > 0:
		var dealt := target.take_damage(ability.damage)
		log_message.emit("%s used %s on %s for %d damage!" % [
			card.source_creature.card_name, ability.ability_name, target.data.card_name, dealt])
	else:
		log_message.emit("%s used %s -- you gained %d block." % [
			card.source_creature.card_name, ability.ability_name, ability.block])

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
			var dealt := _damage_player(ability.damage)
			log_message.emit("%s used %s on you for %d damage!" % [enemy.data.card_name, ability.ability_name, dealt])
		else:
			log_message.emit("%s used %s and gained %d block." % [enemy.data.card_name, ability.ability_name, ability.block])
		_check_battle_over()

	if not is_over:
		_start_player_turn()
	state_changed.emit()


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
