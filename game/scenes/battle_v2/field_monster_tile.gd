extends Panel
## Read-only battlefield presence for a played monster in the hand-based
## combat prototype (BattleStateV2) -- shown purely as flavor/feedback for
## as long as at least one of the monster's ability cards is still in the
## player's hand, no HP, no tap interaction (abilities are played from
## hand, not by tapping the field). See battle_v2.gd's
## _on_creature_entered_field/_on_creature_left_field for the
## enter/flee animations that add and remove these tiles.

@onready var art_rect: TextureRect = $Art
@onready var name_label: Label = $NameLabel

var source_creature: CardData


func setup(card: CardData) -> void:
	source_creature = card
	art_rect.texture = card.get_battle_texture()
	name_label.text = card.card_name
