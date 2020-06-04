tool
extends Node

#ALEJANDRO (Feb-23-2020)
#This is the node from which to extend level nodes, which basically makes sure each level has the basic
#requirments needed to start the level properly. 
export (bool) var playTest = false
export (NodePath) var astroNodePath = null
export (Array, Resource) var startingInventory
var astroNode
export (NodePath) var trigChunkNodePath = null
#export (global.CHAR) var character
export (bool) var CSWrapsAddAstroAndCam = false setget setAddAstroAndCam
export (bool) var CSWrapsAddAll1stGenChildNodes = false setget setAddAllChildNodes
export (bool) var CSWrapsClearAllNodes = false setget setClearAllNodes
export (Array, Resource) var charSwitchWrappers# setget registerNodes

var testBool = true


var trigChunkNode
var ASTRO_GLOBAL_START_POS : Vector2
var ASTRO_FACE_RIGHT : bool
var ASTRO_HEALTH : int

var CAM_GLOBAL_START_POS : Vector2

var levelNodes : Dictionary

var Inventory : Dictionary

var oneShotAddAstroAndCam = true

var readyDone = false
var oneShotFrameWait = false
var processDone = false

#the node that is the parent of all timeDiscrepAreas
var timeDiscrepParentNode
#keeps track of the area2D node that belongs to the cs wrap and astroChars
#var timeDiscrepAreaBodyDict = {}

#var timeDiscrepCSWDict = {}

var timeDiscrepCSWCharDict = {}

var timeDiscrepAstroShapes = {}
var timeDiscrepAstroShapesCOPIES = {}
const timeDiscrepAstroScript = preload("res://SCRIPTS/astro_timeDiscrepArea.gd")

#keeps track of the in which areas the object body is present in
#var timeDiscrepBodyPresentDict = {}
var timeDiscrepBodyPresentDict2 = {}
var timeDiscrepManuallyRemovingArea = []
var timeDiscrepRemovingArea

func setAddAstroAndCam(garboVal):
	if !Engine.editor_hint:
		return
	if !readyDone: return
	addAstroAndCamPerChar()
	
func setAddAllChildNodes(garboVal):
	if !Engine.editor_hint:
		return
	#if !readyDone: return
	
	addAstroAndCamPerChar()
	
	for child in get_children():
		#print(child.get_name())
		if child.get_name() == "InteractFont" : continue
		var alreadyPresent = false
		
		for resNode in charSwitchWrappers:
			if get_node(resNode.nodePath) == child:
				alreadyPresent = true
				break
				
		if !alreadyPresent:
			var childRes = CharacterSwitchingWrapper.new()
			#name can actually act as a readable node path
			
			
			#print("name, then path")
			var nodePath =  child.get_path()
			#print(child.get_name())
			#print(nodePath)
			#var actualNodePath = getActualNodePath(nodePath)
			childRes.nodePath = getActualNodePath(child.get_path())
			print("groups:")
			print(child.get_groups())
			for group in child.get_groups():
				childRes.groups.append(group)
				print("group")
				print(group)
			print (childRes.groups)
			for childChild in child.get_children():
				if childChild is CollisionShape2D:
					for group in childChild.get_groups():
						childRes.groups.append(group)
					childRes.nodeCollShapePaths.resize(childRes.nodeCollShapePaths.size()+1)
					var index = childRes.nodeCollShapePaths.size() -1
					childRes.nodeCollShapePaths[index] = getActualNodePath(childChild.get_path())
					
				if childChild is StaticBody2D:
					for childChildChild in childChild.get_children():
						if childChildChild is CollisionShape2D:
							for group in childChildChild.get_groups():
								childRes.groups.append(group)
							#var childCollpath = nodePath + "/" + childChild.get_name() + "/" + childChildChild.get_name()
							childRes.nodeCollShapePaths.resize(childRes.nodeCollShapePaths.size() + 1)
							var index = childRes.nodeCollShapePaths.size()-1
							
							childRes.nodeCollShapePaths[index] = getActualNodePath(childChildChild.get_path())#NodePath(childCollpath)

			if !child.has_method("CSWrapSaveStartState"):
				childRes.staticNode = true
			charSwitchWrappers.append(childRes)


