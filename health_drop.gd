extends Area2D

#ALEJANDRO (Feb-14-2020)
#This is a kinda garbo hard coded thing but kind of works
# for the bubble close to the cave entrance which drops your health
#once you go past it. This is done to make the player think tha
#your O2 is running out because of time (because you have progressed
#through the level), but in reality there is no time factor, just a
# a cheap trick to make the player worry. They can actually take as
#long as they want ;)

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
