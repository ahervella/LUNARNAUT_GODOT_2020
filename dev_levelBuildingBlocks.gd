extends "res://SCRIPTS/lvl.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	._ready()
	global.playTest = false
	global.changeGrav(2, 45)


