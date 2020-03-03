#extends Area2D

#ALEJANDRO (Feb-14-2020)
#I believe I switched all the ship in and out detection logic to
#just ship_in. Should probably go clean that up and then delete this
#Keeping for ref incase any shit is needed

#
#var detector_pos
#var astro_pos
#
#func _ready():
#	detector_pos = get_node("out_detector_shape").get_global_position()
#	astro_pos = get_node("/root/Control/astro").get_global_position()
#
#
#func _on_ship_out_detector_body_entered(body):
#	var groups = body.get_groups()
#	if (groups.has("astro")) and (detector_pos.y > astro_pos.y):
#		out_ship_visibility(true)
#
#
#func out_ship_visibility(visi):
#	var out_ship_nodes = (get_tree().get_nodes_in_group("out-ship"))
#	var bg_nodes = get_tree().get_nodes_in_group("bg")
#	for i in (out_ship_nodes):
#		i.set_visible(visi)
#
#	for i in (bg_nodes):
#		i.set_visible(visi)
#