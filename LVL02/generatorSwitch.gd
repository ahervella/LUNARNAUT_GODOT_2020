extends "res://SCRIPTS/INTERACT/intr_default.gd"

func Interact():
	if can_interact:
		set_rotation(deg2rad(200))
		global.lvl().generatorOn = true
	.Interact()
	

