tool
extends Sprite

func _physics_process(delta):
	if !Engine.editor_hint:
		set_modulate(Color(1, 1, 1, 0))
	else:
		set_self_modulate(Color(1, 1, 1, 0))
