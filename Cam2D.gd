extends Camera2D

#used so astro can grab this
export (NodePath) var TOUCH_CONTROL_PATH = "CanvasLayer/touchControls"
export (NodePath) var TIMELINE_LABEL_PATH = "CanvasLayer/timelineLabel"
onready var TOUCH_CONTROL_NODE = get_node(TOUCH_CONTROL_PATH)
onready var TIMELINE_LABEL_NODE = get_node(TIMELINE_LABEL_PATH)
export (bool) var touchControlsOn = false
export (bool) var timelineLabelOn = false
export (bool) var disableCSTouchButton = false

const RED_FLASH_TIME = 1
const BLACK_FADE_TIME = 3
onready var blackOverlayNode = get_node("CanvasLayer/blackOverlay")
onready var hurtTintNode = get_node("CanvasLayer/hurtTint")
onready var gameOverTextNode = get_node("CanvasLayer/gameOverText")

func _ready():

	blackOverlayNode.set_modulate( Color(0, 0, 0, 1))

	if touchControlsOn:
		TOUCH_CONTROL_NODE.activate()
	else:
		TOUCH_CONTROL_NODE.deactivate()
		
	if disableCSTouchButton:
		TOUCH_CONTROL_NODE.deactivateCS()
	else:
		TOUCH_CONTROL_NODE.activateCS()
		
	if timelineLabelOn:
		TIMELINE_LABEL_NODE.show()
	else:
		TIMELINE_LABEL_NODE.hide()
		
	call_deferred("readyExt")
	
func readyExt():
	if global.playTest:
		FadeOutOfBlack()
		#blackOverlayNode.set_modulate( Color(0, 0, 0, 0))
	else:
		
		blackOverlayNode.set_modulate( Color(0, 0, 0, 0))

func deathRedness():
	var cur_color = hurtTintNode.get_modulate()#$"/root/Control/Cam2D/hurtTint".get_modulate()
	var g = cur_color.g
	var r = cur_color.r
	var b = cur_color.b
	var a = cur_color.a
	
	global.newTween(hurtTintNode, "modulate", Color(r, g, b, a), Color(r, g, b, 1), 3, 0)

func TakeDamageFlash():
	
	var cur_color = hurtTintNode.get_modulate()
	var g = cur_color.g
	var r = cur_color.r
	var b = cur_color.b
	var a = cur_color.a
	
	global.newTween(hurtTintNode, "modulate", Color(r, g, b, a), Color(r, g, b, 0.7), (RED_FLASH_TIME/2.0), 0, funcref(self, "TakeDamageFlashReverse"))
	#last numbre is delay for starting tween
	#global.newTween(self, "modulate", Color(r, g, b), Color(r, 0, 0), 0.5, 0, funcref(self, "TakeDamageFlashReverse"))

func TakeDamageFlashReverse():
	
	var cur_color = hurtTintNode.get_modulate()
	var g = cur_color.g
	var r = cur_color.r
	var b = cur_color.b
	var a = cur_color.a
	
	global.newTween(hurtTintNode, "modulate", Color(r, g, b, a), Color(r, g, b, 0), (RED_FLASH_TIME/2.0), 0)
	
	#global.newTween(self, "modulate", Color(r, 0, 0), Color(r, g, b), 0.5, 0.5)
	
func FadeOutOfBlack():
	
	var cur_color = blackOverlayNode.get_modulate()
	var g = cur_color.g
	var r = cur_color.r
	var b = cur_color.b
	var a = cur_color.a
	
	global.newTween(blackOverlayNode, "modulate", Color(r, g, b, 1), Color(r, g, b, 0), BLACK_FADE_TIME, 0)

func FadeIntoBlack(wonBool = null):
	
	var cur_color = blackOverlayNode.get_modulate()
	var g = cur_color.g
	var r = cur_color.r
	var b = cur_color.b
	var a = cur_color.a
	
	
	global.newTween(blackOverlayNode, "modulate", Color(r, g, b, 0), Color(r, g, b, 1), BLACK_FADE_TIME, 0)
	
	if (wonBool == null):
		return
		#for now for testing
		
	
	gameOverTextNode.animateText(wonBool)
		#global.newTween(
	#last numbre is delay for starting tween
	#global.newTween(self, "modulate", Color(r, g, b), Color(r, 0, 0), 0.5, 0, funcref(self, "TakeDamageFlashReverse"))
	





func CSWrapSaveStartState(CSWrap):
	pass
	
	
	
	
	
	
	
func CSWrapAddChanges(CSWrap):
	var currChar = global.currCharRes.id
	
	CSWrap.changesToApply[currChar] = get_global_position()
	#CSWrap.changesToApply[currChar][1] = 0
	

	
func CSWrapApplyChanges(CSWrap):
	var currChar = global.currCharRes.id
	
	#to change the camera position immediately on frame one
	print(get_global_position())
	set_enable_follow_smoothing(false)
	set_global_position(CSWrap.changesToApply[currChar])
	call_deferred("secondDefferedCamPos")
	print(get_global_position())
	
func secondDefferedCamPos(inhh = 0):
	yield(get_tree(),"physics_frame")
	call_deferred("set_enable_follow_smoothing", true)
	

func CSWrapApplyDependantChanges(CSWrap):
	pass

