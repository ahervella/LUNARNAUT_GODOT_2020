extends Area2D


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






