extends "res://SCRIPTS/lvl.gd"

var grav = 0
var gravDiff = 0.5
export (bool) var rotateGravity = false

func _physics_process(delta):
		physicsProcessOn = rotateGravity
		grav += gravDiff
		global.changeGrav(1, grav, delta)
