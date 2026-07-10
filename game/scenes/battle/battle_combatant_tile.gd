extends Button
## One creature's card on the battlefield -- used for both the player's
## row and the enemy's row, since they're structurally identical (art,
## name, HP bar, block). A plain Button is fine here (unlike the card
## browser's tiles) since this scene has no scrolling to fight with.
##
## Purely a display + tap-to-select surface: it doesn't know whether a
## tap means "pick this as my acting creature" or "pick this as my
## attack's target" -- battle.gd owns that interpretation and just
## listens for `tapped`.

signal tapped(combatant: BattleCombatant)

@onready var art_rect: TextureRect = $Art
@onready var name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HpBar
@onready var status_label: Label = $StatusLabel
@onready var selection_overlay: ColorRect = $SelectionOverlay

var combatant: BattleCombatant


func _ready() -> void:
	pressed.connect(func() -> void: tapped.emit(combatant))


func setup(c: BattleCombatant) -> void:
	combatant = c
	art_rect.texture = c.data.get_display_texture()
	name_label.text = c.data.card_name
	refresh()


## Called after any battle action so every tile stays in sync with the
## current HP/block/alive state.
func refresh() -> void:
	hp_bar.max_value = combatant.data.max_health
	hp_bar.value = combatant.current_hp

	var text := "%d/%d HP" % [combatant.current_hp, combatant.data.max_health]
	if combatant.block > 0:
		text += "  ·  Block %d" % combatant.block
	status_label.text = text

	var alive := combatant.is_alive()
	modulate = Color.WHITE if alive else Color(0.35, 0.35, 0.35)
	disabled = not alive


func set_selected(selected: bool) -> void:
	selection_overlay.visible = selected
