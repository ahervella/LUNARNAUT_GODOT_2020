extends Node2D
#ALEJANDRO - Jun.7.2020:
#This mini script is attached to astro timediscrep areas when astro is ontop of
#a movable object in the future. Used to manage when and where it draws
#timeDiscrep 2D areas

var astroChar
var refNode
var refIsRolling = false
var cswDependant
var diffPos
var astroCSW
var presentShit = []
var copyAstroArea = null
var diactivated = false

func refNotNull():
	return refNode != null
	

func _init():
	diactivated = false
	presentShit = []
	
	#ended up not using but keeping in case
	refIsRolling = false
	
	connect("body_entered", self, "bodyEntered")
	connect("body_exited", self, "bodyExited")
	connect("area_entered", self, "areaEntered")
	connect("area_exited", self, "areaExited")
	set_physics_process(true)
	
	
func _physics_process(delta):
	if diactivated: return
	if refNode != null && diffPos != null && is_instance_valid(refNode):
		set_global_position(refNode.get_global_position() + diffPos)
		


func bodyEntered(body):
	if diactivated: return
	if presentShit.has(body): return
	if !bodyEnterExitCheck(body): return
	
	presentShit.append(body)
	if presentShit.size() == 1:
		addCopyArea()
	
func bodyExited(body):
	if diactivated: return
	if !presentShit.has(body): return
	if !bodyEnterExitCheck(body): return
	
	var prevSize = presentShit.size()
	presentShit.erase(body)
	presentShit.resize(prevSize-1)
	
	if presentShit.size() == 0: removeCopyArea()
	
		
	
func bodyEnterExitCheck(body):
	if illegalBody(body): return false
	
	var lvl = global.lvl()
	var bodyCSW = null
	
	for csw in lvl.charSwitchWrappers:
		if lvl.get_node(csw.nodePath) == body:
			bodyCSW = csw
			break
			
	if bodyCSW!= null:
		if !bodyCSW.checkIfInCharLvl(astroChar): return false
		
	return true
	
	
func areaEntered(areaNode, areaChar, areaCSW):
	if diactivated: return
	if presentShit.has(areaNode): return
	if !areaEnterExitCheck(areaNode, areaChar, areaCSW): return
	
	presentShit.append(areaNode)
	
func areaExited(areaNode, areaChar, areaCSW):
	if diactivated: return
	if !presentShit.has(areaNode): return
	if !areaEnterExitCheck(areaNode, areaChar, areaCSW): return
	
	presentShit.erase(areaNode)

func areaEnterExitCheck(areaNode, areaChar, areaCSW):
	var lvl = global.lvl()
	if areaChar != astroChar: return false
	if lvl.get_node(areaCSW.nodePath) == lvl.astroNode: return false
	return true

func illegalBody(body):
	var lvl = global.lvl()
	if body == lvl.astroNode: return true
	if body == refNode: return true
	if body.is_in_group("cablePoint"): return true
	return false
	


func addCopyArea():
	if copyAstroArea != null: return
	
	var lvl = global.lvl()
	copyAstroArea = Area2D.new()
	get_parent().add_child(copyAstroArea)
	copyAstroArea.set_owner(copyAstroArea)
	copyAstroArea.set_name(get_name() + "_COPY")
	copyAstroArea.set_global_position(get_global_position())
	
	for child in get_children():
		var dupChild = child.duplicate()
		var pos = child.get_position()
		var rot = child.get_rotation()
		var scale = child.get_global_scale()
		copyAstroArea.add_child(dupChild)
		dupChild.set_owner(copyAstroArea)
		
		dupChild.set_position(pos)
		dupChild.set_rotation(rot)
		dupChild.set_global_scale(scale)
	
	copyAstroArea.connect("body_entered", lvl, "bodyEnteredTimeDiscrepArea", [copyAstroArea, astroChar, astroCSW])
	copyAstroArea.connect("area_entered", lvl, "areaEnteredTimeDiscrepArea", [copyAstroArea, astroChar, astroCSW])
	copyAstroArea.connect("body_exited", lvl, "bodyExitedTimeDiscrepArea", [copyAstroArea, astroChar, astroCSW])
	copyAstroArea.connect("area_exited", lvl, "areaExitedTimeDiscrepArea", [copyAstroArea, astroChar, astroCSW])
	
	disconnect("body_entered", lvl, "bodyEnteredTimeDiscrepArea")
	disconnect("area_entered", lvl, "areaEnteredTimeDiscrepArea")
	disconnect("body_exited", lvl, "bodyExitedTimeDiscrepArea")
	disconnect("area_exited", lvl, "areaExitedTimeDiscrepArea")

	lvl.timeDiscrepCSWCharDict[astroCSW.nodePath][1][astroChar] = copyAstroArea.get_path()
	#lvl.astroNode.CSWrapSaveTimeDiscrepState(astroCSW, astroChar, true)
	astroCSW.savedTimeDiscrepencyState[astroChar] = []
	astroCSW.savedTimeDiscrepencyState[astroChar].resize(4)
	astroCSW.savedTimeDiscrepencyState[astroChar][0] = get_global_position()
	astroCSW.savedTimeDiscrepencyState[astroChar][1] = get_global_rotation()
	astroCSW.savedTimeDiscrepencyState[astroChar][2] = astroCSW.changesToApply[astroChar][2]
	astroCSW.savedTimeDiscrepencyState[astroChar][3] = false
	
func removeCopyArea():
	if copyAstroArea == null: return
	
	var lvl = global.lvl()
	connect("body_entered", lvl, "bodyEnteredTimeDiscrepArea", [self, astroChar, astroCSW])
	connect("area_entered", lvl, "areaEnteredTimeDiscrepArea", [self, astroChar, astroCSW])
	connect("body_exited", lvl, "bodyExitedTimeDiscrepArea", [self, astroChar, astroCSW])
	connect("area_exited", lvl, "areaExitedTimeDiscrepArea", [self, astroChar, astroCSW])
	
	var CAA = copyAstroArea
	CAA.get_parent().remove_child(CAA)
	CAA.queue_free()
	copyAstroArea = null
	lvl.astroNode.CSWrapSaveTimeDiscrepState(astroCSW, astroChar, false)

func disableActivity():
	var lvl = global.lvl()
	diactivated = true
	disconnect("body_entered", lvl, "bodyEnteredTimeDiscrepArea")
	disconnect("area_entered", lvl, "areaEnteredTimeDiscrepArea")
	disconnect("body_exited", lvl, "bodyExitedTimeDiscrepArea")
	disconnect("area_exited", lvl, "areaExitedTimeDiscrepArea")
	disconnect("body_entered", self, "bodyEntered")
	disconnect("body_exited", self, "bodyExited")
	disconnect("area_entered", self, "areaEntered")
	disconnect("area_exited", self, "areaExited")
	
	
