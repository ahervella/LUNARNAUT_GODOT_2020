extends Area2D

#ALEJANDRO (Feb-14-2020)
#this is the script for the detector of hiding the STARS,
#not "starts" (I fucked up and misnamed it and was too lazy to go
#back and fix, maybe I thought I'd remember? Either way, MUST CHANGE THE NAME
#to stars and fix all anything else that still has this name.
#At the bottom you'll see basically a couple node connections to hide the stars from
#rendering once the player reaches the bubble at which point it would be safe to hide them


var hide_starts = true
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	pass
#	print(self)
#
#	connect("body_entered", self, "shtuff_entered")
#	#get_tree().call_group("astro", "hide_show_lab", self)
##	self.connect("area_exited", self, "updateShtuff")
#	# Called every time the node is added to the scene.
#	# Initialization here
#	pass
#
#
#func shtuff_entered(blah):
#	print(blah)
#	var detector_pos = get_node("detector_shape").get_global_position()
#	var astro_pos = get_node("/root/Control/astro").get_global_position()
#	show_lab = ((detector_pos.x - astro_pos.x)>0)
#
#	print (detector_pos.x - astro_pos.x)
#	print(show_lab)
#
#	var lab_nodes = (get_tree().get_nodes_in_group("lab"))
#	for i in lab_nodes:
#		i.set_visible(show_lab)
		

#func hide_show_lab(lab):
#
#	#if self.get_global_position() > get_node("/root/Control/astro").get_global_position():
#	print(lab)
#	print("got it")
##	print("tdrytfuygiuhoi")
#		#get_node(thing).show
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _on_hide_stars_detector_body_entered(body):
	pass # Replace with function body.
	#print("we're in")
	var groups = body.get_groups()
	if (groups.has("astro")):
		var detector_pos = get_node("detector_shape").get_global_position()
		var astro_pos = get_node("/root/Control/astro").get_global_position()
		hide_starts = ((detector_pos.x - astro_pos.x)<0)
	
			
		var bg_nodes = (get_tree().get_nodes_in_group("bg"))
		for i in bg_nodes:
			i.set_visible(hide_starts)

func _on_hide_stars_detector_body_exited(body):
	var groups = body.get_groups()
	if (groups.has("astro")):
		var detector_pos = get_node("detector_shape").get_global_position()
		var astro_pos = get_node("/root/Control/astro").get_global_position()
		hide_starts = ((detector_pos.x - astro_pos.x)>0)
	
			
		var bg_nodes = (get_tree().get_nodes_in_group("bg"))
		for i in bg_nodes:
			i.set_visible(hide_starts)






