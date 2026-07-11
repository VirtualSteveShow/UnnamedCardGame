class_name AbilityCardData
extends BaseCardData
## A hand card generated when a captured-monster card is played in the
## hand-based combat prototype (BattleStateV2 -- see docs/gameplay-notes.md's
## "Experimental Mode" section for the full design). Represents one of that
## monster's abilities, playable on its own once it's in hand: playing it
## shows the source monster's battle sprite performing the move, resolves
## the ability's effect, then discards -- the same single-use lifecycle an
## item card already has.
##
## card_name/art_texture/energy_cost (from BaseCardData) are set at
## creation time from source_creature and ability, not authored directly.

@export var source_creature: CardData
@export var ability: CardAbility
