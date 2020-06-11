tool
extends "res://SCRIPTS/lvl.gd"

	
func _ready():

	#prevent from running in editor
	if Engine.editor_hint:
		return
		
	for charResPath in global.astroCharDict.values():
		var charRes = load(charResPath)
		charRes.level = getLvlSceneName()#"dev_movable_obj"
		ResourceSaver.save(charResPath, charRes)
	#._ready()
#	global.playTest = false
#	if global.CharacterRes.id == global.CHAR.RUS:
#		global.changeGrav(2, -15)
#	else:
#		global.changeGrav(1, 45, 1)
