extends "res://SCRIPTS/INTERACT/intr_default.gd"

export (NodePath) var elevatorPath = null
export (NodePath) var elevatorLightsPath = null
export (NodePath) var camShakePath = null
export (NodePath) var lunarnautTextPath = null
onready var elevator = get_node(elevatorPath)
onready var elevatorLights = get_node(elevatorLightsPath)
onready var camShake = get_node(camShakePath)
onready var lunarnautText = get_node(lunarnautTextPath)

onready var textTween = Tween.new()
onready var textTweenFade = Tween.new()

onready var touchControlsTween = Tween.new()
onready var touchControlsTweenFade = Tween.new()

func _ready():
	for child in elevatorLights.get_children():
		child.set_enabled(false)

	camShake.get_child(0).set_disabled(true)
	
	add_child(textTween)
	add_child(textTweenFade)
	add_child(touchControlsTween)
	add_child(touchControlsTweenFade)
	
	lunarnautText.set_modulate(Color(1, 1, 1, 0))
	
	audio.loadLevelSounds("lvl02", false)
	
func Interact():
	
	if can_interact:
		elevator.movingPlatform = true
		interactNode.closeText()
	.Interact()
	
	for child in elevatorLights.get_children():
		child.set_enabled(true)
	
	camShake.get_child(0).set_disabled(false)
	
	
	textTween.interpolate_property(lunarnautText, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 10)
	textTweenFade.interpolate_property(lunarnautText, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 25)
	textTween.start()
	textTweenFade.start()
	
	var touchControlNode = global.lvl().astroNode.CAMERA_NODE.TOUCH_CONTROL_NODE
	
	touchControlsTween.interpolate_property(touchControlNode, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
	touchControlsTweenFade.interpolate_property(touchControlNode, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 28)
	touchControlsTween.start()
	touchControlsTweenFade.start()
	
	audio.sound("elevator", "lvl02").play()

	var sound = audio.sound("music", "lvl01")
	global.newTween(sound, "volume_db", sound.get_volume_db(), -30, 3, 0)
	global.newTween(sound, "volume_db", sound.get_volume_db(), -4, 6, 60)
