extends Control
## Debug tool: flips through every generated background image full-
## screen so they can be reviewed without hunting through each scene
## individually (or gambling on which of the 3 random Deck Battle
## variants shows up). Reached from the Options screen; not part of the
## normal player-facing flow.
##
## For the three battle variants specifically, overlays a mock player
## panel + one field creature + one enemy at the exact same anchors
## battle_v2.tscn uses, so grounding/scale can actually be judged in the
## context they'll be seen in, not just as a bare picture.

const BACKGROUNDS := [
	"res://assets/backgrounds/title_bg.png",
	"res://assets/backgrounds/options_bg.png",
	"res://assets/backgrounds/card_browser_bg.png",
	"res://assets/backgrounds/map_bg.png",
	"res://assets/backgrounds/battle_bg_backyard.png",
	"res://assets/backgrounds/battle_bg_street.png",
	"res://assets/backgrounds/battle_bg_park.png",
]

@onready var art_rect: TextureRect = $ArtRect
@onready var name_label: Label = $NameLabel
@onready var prev_button: Button = $PrevButton
@onready var next_button: Button = $NextButton
@onready var back_button: Button = $BackButton

@onready var battle_mock: Control = $BattleMock
@onready var mock_player_panel := $BattleMock/MockPlayerPanel
@onready var mock_field_tile := $BattleMock/MockFieldRow/MockFieldTile
@onready var mock_enemy_tile := $BattleMock/MockEnemyRow/MockEnemyTile

var _index := 0


func _ready() -> void:
	prev_button.pressed.connect(func() -> void: _step(-1))
	next_button.pressed.connect(func() -> void: _step(1))
	back_button.pressed.connect(_on_back_pressed)

	var house_cat := CardDatabase.get_real_creature_by_name("House Cat")
	mock_field_tile.setup(BattleCombatant.new(house_cat))
	mock_player_panel.refresh(20, 20, 0)

	var rabbit := CardDatabase.get_real_creature_by_name("Rabbit")
	mock_enemy_tile.setup(BattleCombatant.new(rabbit))

	_show_current()


func _step(delta: int) -> void:
	_index = (_index + delta + BACKGROUNDS.size()) % BACKGROUNDS.size()
	_show_current()


func _show_current() -> void:
	var path: String = BACKGROUNDS[_index]
	art_rect.texture = load(path)
	name_label.text = "%d/%d   %s" % [_index + 1, BACKGROUNDS.size(), path.get_file()]
	battle_mock.visible = path.get_file().begins_with("battle_bg_")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options/options_screen.tscn")
