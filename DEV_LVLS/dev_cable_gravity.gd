tool
extends "res://SCRIPTS/lvl.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	#prevent from running in editor
	if Engine.editor_hint:
		return
	
	consistentCharSet()
