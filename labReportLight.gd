extends Sprite

#ALEJANDRO (Feb-14-2020)
#this is the script for the blinking lab light that gives the
#description of the nora alien in the blue lab on the right.
#all it does is use timers to control the blink. Should update
#to use the new timers (as seen below, still using old timers)

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
	