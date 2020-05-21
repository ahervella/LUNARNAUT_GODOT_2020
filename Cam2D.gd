extends Camera2D

#used so astro can grab this
export (NodePath) var TOUCH_CONTROL_PATH = "CanvasLayer/touchControls"
onready var TOUCH_CONTROL_NODE = get_node(TOUCH_CONTROL_PATH)
export (bool) var touchControlsOn = false

const RED_FLASH_TIME = 1
const BLACK_FADE_TIME = 3
onready var blackOverlayNode = get_node("blackOverlay")
onready var hurtTintNode = get_node("hurtTint")
onready var gameOverTextNode = get_node("CanvasLayer/gameOverText")

func _ready():
	var cur_color = blackOverlayNode.get_modulate()
	var g = cur_color.g
	var r = cur_color.r
	var b = cur_color.b
	var a = cur_color.a
	blackOverlayNode.set_modulate( Color(r, g, b, 0))

	if touchControlsOn:
		TOUCH_CONTROL_NODE.activate()
	else:
		TOUCH_CONTROL_NODE.deactivate()

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
	
	
	
	
	
	
	
func CSWrapAddChanges(CSWrap : CharacterSwitchingWrapper):
	pass
	

	
func CSWrapApplyChanges(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	var camPosChange = CSWrap.changesToApply[currChar][0]
	
	
	var finalPos = get_global_position()
	if camPosChange!= null || camPosChange != Vector2(0, 0):
		finalPos += camPosChange
	
	set_global_position(finalPos)
	

func CSWrapApplyDependantChanges(CSWrap : CharacterSwitchingWrapper):
	pass


func CSWrapRecieveTransformChanges(CSWrap : CharacterSwitchingWrapper, currChar, posToAdd, rotToAdd):
	
	CSWrap.changesToApply[currChar].resize(2)
	
	if CSWrap.changesToApply[currChar][0] == null:
		CSWrap.changesToApply[currChar][0] = Vector2(0, 0)
		
	CSWrap.changesToApply[currChar][0] += posToAdd
