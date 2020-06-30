tool
extends "res://SCRIPTS/lvl.gd"

export (NodePath) var generatorOutletPath = null
onready var generatorOutlet = get_node(generatorOutletPath)

export (NodePath) var labDoorPath = null
onready var labDoor = get_node(labDoorPath)

var generatorOn = false
var generatorConnected = false
export (bool) var visitorsCenterHasPower = false setget vcPower


func _process(delta):
	if Engine.editor_hint: return
	
	#if power off
	if !visitorsCenterHasPower:
		if !generatorConnected && generatorOutlet.connPlug != null:
			var signalResult = generatorOutlet.transmitEntity("power_signal")
			if signalResult is bool && signalResult:
				generatorConnected = true
				
		if generatorOn && generatorConnected:
			visitorsCenterPowerOn()
	
	
	#if power on, make sure shit still good
	else:
		var signalResult = generatorOutlet.transmitEntity("power_signal")
		if !signalResult is bool || !signalResult:
			generatorConnected = false
			
		if !generatorOn || !generatorConnected:
			visitorsCenterPowerOff()

func visitorsCenterPowerOn():
	if Engine.editor_hint: return
	labDoor.DOOR_MANUAL_LOCK = false
	visitorsCenterHasPower = true
	
func visitorsCenterPowerOff():
	if Engine.editor_hint: return
	labDoor.DOOR_MANUAL_LOCK = true
	visitorsCenterHasPower = false
	
	
func vcPower(val):
	visitorsCenterHasPower = val
	if Engine.editor_hint: return
	if visitorsCenterHasPower:
		visitorsCenterPowerOn()
