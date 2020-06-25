tool
extends "res://SCRIPTS/PLUGS_CABLES/plug.gd"

export (NodePath) var visitorDoorToUnlockPath
onready var visitorDoorToUnlock = get_node(visitorDoorToUnlockPath)

func receivedEntity(entity):
	if !Engine.editor_hint: return
	visitorDoorToUnlock.DOOR_LOCKED = false
	visitorDoorToUnlock.openDoor()

#func _ready(): 
#	if Engine.editor_hint: return
#	call_deferred("_readyEXT")

#func readyEXT():
#	if Engine.editor_hint: return
#	call_deferred("_readyEXT2")
#
#func _readyEXT2():
#	Interact()
