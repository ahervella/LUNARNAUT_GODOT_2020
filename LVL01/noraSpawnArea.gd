extends Area2D

#ALEJANDRO (Feb-14-2020)
#this is the script for knowing when to spawn our monster nora when our
#astronaut enters a bubble within the lab to trigger it! (For level 1)

var one_shot = true

func _ready():
	pass

func _on_noraSpawnArea_body_entered(body):
	var groups = body.get_groups()
	if(groups.has("astro") && one_shot):
		one_shot = false
		global.lvl(1).spawnNora = true
