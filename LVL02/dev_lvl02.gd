#tool
extends "res://SCRIPTS/lvl.gd"

export (NodePath) var generatorOutletPath = null
onready var generatorOutlet = get_node(generatorOutletPath)

export (NodePath) var labDoorPath = null
onready var labDoor = get_node(labDoorPath)

export (NodePath) var vcLightGroupPath = null
onready var vcLightGroup = get_node(vcLightGroupPath)

var generatorOn = false
var generatorConnected = false
export (bool) var visitorsCenterHasPower = false #setget vcPower
export (bool) var turnOffAutoCheck = false

func _ready():
#	generatorOutlet = get_node(generatorOutletPath)
#	labDoor = get_node(labDoorPath)
#	vcLightGroup = get_node(vcLightGroupPath)
	if visitorsCenterHasPower:
		visitorsCenterPowerOn()
	else:
		visitorsCenterPowerOff()


	audio.loadLevelSounds("lvl01", false)
	audio.sound("music", "lvl01").play(0)
	global.newTween(audio.sound("music", "lvl01"), "volume_db", -50, -4, 3, 0)
	
func _process(delta):
	if Engine.editor_hint || turnOffAutoCheck: return
	
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
	for light in vcLightGroup.get_children():
		light.show()
	
func visitorsCenterPowerOff():
	if Engine.editor_hint: return
	labDoor.DOOR_MANUAL_LOCK = true
	visitorsCenterHasPower = false
	
	for light in vcLightGroup.get_children():
		light.hide()
	
	
func vcPower(val):
	visitorsCenterHasPower = val
	if Engine.editor_hint: return
	if visitorsCenterHasPower:
		visitorsCenterPowerOn()






func _on_vcTransitionArea_body_entered(body):
	if !body.is_in_group("astro"): return
	
	global.controls_enabled = false
	astroNode.CAMERA_NODE.FadeIntoBlack()
	global.newTimer(astroNode.CAMERA_NODE.BLACK_FADE_TIME+2, funcref(self, "goToShuttleScene"))
	
func goToShuttleScene():
	global.controls_enabled = false
	global.goto_scene_via_shuttle("res://SCENES/main_menu.tscn", false)
	
	
	
	
	
	
