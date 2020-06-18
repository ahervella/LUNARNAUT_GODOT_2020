extends Area2D


func _on_trig_EndOfDemoArea_body_entered(body):
	if(body.get_groups().has("astro")):
		var lvl = global.lvl(01)
		var astro = lvl.astroNode
		if astro.dead || astro.preDeath: return
		global.controls_enabled = false
		lvl.noraNode.deactivate()
		
		astro.CAMERA_NODE.FadeIntoBlack(true)
		
