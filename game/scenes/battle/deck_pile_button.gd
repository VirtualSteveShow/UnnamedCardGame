extends Button
## Visual draw-pile stack shown beside the hand row. Tap to open an
## overlay listing every card still left in the draw pile. Also doubles
## as the on-screen "origin point" battle.gd's draw animation flies
## cards away from -- see battle.gd's _fly_card_from_deck.

signal tapped

@onready var count_label: Label = $FrontPanel/CountLabel


func _ready() -> void:
	pressed.connect(func() -> void: tapped.emit())


func set_count(n: int) -> void:
	count_label.text = str(n)