func getActualNodePath(nodePath : NodePath):
	var topNodeNameIndex = null
	for i in nodePath.get_name_count():
		#print(i)
		#print(nodePath.get_name(i))
		if nodePath.get_name(i) == get_name():
			topNodeNameIndex = i
			break
	
	var newPath = "/root"
	for k in (nodePath.get_name_count()-topNodeNameIndex):
		newPath = newPath +  "/" + nodePath.get_name(k+topNodeNameIndex)
	
	#print(newPath)
	return (NodePath(newPath))

func addAstroAndCamPerChar():
	if !Engine.editor_hint:
		return

	var astroPresent = false
	var camPresent = false
	
	var astro = get_node(astroNodePath)
	var camNode
			
	for child in get_children():
		if child is Camera2D:
			camNode = child 
	
	
	for csWrap in charSwitchWrappers:
		if get_node(csWrap.nodePath) == astro || csWrap.nodePath == "astro":
			astroPresent = true
		
		if get_node(csWrap.nodePath) == camNode || csWrap.nodePath == "Cam2D":
			camPresent = true
			
	
	if !astroPresent:
		var astroCharRes = CharacterSwitchingWrapper.new()
		astroCharRes.nodePath = getActualNodePath(astroNode.get_path())
		print("groups:")
		print(astroNode.get_groups())
		for group in astroNode.get_groups():
			print("group:")
			print(group)
			astroCharRes.goups.append(group)
		for child in astro.get_children():
			if child is CollisionShape2D:
				
				astroCharRes.nodeCollShapePaths.resize(astroCharRes.nodeCollShapePaths.size() + 1)
				var index = astroCharRes.nodeCollShapePaths.size() -1
				astroCharRes.nodeCollShapePaths[index] = getActualNodePath(child.get_path())#NodePath(astroNode.get_name() + "/" + nodePath)
				break
				
		charSwitchWrappers.append(astroCharRes)
	
	if !camPresent:
		var camCharRes = CharacterSwitchingWrapper.new()
		camCharRes.nodePath = getActualNodePath(camNode.get_path())#camNode.get_name()
		for group in camNode.get_groups():
			camCharRes.goups.append(group)
		charSwitchWrappers.append(camCharRes)

	
func setClearAllNodes(garboVal):
	#var size = charSwitchWrappers.size()
	for node in charSwitchWrappers:
		if node == null:
			continue
		
		node.nodeCollShapePaths.resize(0)
	charSwitchWrappers.resize(0)


func _physics_process(delta):
	if Engine.editor_hint:
		readyDone = true
		return

	if readyDone && !processDone && oneShotFrameWait:
		loadCSWrappersFromGlobal()
		addCSWrapperTimeDiscrepencyAreas()
		
		removeDisabledCSWrapperNodes()
		restoreCSWrapperState()
		#restoreExtraCSWrapperState()
		applyCSWrapperChanges()
		saveCSWrapperStartStates()
		processDone = true
		set_physics_process(false)
		print("iosudhfaiusdhfiaushdfiaushdfisuhf")

	elif readyDone && !oneShotFrameWait:
		oneShotFrameWait = true


func _ready():
	#prevent from running in editor
	if Engine.editor_hint:
		readyDone = true
		return
	
#	var blah = PackedScene.new()
#	blah.pack(self)
#	ResourceSaver.save("res://name2.tscn", blah)
#	#blah.free()
	
#	applyCSWrapperChanges(0.017)
#	saveCSWrapperStartStates()
#	removeDisabledCSWrapperNodes()


	
	global.playTest = playTest
	astroNode = get_node(astroNodePath)
	if (trigChunkNodePath != null):
		trigChunkNode = get_node(trigChunkNodePath)
	global.interactNode = astroNode.INTERACT_TEXT_NODE
	
	readyDone = true

func loadCSWrappersFromGlobal():
	if global.CharacterRes == null: return
	var currLvlPath = global.getScenePath(global.CharacterRes.level)
	var currChar = global.CharacterRes.id
	
	if global.levelWrapperDict.has(currLvlPath):
		if global.levelWrapperDict[currLvlPath].gravity.has(currChar):
			var gravMag = global.levelWrapperDict[currLvlPath].gravity[currChar][0]
			var gravDeg = global.levelWrapperDict[currLvlPath].gravity[currChar][1]
			global.changeGrav(gravMag, gravDeg, 0)
		
		if global.levelWrapperDict[currLvlPath].lvlNodesCSWrapDict.has(currChar):
			charSwitchWrappers = global.levelWrapperDict[currLvlPath].lvlNodesCSWrapDict[currChar]




