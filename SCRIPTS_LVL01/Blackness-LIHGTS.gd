extends Sprite

#ALEJANDRO (Feb-07-2020)
#used to make a fade transition with loading the
#first level. Specifically placed in the scene tree
# so that the lights appear first then the game

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var cur_color = self.get_modulate()
	var cur_g = cur_color.g
	var cur_r = cur_color.r
	var cur_b = cur_color.b
	var cur_a = cur_color.a
	self.show()
	
	#if in playtest mode, do nice tweens, else ignore, just instant alpha
	if (global.get("playtest")):
	
		var tweeny = Tween.new()
		add_child(tweeny)
		
		#if dev mode on:
		#global.set("controls_enabled", true)
		
		#last numbre is delay for starting tween
		tweeny.interpolate_property(self, "modulate", Color(cur_r, cur_g, cur_b,cur_a), Color(cur_r, cur_g, cur_b, 0), 3 , 0, Tween.EASE_OUT, 4)
	
		tweeny.connect("tween_completed", self, "on_tween_fin")
		tweeny.start()
	
	else:
		self.set_modulate( Color(cur_r, cur_g, cur_b, 0))
	
	
func on_tween_fin(object, key):
	if (global.set("playtest", true)):
		global.set("controls_enabled", true)

	
	#find way to delete tween node after tween fin?

