tool
extends "res://SCRIPTS/lvl.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	#prevent from running in editor
	if Engine.editor_hint:
		return
	
	for charResPath in global.astroCharDict.values():
		var charRes = load(charResPath)
		   #ResourceSaver.save
		charRes.level = "dev_cable_gravity"
		ResourceSaver.save(charResPath, charRes)
	
	._ready()
	global.playTest = false
	#global.changeGrav(2, 45)


