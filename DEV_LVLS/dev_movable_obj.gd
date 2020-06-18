tool
extends "res://SCRIPTS/lvl.gd"

	
func _ready():

	#prevent from running in editor
	if Engine.editor_hint:
		return
	
	
	consistentCharSet()
