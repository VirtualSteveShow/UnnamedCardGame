extends Panel
## Battlefield presence for a played creature in the hand-based combat
## prototype (BattleStateV2) -- shown for as long as the creature is
## alive, with a slim HP bar matching enemy_tile_v2's convention. No tap
## interaction -- abilities are played from hand, not by tapping the
## field. See battle_v2.gd's _on_creature_entered_field/
## _on_creature_left_field for the enter/defeat animations that add and
## remove these tiles.

@onready var art_rect: TextureRect = $Art
@onready var name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HpBar

var combatant: BattleCombatant

var _hp_bg_style: StyleBoxFlat
var _hp_fill_style: StyleBoxFlat

## Matches enemy_tile_v2's always-red HP bar convention rather than the
## green/yellow/red scheme the non-StS-styled tiles elsewhere use.
const HP_COLOR := Color(0.8, 0.2, 0.2)


func _ready() -> void:
	IdleBob.start(art_rect)

	_hp_bg_style = StyleBoxFlat.new()
	_hp_bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	_hp_bg_style.corner_radius_top_left = 4
	_hp_bg_style.corner_radius_top_right = 4
	_hp_bg_style.corner_radius_bottom_left = 4
	_hp_bg_style.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("background", _hp_bg_style)

	_hp_fill_style = StyleBoxFlat.new()
	_hp_fill_style.bg_color = HP_COLOR
	_hp_fill_style.corner_radius_top_left = 4
	_hp_fill_style.corner_radius_top_right = 4
	_hp_fill_style.corner_radius_bottom_left = 4
	_hp_fill_style.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("fill", _hp_fill_style)


func setup(c: BattleCombatant) -> void:
	combatant = c
	art_rect.texture = c.data.get_battle_texture()
	name_label.text = c.data.card_name
	refresh()


func refresh() -> void:
	hp_bar.max_value = combatant.data.max_health
	hp_bar.value = combatant.current_hp
