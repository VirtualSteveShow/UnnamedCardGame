extends Panel
## Procedural circular energy orb approximating Slay the Spire's glowing
## energy orb (outer ring + bright inner fill + count text), instead of
## a plain "Energy: 3/3" text label. No art asset -- built entirely from
## StyleBoxFlat circles since it's a simple, resolution-independent icon.

@onready var count_label: Label = $CountLabel


func set_energy(current: int, maximum: int) -> void:
	count_label.text = "%d/%d" % [current, maximum]
