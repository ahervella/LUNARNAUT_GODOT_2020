extends Area2D

# class member variables go here, for example:
# var a = 2
var one_shot = true

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_health_drop_body_entered(body):
	var groups = body.get_groups()
	if (groups.has("astro") and one_shot):
		one_shot = false
		$"/root/Control/astro".dec_health()