func addCSWrapperTimeDiscrepencyAreas():
	if global.CharacterRes == null: return
	
	var currChar = global.CharacterRes.id
	var currLvlPath = global.getScenePath(global.CharacterRes.level)
	
			
	timeDiscrepParentNode = Node.new()
	timeDiscrepParentNode.set_name("TIME_DISCREP")
#	timeDiscrepArea = Area2D.new()
	add_child(timeDiscrepParentNode)
	timeDiscrepParentNode.set_owner(self)


	for csw in charSwitchWrappers:
		checkNodePathsAreCorrect(csw)
		
		var csNode = get_node(csw.nodePath)
		var timeDiscrepCSWNode = Node.new()
		timeDiscrepCSWNode.set_name("TIME_DISCREP_" + csNode.get_name())
		timeDiscrepParentNode.add_child(timeDiscrepCSWNode)
		timeDiscrepCSWNode.set_owner(timeDiscrepParentNode)
		timeDiscrepCSWCharDict[csw.nodePath] = [timeDiscrepCSWNode.get_path(), {}]
		
		for astroChar in csw.changesToApply.keys():
			addCSWrapCollShape2DiscrepArea(csw, astroChar, null)
	
	print("done")


func checkNodePathsAreCorrect(csw : CharacterSwitchingWrapper):
	if csw.nodePath.get_name(0) != "root":
		csw.nodePath = correctNodePath(csw.nodePath)
		
	for k in csw.nodeCollShapePaths.size():
		var ncsp = csw.nodeCollShapePaths[k]
		if ncsp.get_name(0) != "root":
			csw.nodeCollShapePaths[k] = correctNodePath(ncsp)
		
func correctNodePath(np : NodePath):
	var nodePathAsString = ""
	for i in np.get_name_count():
		nodePathAsString = nodePathAsString + "/" + np.get_name(i)
		
	var newPathAsString = "/root/" + get_name() + nodePathAsString
	
	return NodePath(newPathAsString)

