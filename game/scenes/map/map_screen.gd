extends Control
## Bare-bones linear run map: a row of battle nodes, tap an unlocked one
## to fight it. No branching yet -- see docs/gameplay-notes.md's Run
## Structure section for the eventual branching-path plan; this is just
## enough to playtest deck persistence and creature capture across more
## than one battle.

const COLOR_CLEARED := Color(0.4, 0.85, 0.4)
const COLOR_LOCKED := Color(0.5, 0.5, 0.5)

@onready var node_row: HBoxContainer = $CenterContainer/NodeRow
@onready var status_label: Label = $StatusLabel
@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	Run.node_cleared.connect(func(_index: int) -> void: _rebuild_nodes())
	_rebuild_nodes()


func _rebuild_nodes() -> void:
	for child in node_row.get_children():
		child.queue_free()

	for i in Run.nodes.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(110, 110)
		button.add_theme_font_size_override("font_size", 32)

		if Run.is_node_cleared(i):
			button.text = "✓"
			button.disabled = true
			button.modulate = COLOR_CLEARED
		elif Run.is_node_unlocked(i):
			button.text = str(i + 1)
			button.pressed.connect(_on_node_pressed.bind(i))
		else:
			button.text = str(i + 1)
			button.disabled = true
			button.modulate = COLOR_LOCKED

		node_row.add_child(button)

	status_label.text = "Run complete! Every node cleared." if Run.is_run_complete() \
		else "Tap a node to fight it."


func _on_node_pressed(index: int) -> void:
	Run.enter_node(index)
	get_tree().change_scene_to_file("res://scenes/battle_v2/battle_v2.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")
