extends Control
## Boot / root scene for Unnamed Card Game.
##
## Right now this scene only exists to (1) prove the project boots correctly
## on both desktop and mobile with the landscape + multi-aspect-ratio
## settings configured in project.godot, and (2) keep the version number
## visible at all times per project requirement #5. Real gameplay (starting
## with the card browser) will replace/extend this scene next.

@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	# Pull the version from project.godot's [application] config/version
	# field instead of hardcoding it here, so bumping the version in one
	# place (Project Settings > Application > Config > Version) is enough
	# to keep every in-game display in sync automatically.
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	version_label.text = "v%s" % version
