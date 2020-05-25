tool
extends "res://SCRIPTS/lvl.gd"

	
func _ready():

	#prevent from running in editor
	if Engine.editor_hint:
		return
	
	#._ready()
	global.playTest = false
	if global.CharacterRes.id == global.CHAR.RUS:
		global.changeGrav(2, -15)
	else:
		global.changeGrav(1, 15, 1)
