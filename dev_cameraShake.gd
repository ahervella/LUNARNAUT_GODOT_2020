extends "res://SCRIPTS/lvl.gd"

func _ready():
	call_deferred("_ready_deferred")
	
func _ready_deferred():
	pass
	#astroNode.CAMERA_NODE.shake(global.SHAKE.MED, 1)
