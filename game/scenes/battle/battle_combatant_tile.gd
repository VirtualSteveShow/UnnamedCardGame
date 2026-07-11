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

## Built once and mutated per-refresh rather than a single shared/theme
## resource -- each tile needs its own fill color, and StyleBoxFlat is a
## Resource (shared by reference) unless duplicated per instance.
var _hp_bg_style: StyleBoxFlat
var _hp_fill_style: StyleBoxFlat

const HP_COLOR_HIGH := Color(0.3, 0.8, 0.3)
const HP_COLOR_MID := Color(0.9, 0.75, 0.2)
const HP_COLOR_LOW := Color(0.85, 0.25, 0.25)


func _ready() -> void:
	pressed.connect(func() -> void: tapped.emit(combatant))

	_hp_bg_style = StyleBoxFlat.new()
	_hp_bg_style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	_hp_bg_style.corner_radius_top_left = 6
	_hp_bg_style.corner_radius_top_right = 6
	_hp_bg_style.corner_radius_bottom_left = 6
	_hp_bg_style.corner_radius_bottom_right = 6
	_hp_bg_style.border_width_left = 2
	_hp_bg_style.border_width_right = 2
	_hp_bg_style.border_width_top = 2
	_hp_bg_style.border_width_bottom = 2
	_hp_bg_style.border_color = Color(0, 0, 0, 0.8)
	hp_bar.add_theme_stylebox_override("background", _hp_bg_style)

	_hp_fill_style = StyleBoxFlat.new()
	_hp_fill_style.corner_radius_top_left = 6
	_hp_fill_style.corner_radius_top_right = 6
	_hp_fill_style.corner_radius_bottom_left = 6
	_hp_fill_style.corner_radius_bottom_right = 6
	hp_bar.add_theme_stylebox_override("fill", _hp_fill_style)


## facing_left: true for the enemy side, so a battle sprite drawn facing
## right (the shared convention every side-view sprite is generated in)
## mirrors to face the player side instead of facing off the edge of the
## screen. Purely a flip -- no separate "facing left" art needed.
func setup(c: BattleCombatant, facing_left: bool = false) -> void:
	combatant = c
	art_rect.texture = c.data.get_battle_texture()
	art_rect.flip_h = facing_left
	name_label.text = c.data.card_name
	refresh()


## Called after any battle action so every tile stays in sync with the
## current HP/block/alive state.
func refresh() -> void:
	hp_bar.max_value = combatant.data.max_health
	hp_bar.value = combatant.current_hp

	var hp_fraction := float(combatant.current_hp) / float(combatant.data.max_health)
	if hp_fraction > 0.6:
		_hp_fill_style.bg_color = HP_COLOR_HIGH
	elif hp_fraction > 0.25:
		_hp_fill_style.bg_color = HP_COLOR_MID
	else:
		_hp_fill_style.bg_color = HP_COLOR_LOW

	var text := "%d/%d HP" % [combatant.current_hp, combatant.data.max_health]
	if combatant.block > 0:
		text += "  ·  Block %d" % combatant.block
	status_label.text = text

	var alive := combatant.is_alive()
	modulate = Color.WHITE if alive else Color(0.35, 0.35, 0.35)
	disabled = not alive


func set_selected(selected: bool) -> void:
	selection_overlay.visible = selected
