tool
extends "res://SCRIPTS/lvl.gd"

var grav = 0
var gravDiff = 0.1
func _ready():

	#prevent from running in editor
	if Engine.editor_hint:
		return
		
		
	
	consistentCharSet()
		

