tool
extends "res://SCRIPTS/lvl.gd"

func _ready():
	
	#prevent from running in editor
	if Engine.editor_hint:
		return
	
	._ready()
	global.playTest = false
	#global.changeGrav(2, 90)
