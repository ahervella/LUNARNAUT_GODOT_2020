extends Node2D


var astroChar
var refNode
var refIsRolling = false
var cswDependant
var diffPos
var astroCSW
var presentShit = []

func refNotNull():
	return refNode != null
	

func _init():
	presentShit = []
	refIsRolling = false
	set_physics_process(true)
	
	#print("ISET THE PROCESS TO TRUEEEEEEEEEEE")
	
func _physics_process(delta):
	if refNode != null && diffPos != null && is_instance_valid(refNode):
		if refIsRolling:
			set_global_position(refNode.get_global_position() + diffPos)
		else:
			set_global_position(refNode.get_global_position() + diffPos.rotated(refNode.get_global_rotation()))
		astroCSW.changesToApply[astroChar][0] = get_global_position()

func bodyEnteredArea(body):
	if illegalBody(body): return
	
	var lvl = global.lvl()
	var areaCSW = null
	
	if presentShit.has(body): return
	presentShit.append(body)
	
	for csw in lvl.charSwitchWrappers:
		if lvl.get_node(csw.nodePath) == body:
			areaCSW = csw
			break
	
	global.lvl().bodyEnteredTimeDiscrepArea(refNode, null, astroChar, areaCSW, body)
	
func bodyExitedArea(body):
	if illegalBody(body): return
	
	var lvl = global.lvl()
	var areaCSW = null
	
	if !presentShit.has(body): return
	presentShit.erase(body)
	
	for csw in lvl.charSwitchWrappers:
		if lvl.get_node(csw.nodePath) == body:
			areaCSW = csw
			break
	
	global.lvl().bodyExitedTimeDiscrepArea(refNode, null, astroChar, areaCSW, body)


func illegalBody(body):
	var lvl = global.lvl()
	if body == lvl.astroNode: return true
	if body == refNode: return
	if body.is_in_group("cablePoint"): return
	
