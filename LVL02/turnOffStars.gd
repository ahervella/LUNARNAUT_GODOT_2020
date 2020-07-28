extends Area2D




func _on_turnOffStars_body_exited(body):
	if !body.is_in_group("astro"): return

	enableMoonBG(astroOnLeft())

func astroOnLeft():
	return get_global_position().x > global.lvl().astroNode.get_global_position().x
	
func enableMoonBG(enable):
	global.lvl().astroNode.showMoonBG = enable