func addCSWrapCollShape2DiscrepArea(csWrap, astroChar, areaCSW, interactWithOthers : bool = true):
	var currChar = global.CharacterRes.id
	var cswNode = get_node(csWrap.nodePath)#find_node(csWrap.nodePath, true, false)
	
	
	if global.charYearDict[astroChar] <= global.charYearDict[currChar]: return false
	if csWrap.staticNode && csWrap.checkIfInCharLvl(currChar): return false
	
	#if !csWrap.checkIfInCharLvl(astroChar): return false
	
	
	#if the item exiting does not exist in the astroChar timeline, ignore
	if !csWrap.checkIfInCharLvl(astroChar): return false
	
	#if the area exiting from does not exist in the astroChar timeline, ignore
	if areaCSW != null && !areaCSW.checkIfInCharLvl(astroChar): return false
	
	#if the item entering is still present in other timeDicrep areas for said timeline, don't add a new spot because one already exists
	if timeDiscrepBodyPresentDict2.has(cswNode.get_name()) && timeDiscrepBodyPresentDict2[cswNode.get_name()].has(astroChar) && timeDiscrepBodyPresentDict2[cswNode.get_name()][astroChar].size() > 1:
		return false
	
	if timeDiscrepCSWCharDict.has(csWrap.nodePath) && timeDiscrepCSWCharDict[csWrap.nodePath][1].has(astroChar): return false
	
	
	if !interactWithOthers:
		if !timeDiscrepCSWCharDict.has(csWrap.nodePath):
			timeDiscrepCSWCharDict[csWrap.nodePath] = [csWrap.get_path(), {}]
		if !timeDiscrepCSWCharDict[csWrap.nodePath][1].has(astroChar):
			timeDiscrepCSWCharDict[csWrap.nodePath][1][astroChar] = "noArea"
		return true
		
	var cswTimeDiscrepNode = get_node(timeDiscrepCSWCharDict[csWrap.nodePath][0])
	
	var areaNode = null
	
	for collShape in csWrap.nodeCollShapePaths:
		var collShapeNode = get_node(collShape)
		#if collShapeNode == null: collShapeNode = cswNode.get_node(collShape)
		#if collShapeNode == null: collShapeNode = find_node(collShape, true, false)
		#if collShapeNode == null: collShapeNode = cswNode.find_node(collShape, true, false)
		
		var collShapeNodePos = collShapeNode.get_position()
		var collShapeNodeRot = collShapeNode.get_rotation()
		var collShapeNodeScale = collShapeNode.get_global_scale()
		#assuming every csw will have position has 0 index, and rot as 1
		#TODO: need to make more flexible
		
		var parentNodePos
		var parentNodeRot
		
		if areaCSW == null:
			if csWrap.changesToApply[astroChar] == null || csWrap.changesToApply[astroChar] == []:
				#var cswNode = get_node(csWrap.nodePath)
				csWrap.changesToApply[astroChar].resize(2)
				csWrap.changesToApply[astroChar][0] = cswNode.get_global_position()
				csWrap.changesToApply[astroChar][1] = cswNode.get_global_rotation()
				
			parentNodePos = csWrap.changesToApply[astroChar][0]
			parentNodeRot = csWrap.changesToApply[astroChar][1]
		
		var collShapeNodeDup = collShapeNode.duplicate() #duplicate(DUPLICATE_USE_INSTANCING)
		collShapeNodeDup.set_name("TIME_DISCREP_SHAPE_%s_%s_%s" % [csWrap.nodePath, global.astroChar2String(astroChar), collShapeNode.get_name()])
		
		if !timeDiscrepCSWCharDict[csWrap.nodePath][1].has(astroChar):
			areaNode = Area2D.new()
			areaNode.set_name("TIME_DISCREP_AREA_%s_%s" % [csWrap.nodePath, global.astroChar2String(astroChar)])
			cswTimeDiscrepNode.add_child(areaNode)
			areaNode.set_owner(cswTimeDiscrepNode)
			
			
			
			if cswNode == astroNode:
				if csWrap.dependantCSWrappers[astroChar].size() > 0:
					timeDiscrepAstroShapes[astroChar] = areaNode
					areaNode.set_script(load(global.getScriptPath("astro_timeDiscrepArea.gd")))#set_script(timeDiscrepAstroScript)#
					areaNode.astroChar = astroChar
					areaNode.astroCSW = csWrap
					areaNode.cswDependant = csWrap.dependantCSWrappers[astroChar][csWrap.dependantCSWrappers[astroChar].size()-1]
					areaNode.add_to_group("astroTimeDiscrep")
					
			if timeDiscrepAstroShapes.has(astroChar):
				var astroArea = timeDiscrepAstroShapes[astroChar]
				if astroArea.cswDependant == csWrap:
					

					
					if astroArea.diffPos == null:
						astroArea.diffPos = astroArea.astroCSW.changesToApply[astroChar][0] - csWrap.changesToApply[astroChar][0]
					timeDiscrepAstroShapes[astroChar].refIsRolling = cswNode.is_in_group("object") && cswNode.roll
					
					#if just loading scene
					if astroArea.refNode == null:
						astroArea.refNode = areaNode
					
					#combination was previously on node and 
					else:
						astroArea.disconnect("body_entered", astroArea, "bodyEnteredArea")
						astroArea.disconnect("body_exited", astroArea, "bodyExitedArea")
						var prevRef = astroArea.refNode
						astroArea.remove_from_group("astroTimeDiscrep")
						astroArea.refNode = areaNode
						
						parentNodePos = cswNode.get_global_position()
						parentNodeRot = cswNode.get_global_rotation()
						
						#in initiating this method, the cswNode had the initial already added to it
						# so need to take it out to set up correctly
						if (astroArea.presentShit.size() > 0 
							&& timeDiscrepBodyPresentDict2.has(cswNode.get_name()) 
							&& timeDiscrepBodyPresentDict2[cswNode.get_name()].has(astroChar) 
							&& timeDiscrepBodyPresentDict2[cswNode.get_name()][astroChar].has(astroArea.presentShit[0])):
							
								timeDiscrepBodyPresentDict2[cswNode.get_name()][astroChar].erase(astroArea.presentShit[0])
								astroArea.presentShit = []
								

						
						var astroAreaCOPY = astroArea.duplicate()
						
						astroAreaCOPY.diffPos = astroArea.diffPos
						astroAreaCOPY.cswDependant = astroArea.cswDependant
						astroAreaCOPY.refIsRolling = astroArea.refIsRolling
						astroAreaCOPY.astroChar = astroArea.astroChar
						astroAreaCOPY.astroCSW = astroArea.astroCSW
						
						astroAreaCOPY.set_name(astroArea.get_name()+"_COPY")
						astroArea.get_parent().add_child(astroAreaCOPY)
						astroAreaCOPY.set_owner(astroArea.get_parent())
						
						astroAreaCOPY.disconnect("body_entered", self, "bodyEnteredTimeDiscrepArea")
						astroAreaCOPY.disconnect("area_entered", self, "areaEnteredTimeDiscrepArea")
						astroAreaCOPY.disconnect("body_exited", self, "bodyExitedTimeDiscrepArea")
						astroAreaCOPY.disconnect("area_exited", self, "areaExitedTimeDiscrepArea")
						
						astroAreaCOPY.connect("body_entered", astroAreaCOPY, "bodyEnteredArea")
						astroAreaCOPY.connect("body_exited", astroAreaCOPY, "bodyExitedArea")
						
						timeDiscrepAstroShapesCOPIES[astroChar] = astroAreaCOPY
						astroAreaCOPY.refNode = prevRef
					
			
			
			
			areaNode.connect("body_entered", self, "bodyEnteredTimeDiscrepArea", [areaNode, astroChar, csWrap])
			areaNode.connect("area_entered", self, "areaEnteredTimeDiscrepArea", [areaNode, astroChar, csWrap])
			areaNode.connect("body_exited", self, "bodyExitedTimeDiscrepArea", [areaNode, astroChar, csWrap])
			areaNode.connect("area_exited", self, "areaExitedTimeDiscrepArea", [areaNode, astroChar, csWrap])
			
			timeDiscrepCSWCharDict[csWrap.nodePath][1][astroChar] = areaNode.get_path()
			
		
		
		
		areaNode.set_global_position(parentNodePos)
		areaNode.set_global_rotation(parentNodeRot)
		areaNode = get_node(timeDiscrepCSWCharDict[csWrap.nodePath][1][astroChar])
		areaNode.add_child(collShapeNodeDup)
		collShapeNodeDup.set_owner(areaNode)
		collShapeNodeDup.set_position(collShapeNodePos)
		collShapeNodeDup.set_global_scale(collShapeNodeScale* 0.98)
		collShapeNodeDup.set_rotation(collShapeNodeRot)
