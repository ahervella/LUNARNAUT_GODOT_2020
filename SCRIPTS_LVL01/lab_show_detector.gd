extends Area2D

#ALEJANDRO (Feb-14-2020)
#This the script for the bubble in the tunnel on route
#towards the red lab. This is used to control when to hide it
#so that when the player is traversing other parts of the cave
#it will not appear (although layers normally solve this problem,
#because of how the lab is set up to be ontop of astro due to lights
#and the walls, I cannot place it behind our main character, so instead
#I use this method to turn it off. Works fine.)
#TODO: clean this up a bit


var show_lab = false

func _ready():
	call_deferred('readyDeferred')

func readyDeferred():
	pass
	
	#var lab_nodes = (get_tree().get_nodes_in_group("lab"))
	#for i in lab_nodes:
	#	i.set_visible(show_lab)
	
	#global.lvl(1).noraNode.hide()


func _on_lab_show_detector_body_entered(body):
	
	#just so for testing and not having to go all the way from the top to hide the stars
	get_parent().get_node("chunk_hide_stars")._on_hide_stars_detector_body_entered(body)
	
	#print("we're in")
	var groups = body.get_groups()
	if (groups.has("astro")):
		show_lab = !global.lvl().trigChunkNode.onRightSide(body, get_node("shape"))
	
		print("show lab")
		print(show_lab)
	
		global.lvl(1).noraNode.show()
	
	
		var lab_nodes = (global.lvl(01).get_tree().get_nodes_in_group("lab"))
		for i in lab_nodes:
			i.set_visible(show_lab)
			
		#fix for lab above shit, and activated in interact script
		
		#global.lvl(1).get_node("lab_above/lab_above_1").hide()
		
		#done by hide_stars detector
		#var bg_nodes = (get_tree().get_nodes_in_group("bg"))
		#for i in bg_nodes:
		#	i.set_visible(hide_bg)
