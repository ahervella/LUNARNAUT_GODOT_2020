tool
extends "res://SCRIPTS/PROTO_BLOCK_BASE.gd"

onready var savedCollShape = get_child(0)
#var timer

func fallThrough():
	if Engine.editor_hint: return
	set_collision_layer_bit(0, false)
	set_collision_mask_bit(0, false)
	#remove_from_group("solid")
	global.newTimer(2, funcref(self, "fallThroughReset"))
	
func fallThroughReset():
	if Engine.editor_hint: return
	set_collision_layer_bit(0, true)
	set_collision_mask_bit(0, true)
	#add_to_group("solid")