#



					
			
	return true





func removeCSWrapTimeDiscepArea2D(csWrap : CharacterSwitchingWrapper, astroChar, areaCSW, interactWithOthers : bool = true):
	
	var currChar = global.CharacterRes.id
	var cswNode = get_node(csWrap.nodePath)#find_node(csWrap.nodePath, true, false)
	
	if global.charYearDict[astroChar] <= global.charYearDict[currChar]: return false
	
	#if the item exiting does not exist in the astroChar timeline, ignore
	if !csWrap.checkIfInCharLvl(astroChar): return false
	
	#NOTE THE following return false checks are VERY senesitive to making the game
	#crash upon moving objects if the logic is not done properly
	
	#areaCSW is null when called outside the enter and exit functions, manually
	if areaCSW != null:
		#if the area exiting from does not exist in the astroChar timeline, ignore
		if !areaCSW.checkIfInCharLvl(astroChar): return false
		#if not in anything, then don't remove
	
	
#	if the item exiting is still present in other timeDicrep areas for said timeline, don't remove
	if timeDiscrepBodyPresentDict2.has(cswNode.get_name()) && timeDiscrepBodyPresentDict2[cswNode.get_name()].has(astroChar) && timeDiscrepBodyPresentDict2[cswNode.get_name()][astroChar].size() > 0:
		return false
	
	if !timeDiscrepCSWCharDict.has(csWrap.nodePath): return false
	#if cswNode == astroNode: return false
	
	
	
	if !timeDiscrepCSWCharDict[csWrap.nodePath][1].has(astroChar): return false
	
	if !interactWithOthers:
		timeDiscrepCSWCharDict[csWrap.nodePath][1].erase(astroChar)
		return true
	
	#var cswTimeDiscrepNode = get_node(timeDiscrepCSWCharDict[csWrap.nodePath][0])
	
	var charAreaNode = get_node(timeDiscrepCSWCharDict[csWrap.nodePath][1][astroChar])
	if charAreaNode == null: return false
	
	
	
	
	if cswNode == astroNode:
		if timeDiscrepAstroShapes.has(astroChar):
			timeDiscrepAstroShapes.erase(astroChar)
	
	if timeDiscrepAstroShapes.has(astroChar):
		var astroArea = timeDiscrepAstroShapes[astroChar]
		if astroArea.cswDependant == csWrap:
			astroArea.refNode = cswNode
			astroArea.refIsRolling = cswNode.is_in_group("object") && cswNode.roll
			astroArea.connect("body_entered", astroArea, "bodyEnteredArea")
			astroArea.connect("body_exited", astroArea, "bodyExitedArea")
				
	
	if timeDiscrepAstroShapesCOPIES.has(astroChar):
		if timeDiscrepAstroShapesCOPIES[astroChar].refNode == cswNode:
			var astroAreaCOPY = timeDiscrepAstroShapesCOPIES[astroChar]
			var astroArea = timeDiscrepAstroShapes[astroChar]
			timeDiscrepAstroShapesCOPIES.erase(astroChar)
			astroAreaCOPY.get_parent().remove_child(astroAreaCOPY)
			astroAreaCOPY.set_physics_process(false)
			astroAreaCOPY.queue_free()
			
			astroArea.refNode == cswNode
			astroArea.add_to_group("astroTimeDiscrep")
