extends Area2D

var one_shot = true

func _ready():
	pass

func _on_noraSpawnArea_body_entered(body):
	var groups = body.get_groups()
	if(groups.has("astro") && one_shot):
		one_shot = false
		global.spawnNora = true
