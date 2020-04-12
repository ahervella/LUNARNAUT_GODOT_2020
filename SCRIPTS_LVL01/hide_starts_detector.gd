extends Area2D

#ALEJANDRO (Feb-14-2020)
#this is the script for the detector of hiding the STARS,
#not "starts" (I fucked up and misnamed it and was too lazy to go
#back and fix, maybe I thought I'd remember? Either way, MUST CHANGE THE NAME
#to stars and fix all anything else that still has this name.
#At the bottom you'll see basically a couple node connections to hide the stars from
#rendering once the player reaches the bubble at which point it would be safe to hide them


func _ready():
	call_deferred('readyDeferred')

func readyDeferred():
	if (global.playTest):
		starsVisible(true)


func _on_hide_stars_detector_body_entered(body):
		
	var groups = body.get_groups()
	if (groups.has("astro")):
		var visibility = global.lvl().trigChunkNode.onRightSide(body, get_node("shape"))
		starsVisible(visibility)
		
func starsVisible(visibility):
		var bg_nodes = (get_tree().get_nodes_in_group("bg"))
		for i in bg_nodes:
			i.set_visible(visibility)