#
#			astroArea.connect("body_entered", self, "bodyEnteredTimeDiscrepArea", [astroArea, astroChar, astroArea.astroCSW])
#			astroArea.connect("area_entered", self, "areaEnteredTimeDiscrepArea", [astroArea, astroChar, astroArea.astroCSW])
#			astroArea.connect("body_exited", self, "bodyExitedTimeDiscrepArea", [astroArea, astroChar, astroArea.astroCSW])
#			astroArea.connect("area_exited", self, "areaExitedTimeDiscrepArea", [astroArea, astroChar, astroArea.astroCSW])
#
#
	
	
	#timeDiscrepRemovingArea = charAreaNode
	var childrenToDelete = charAreaNode.get_children()
	#MUST erase from dictionary before triggering removing object
	timeDiscrepCSWCharDict[csWrap.nodePath][1].erase(astroChar)
	
	for ind in childrenToDelete.size():
		charAreaNode.remove_child(childrenToDelete[ind])
		childrenToDelete[ind].queue_free()
	charAreaNode.get_parent().remove_child(charAreaNode)
	charAreaNode.queue_free()
	
	
	timeDiscrepRemovingArea = null
	
	
	return true



func bodyEnteredTimeDiscrepArea(body, areaNode, astroChar, areaCSW, astroTimeDiscrepBody = null):
	if !body.has_method("CSWrapSaveTimeDiscrepState"): return
	if body == astroNode: return
	
	var interactWithOthers = true
	var cswrap = null
	
	if body.is_in_group("cablePoint"):
		#var areaCSWNode = get_node(areaCSW.nodePath)
		if areaCSW != null:
			if areaCSW.groups.has("astro"): return
			if areaCSW.groups.has("object"): return
		
		interactWithOthers = false
		var cswww = body.get_parent().csWrap
		var extraWraps = cswww.extraCSWrappers
		cswrap = extraWraps[body.get_name()]
	else:
		for csw in charSwitchWrappers:
			if get_node(csw.nodePath) == body:
				cswrap = csw
				break
	
	cswEnteredTimeDiscrepArea(cswrap, body, areaNode, astroChar, areaCSW, interactWithOthers, astroTimeDiscrepBody)
	
	
	
func areaEnteredTimeDiscrepArea(area, areaNode, astroChar, areaCSW): 
	if area.is_in_group("astroTimeDiscrep"):
		if area.refNode != null:
			bodyEnteredTimeDiscrepArea(area.refNode, areaNode, astroChar, areaCSW)
		return
	if !area.is_in_group("plug"): return
	
	if areaCSW.groups.has("astro"): return
	if areaCSW.groups.has("object"): return
	
	var plug = area.get_parent()
	if plug.parentCable == null: return
	
	var csw = null
	for csWrap in charSwitchWrappers:
		if get_node(csWrap.nodePath) == plug.parentCable:
			csw = csWrap
	
	cswEnteredTimeDiscrepArea(csw, plug.parentCable, areaNode, astroChar, areaCSW, false, null)
	
	
