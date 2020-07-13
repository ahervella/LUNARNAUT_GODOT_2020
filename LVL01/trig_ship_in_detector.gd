extends Area2D

#ALEJANDRO (Feb-14-2020)
#(ALL FOR SHIP/LUNAR MODULE SPACECRAFt EXIT AT BEGINNING OF FIRST LEVEL)
#After checking the ship_out_detector file which I thought was also being
#Used, is just empty. Looks like all the ship in and out logic is done here
#and could probably use some cleaning and renaming the script to something better...
#Logic here works on mainly two bubbles near the entrance of the ship; one on the inside,
#the other on the outside. If astro is outside and falls in far enough, you see the inside of the
#ship, and vice versa for leaving. needed two so that hopping around the entrance
#wouldn't be freaking out with changing back and forth, b/c should only change when definitely
#know that astro will land inside or outside. See the entrance of the ship for bubble details

var in_inner_node = false
var in_outer_node = false
export (NodePath) var moduleOutsidePath
var moduleOutside

export (NodePath) var moduleOutside2Path
var moduleOutside2

export (NodePath) var moduleInsideShadowPath
var moduleInsideShadow

func _ready():
	moduleOutside = get_node(moduleOutsidePath)
	moduleOutside2 = get_node(moduleOutside2Path)
	moduleInsideShadow = get_node(moduleInsideShadowPath)
	call_deferred('readyDeferred')

func readyDeferred():
	if (global.playTest):
		out_ship_visibility(false)
	else:
		out_ship_visibility(true)
	

#Signal : When astro enters first detector
func _on_ship_out_detector_body_entered(body):
	
	var groups = body.get_groups()
	if (groups.has("astro")):
		in_outer_node = true
	out_ship_visibility(false)
		
#Signal : When astro exits first detector
func _on_ship_out_detector_body_exited(body):
	
	var groups = body.get_groups()
	if (groups.has("astro")):
		in_outer_node = false
	out_ship_visibility(true)
	
	

#Signal : When astro enters secoond (inner) detector
func _on_ship_in_detector_body_entered(body):
	var groups = body.get_groups()
	if (groups.has("astro")):
		in_inner_node = true
	out_ship_visibility(true)
		
#Signal : When astro exits secoond (inner) detector
func _on_ship_in_detector_body_exited(body):
	var groups = body.get_groups()
	if (groups.has("astro")):
		in_inner_node = false
	
	
	
	
#out_ship_visibility : Boolean -> Void
#trigger for when every astro enters or exits one of the detectors
func out_ship_visibility(thing):
	
	
	var out_ship_nodes = global.lvl(01).get_tree().get_nodes_in_group("out-ship")
	var bg_nodes = global.lvl(01).get_tree().get_nodes_in_group("bg")
	var moon_nodes = global.lvl(01).get_tree().get_nodes_in_group("moon_node")
	var black_node = get_tree().get_nodes_in_group("black")
	#var out_floor = get_node("/root/Control/stage/stage_floor")
	
	#if astro just jumped in or just jumped out
	
	#if (inner and outer and thing), or (inner and not outer and thing), or (not in either and not inner, which is for initial cond)
	if ((in_inner_node && in_outer_node && thing) or (in_inner_node && !in_outer_node && thing) or (!in_inner_node && !in_outer_node && !thing)):
		
		
		tween_exec(moduleOutside, 0)
		#moduleInsideShadow.show()
		#tween_exec(moduleInsideShadow, 0)
		
		for i in (bg_nodes):
			tween_exec(i, 0)
			
		#for i in (moon_nodes):
		#	tween_exec(i, 0)
		
			
		#for i in (out_ship_nodes):
		#	tween_exec(i,  0)
		
		#tween_exec(get_node(BLACK_NODE_PATH), 1)
		#disables moon ground floor so astro can go into ship
		#out_floor.set_disabled(true)
		
		
		
	if (in_inner_node && in_outer_node && !thing):
		#for i in (out_ship_nodes):
		#	tween_exec(i, 1)

		#for i in (moon_nodes):
		#	tween_exec(i, 1)
			
		tween_exec(moduleOutside, 1)
		#moduleInsideShadow.hide()
		for i in (bg_nodes):
			tween_exec(i, 1)
			
		#tween_exec(get_node(BLACK_NODE_PATH), 0)
		#disables moon ground floor so astro can go into ship
		#out_floor.set_disabled(false)
		
		
		
	
#tween_exec : Node, Tween_Node, Integer (1 or 0) -> Void
#is a shell that executes setting and playing tween with inputs determining the start
#or finish result of the alpha channel and tween path to use.
func tween_exec(node, startOrFin):
	var cur_color = node.get_modulate()
	var cur_g = cur_color.g
	var cur_r = cur_color.r
	var cur_b = cur_color.b
	var cur_a = cur_color.a
	
	
	if startOrFin:
		#moduleOutside.set_light_mask(64)
		global.newTween(node, "modulate", cur_color, Color(cur_r, cur_g, cur_b, startOrFin), 0.3, 0, funcref(self, "onFinishShowMoonPart"))
		#get_node(tween_node).interpolate_property(node, "modulate", cur_color, Color(cur_r, cur_g, cur_b, startOrFin), 0.3 , 0, Tween.EASE_OUT)
	else:
		onStartHideMoonPart()
		#moduleOutside.set_light_mask(64)
		global.newTween(node, "modulate", cur_color, Color(cur_r, cur_g, cur_b, startOrFin), 0.3, 0)
	
func onFinishShowMoonPart():
	moduleInsideShadow.hide()
	moduleOutside.hide()
	moduleOutside2.show()
	#moduleOutside.set_light_mask(65536 + 64)

func onStartHideMoonPart():
	moduleInsideShadow.show()
	moduleOutside.show()
	moduleOutside2.hide()
	#moduleOutside.set_light_mask(64)
