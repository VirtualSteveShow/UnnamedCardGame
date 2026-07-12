extends Node
## Autoload singleton (registered in project.godot as "Run") holding
## state for the current run across scene changes between the map and
## battle scenes -- the player's persistent deck, which nodes are
## cleared/unlocked, and creatures captured along the way.
##
## Deliberately a straight line of nodes for this first pass, not a
## branching path -- see docs/gameplay-notes.md's Run Structure section
## for the branching-path recommendation this is a step toward. This is
## just enough to playtest the "fight, capture, fight again with a
## bigger deck" loop across more than one battle. Player HP also resets
## fresh at the start of every node for now; carrying HP (and its
## attrition tension) across nodes is a natural next step once this
## basic loop is proven out, not built yet.

signal run_started
signal node_cleared(node_index: int)

const STARTING_CREATURES := ["House Cat", "Squirrel"]
const STARTING_ITEMS := ["Cat Carrier", "Band-Aid"]

## Each node is just its enemy roster for now -- Dictionaries, matching
## the lightweight data-driven convention CardDatabase.REAL_CREATURES
## already uses, rather than a new Resource type for a single field.
var nodes: Array[Dictionary] = [
	{enemy_names = ["Rabbit"]},
	{enemy_names = ["Robin", "Hamster"]},
	{enemy_names = ["Rabbit", "Robin"]},
	{enemy_names = ["Hamster", "Squirrel"]},
	{enemy_names = ["Rabbit", "Robin", "Hamster"]},
]

var active: bool = false
var deck: Array[BaseCardData] = []
var current_node_index: int = -1
var cleared_node_indices: Array[int] = []


## Starts a fresh run, discarding anything from a previous one -- there's
## no save/resume concept yet, so pressing Battle on the title screen
## always begins again from node 0 with a fresh starting deck.
func start_new_run() -> void:
	active = true
	current_node_index = -1
	cleared_node_indices.clear()
	deck = _build_starting_deck()
	run_started.emit()


func _build_starting_deck() -> Array[BaseCardData]:
	var cards: Array[BaseCardData] = []
	for creature_name in STARTING_CREATURES:
		cards.append(CardDatabase.get_real_creature_by_name(creature_name))
	for item_name in STARTING_ITEMS:
		for item in ItemDatabase.get_item_cards():
			if item.card_name == item_name:
				cards.append(item)
				break
	return cards


func is_node_unlocked(index: int) -> bool:
	return index == 0 or cleared_node_indices.has(index - 1)


func is_node_cleared(index: int) -> bool:
	return cleared_node_indices.has(index)


func is_run_complete() -> bool:
	return cleared_node_indices.size() >= nodes.size()


func enter_node(index: int) -> void:
	current_node_index = index


func current_node_enemy_names() -> Array:
	if current_node_index < 0 or current_node_index >= nodes.size():
		return []
	return nodes[current_node_index].get("enemy_names", [])


func clear_current_node() -> void:
	if current_node_index >= 0 and not cleared_node_indices.has(current_node_index):
		cleared_node_indices.append(current_node_index)
		node_cleared.emit(current_node_index)


## Called when a capture item successfully takes a creature -- adds it
## straight to the run's deck so it can be drawn in later battles.
func add_captured_creature(card: CardData) -> void:
	deck.append(card)