func cswEnteredTimeDiscrepArea(cswrap, body, areaNode, astroChar, areaCSW, interactWithOthers = true, astroTimeDiscrepBody = null):
	var currChar = global.CharacterRes.id
	
	if cswrap == null: return
	if areaCSW != null:
		if cswrap == areaCSW || cswrap.nodePath == areaCSW.nodePath:
			return
	
	for otherChar in cswrap.changesToApply.keys():
		
		#astroTimeDiscrepBody is for when this method is executed from the astro_timDiscrepArea
		#script and is only applying to the astroTimeDiscrep node and its astroChar
		#I could just make specific shit happen in said script, but this was
		#all of this logic stays in the same place and I don't have to change
		#in different locations
		if astroTimeDiscrepBody != null:
			if otherChar != astroChar: continue
		
		if astroChar == currChar: continue
		
		#if the item exiting does not exist in the astroChar timeline, ignore
		if cswrap.checkIfInCharLvl(otherChar):
		
			#if the area exiting from does not exist in the astroChar timeline, ignore
			if areaCSW == null || areaCSW.checkIfInCharLvl(otherChar) :
			
				if !timeDiscrepBodyPresentDict2.has(body.get_name()):
					timeDiscrepBodyPresentDict2[body.get_name()] = {}
					
				if !timeDiscrepBodyPresentDict2[body.get_name()].has(otherChar):
					timeDiscrepBodyPresentDict2[body.get_name()][otherChar] = []
					
				if areaNode != null: timeDiscrepBodyPresentDict2[body.get_name()][otherChar].append(areaNode)
				elif astroTimeDiscrepBody != null: timeDiscrepBodyPresentDict2[body.get_name()][otherChar].append(astroTimeDiscrepBody)
		
		if addCSWrapCollShape2DiscrepArea(cswrap, astroChar, areaCSW, interactWithOthers):
			body.CSWrapSaveTimeDiscrepState(cswrap, astroChar, true)
	
	
	
	
func bodyExitedTimeDiscrepArea(body, areaNode, astroChar, areaCSW, astroTimeDiscrepBody = null):
	if areaNode != null: 
		if timeDiscrepRemovingArea == areaNode: return
		if timeDiscrepManuallyRemovingArea.has([body, areaNode]): return
	if !body.has_method("CSWrapSaveTimeDiscrepState"): return
	if body == astroNode: return

	var cswrap = null
	var interactWithOthers = true
	
	if body.is_in_group("cablePoint"):
		if areaCSW != null:
			if areaCSW.groups.has("astro"): return
			if areaCSW.groups.has("object"): return
			
		interactWithOthers = false
		cswrap = body.get_parent().csWrap.extraCSWrappers[body.get_name()]
	else:
		for csw in charSwitchWrappers:
			if get_node(csw.nodePath) == body:
				cswrap = csw
				break
			
	cswExitedTimeDiscrepArea(cswrap, body, areaNode, astroChar, areaCSW, interactWithOthers, astroTimeDiscrepBody)
	
	
func areaExitedTimeDiscrepArea(area, areaNode, astroChar, areaCSW):
	if !area.is_in_group("plug"): return
	
	if areaCSW.groups.has("astro"): return
	if areaCSW.groups.has("object"): return
	
	var plug = area.get_parent()
	if plug.parentCable == null: return
	
	var csw = null
	for csWrap in charSwitchWrappers:
		if get_node(csWrap.nodePath) == plug.parentCable:
			csw = csWrap
	
	cswExitedTimeDiscrepArea(csw, plug.parentCable, areaNode, astroChar, areaCSW, false, null)


func cswExitedTimeDiscrepArea(cswrap, body, areaNode, astroChar, areaCSW, interactWithOthers = true, astroTimeDiscrepBody = null):
	var currChar = global.CharacterRes.id
	
	if cswrap == null: return
	
	if areaCSW != null:
		if cswrap == areaCSW || cswrap.nodePath == areaCSW.nodePath: return
	
	for astroChar in cswrap.changesToApply.keys():
		
		if astroChar == currChar: continue
		
				#if the item exiting does not exist in the astroChar timeline, ignore
		if cswrap.checkIfInCharLvl(astroChar):
		
			#if the area exiting from does not exist in the astroChar timeline, ignore
			if (areaCSW == null || areaCSW.checkIfInCharLvl(astroChar)) != null:
				if timeDiscrepBodyPresentDict2.has(body.get_name()):
					if timeDiscrepBodyPresentDict2[body.get_name()].has(astroChar):
						if areaNode != null && timeDiscrepBodyPresentDict2[body.get_name()][astroChar].has(areaNode):
							timeDiscrepBodyPresentDict2[body.get_name()][astroChar].erase(areaNode)
							
						elif astroTimeDiscrepBody != null && timeDiscrepBodyPresentDict2[body.get_name()][astroChar].has(astroTimeDiscrepBody):
							timeDiscrepBodyPresentDict2[body.get_name()][astroChar].erase(astroTimeDiscrepBody)
						
						
					
		
		if removeCSWrapTimeDiscepArea2D(cswrap, astroChar, areaCSW, interactWithOthers):
			body.CSWrapSaveTimeDiscrepState(cswrap, astroChar, false)




