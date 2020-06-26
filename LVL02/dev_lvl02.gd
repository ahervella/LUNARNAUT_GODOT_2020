tool
extends "res://SCRIPTS/lvl.gd"

export (NodePath) var generatorOutletPath = null
onready var generatorOutlet = get_node(generatorOutletPath)

export (NodePath) var labDoorPath = null
onready var labDoor = get_node(labDoorPath)

var generatorOn = false
var generatorConnected = false
var labDoorUnlocked = false
var visitorsCenterHasPower = false


func _process(delta):
	if Engine.editor_hint: return
	
	if !visitorsCenterHasPower:
		if !generatorConnected && generatorOutlet.connPlug != null:
			if generatorOutlet.transmitEntity("power_signal"):
				generatorConnected = true
				
		if generatorOn && generatorConnected && !labDoorUnlocked:
			visitorsCenterPowerOn()

func visitorsCenterPowerOn():
	if Engine.editor_hint: return
	labDoor.DOOR_MANUAL_LOCK = false
	visitorsCenterHasPower = true
