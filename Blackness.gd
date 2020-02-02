extends Sprite



# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var one_shot = true
# Called when the node enters the scene tree for the first time.
func _ready():
	
	var cur_color = self.get_modulate()
	var cur_g = cur_color.g
	var cur_r = cur_color.r
	var cur_b = cur_color.b
	var cur_a = cur_color.a
	self.show()
	
	
	if (global.get("playtest") == true):
		var tweenyy = Tween.new()
		add_child(tweenyy)
		
		#last numbre is delay for starting tween
		tweenyy.interpolate_property(self, "modulate", Color(cur_r, cur_g, cur_b,cur_a), Color(cur_r, cur_g, cur_b, 0), 3 , 0, Tween.EASE_OUT, 2)
		
		tweenyy.start()
		
		#find way to delete tween node after tween fin?
		
	else:
		self.set_modulate( Color(cur_r, cur_g, cur_b, 0))

func _on_EndOfDemoArea_body_entered(body):
	var groups = body.get_groups()
	if (groups.has("astro") && one_shot && !global.get("astroDead")):
		one_shot = false
		
		$"/root/Control/astro".fadeOutSound()
		global.controls_enabled = false
		startEndDemoBlacknessTween(true)
	
func startEndDemoBlacknessTween(won):
	var cur_color = self.get_modulate()
	var cur_g = cur_color.g
	var cur_r = cur_color.r
	var cur_b = cur_color.b
	var cur_a = cur_color.a
	var tweeny = Tween.new()
	add_child(tweeny)
	
	#delay time before start of tween
	var delayTime
	
	if(won):
		delayTime = 1
	else:
		delayTime = 3
	
	tweeny.interpolate_property(self, "modulate", Color(cur_r, cur_g, cur_b, 0), Color(cur_r, cur_g, cur_b, 1), 2 , 0, Tween.EASE_OUT, delayTime)
	tweeny.start()

	get_node("/root/Control/Cam2D/CanvasLayer/DemoText").onGameOver(won)
	get_node("/root/Control/Cam2D/CanvasLayer/AnyButtonText").onGameOver(won)
		

