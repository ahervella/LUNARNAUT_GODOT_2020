extends Area2D


func _on_trig_EndOfDemoArea_body_entered(body):
	if(body.get_groups().has("astro")):
		global.lvl().gameWon()
		global.controls_enabled = false
