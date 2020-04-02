extends Camera2D

#used so astro can grab this
export (NodePath) var TOUCH_CONTROL_PATH = null

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
	

	 
