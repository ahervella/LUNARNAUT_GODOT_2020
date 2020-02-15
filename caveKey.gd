extends AnimatedSprite

#ALEJANDRO (Feb-14-2020)
#shitty. Gotta take out this process garbo and make this an
#interact script (like canister.gd, great example)
#This is also just for the first level as of date

var one_shot = true

func _ready():
	pass # Replace with function body.

func _process(delta):
	var vInteract = $"/root/Control/Cam2D/CanvasLayer/joyOut/joyIn".interacting()
	if ((global.get("pressing_e") or vInteract)and global.get("current_interact") == "key" and one_shot):
		use_key()

func use_key():
	self.set_animation("RED")
	one_shot = false