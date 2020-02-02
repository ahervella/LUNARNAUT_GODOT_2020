extends Sprite

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	show()
	blinkOn()
	
func blinkOn():
	global.newTimerOLD(self, 2, true, "hide")
	global.newTimerOLD(self, 2.3, true, "show")
	global.newTimerOLD(self, 2.6, true, "hide")
	global.newTimerOLD(self, 2.9, true, "reset")
	
func reset():
	show()
	blinkOn()
	