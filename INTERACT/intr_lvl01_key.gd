extends "res://SCRIPTS/INTERACT/intr_default.gd"

func Interact():
	if hasRequiredItems():
		get_node("caveKeyColor").set_animation("RED")
	.Interact()