func restoreCSWrapperState():
	if global.CharacterRes == null: return
	var currChar = global.CharacterRes.id
	
	for csWrap in charSwitchWrappers:
		if csWrap.staticNode:continue
		print(csWrap.nodePath)
		if csWrap.checkIfInCharLvl(currChar):
			var nd = get_node(csWrap.nodePath)
			if nd.has_method("CSWrapRestoreState"):
				nd.CSWrapRestoreState(csWrap)
						

func applyCSWrapperChanges():
	if global.CharacterRes == null: return
	var currChar = global.CharacterRes.id

	
	for csWrap in charSwitchWrappers:
		if csWrap.staticNode: continue
		#print(csWrap.nodePath)
		if csWrap.checkIfInCharLvl(currChar):
			if csWrap.changesToApply[currChar] is Array && csWrap.changesToApply[currChar] == []: continue
			var nd = get_node(csWrap.nodePath)
			nd.CSWrapApplyChanges(csWrap)
			nd.CSWrapApplyDependantChanges(csWrap)



func saveCSWrapperStartStates():
	
	
	#need to add to both registered and charSwitchWrappers
	for csWrap in charSwitchWrappers:
		if csWrap.staticNode: continue
		if csWrap.checkIfInCharLvl(global.CharacterRes.id):
			get_node(csWrap.nodePath).CSWrapSaveStartState(csWrap)




func removeDisabledCSWrapperNodes():
	for csWrap in charSwitchWrappers:
		if !csWrap.checkIfInCharLvl(global.CharacterRes.id):
			var nodeObj = get_node(csWrap.nodePath)
			remove_child(nodeObj)
		
		
	
func initLevel():
	#prevent from running in editor
	if Engine.editor_hint:
		return
		
	if (startingInventory != null):
		for iq in startingInventory:
			AddInventoryItem(iq)

#initAstro is not called here but in the extended gd scripts
func initAstro(customSpawnPoint = null):
	
	#prevent from running in editor
	if Engine.editor_hint:
		return
	
	var camNode = astroNode.CAMERA_NODE
	
	
	astroNode.set_global_position(ASTRO_GLOBAL_START_POS)
	
	if (ASTRO_FACE_RIGHT):
		astroNode.directional_force = astroNode.DIRECTION.RIGHT
	else:
		astroNode.directional_force = astroNode.DIRECTION.LEFT
	
	astroNode.Move()

	astroNode.set_health(ASTRO_HEALTH)

	camNode.set_global_position(CAM_GLOBAL_START_POS)
	
	
func gameWon():
	gameOver(true)
	
func gameLost():
	gameOver(false)
	
func gameOver(won):
	astroNode.fadeOutSound()
	astroNode.CAMERA_NODE.FadeIntoBlack(won)
	
	
func loadNextLevel():
	#all level scenes need to be named via format lvl##
	#this assumes all levels are consecutive
	var nextLevelInt = int(global.lvl().name.substr(2,4)) + 1
	global.loadLevel(nextLevelInt)
	
func reloadLevelLastSave():
	#place astro at save point spawn pint
	#initAstro(customSpawnPoint)....
	_ready()

func AddInventoryItems(iqs):
	for iq in iqs:
		AddInventoryItem(iq);

func AddInventoryItem(iq):
	if (!Inventory.keys().has(iq.item)):
		Inventory[iq.item] = 0
		print("Added ", iq.item, " to dictionary")
	Inventory[iq.item] += iq.quantity;
	print("Set quantity of ",iq.item," to ",Inventory[iq.item], " by adding ",iq.quantity)

func CheckHasInventoryItems(iqs, eatit):
	var canEat = true
	for iq in iqs:
		if !CheckHasInventoryItem(iq, false):
			canEat = false
	if !canEat:
		return false
	for iq in iqs:
		CheckHasInventoryItem(iq, eatit)
	return true	

func CheckHasInventoryItem(iq, eatit):
	if (!Inventory.keys().has(iq.item)):
		print("Do not have any ", iq.item)
		return false
	if (Inventory[iq.item] < iq.quantity):
		print("Do not have enough ", iq.item, "have ", Inventory[iq.item], " need ", iq.quantity)
		return false
	if (eatit):
		print ("Eating ",iq.quantity, " of ", iq.item)
		Inventory[iq.item] -= iq.quantity
	return true
