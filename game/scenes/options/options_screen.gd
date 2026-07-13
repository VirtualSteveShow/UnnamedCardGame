extends Control
## Bare-bones placeholder -- no real settings live here yet, just the
## hub-and-spoke Back button and a dev-only background viewer link.

@onready var back_button: Button = $BackButton
@onready var background_viewer_button: Button = $BackgroundViewerButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	background_viewer_button.pressed.connect(_on_background_viewer_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title/title_screen.tscn")


func _on_background_viewer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/debug/background_viewer.tscn")
