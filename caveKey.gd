extends AnimatedSprite

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