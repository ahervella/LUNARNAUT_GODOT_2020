tool
extends Node

#ALEJANDRO (Feb-23-2020)
#This is the node from which to extend level nodes, which basically makes sure each level has the basic
#requirments needed to start the level properly. 
export (bool) var playTest = false
export (bool) var allCharToThisScene = true
export (NodePath) var astroNodePath = null
export (Array, Resource) var startingInventory
var astroNode
export (NodePath) var trigChunkNodePath = null
export (bool) var CSWrapsAddAstroAndCam = false setget setAddAstroAndCam
export (bool) var CSWrapsAddAll1stGenChildNodes = false setget setAddAllChildNodes
export (bool) var CSWrapsAddNewWrapper = false setget setAddNewWrapper
export (bool) var CSWrapConfirmClear = false
export (bool) var CSWrapsClearCSWs = false setget setClearAllNodes
export (Dictionary) var charSwitchWrappers
export (bool) var CSWrapConfirmSave = false
export (bool) var CSWrapsSaveStates = false setget setSaveCSWStates
export (bool) var CSWrapConfirmLoad = false
export (bool) var CSWrapLoadSavedStates = false setget setLoadCSWStates
#export (bool) var CSWrapClearSavedStates = false setget setClearCSWStates


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

var timeDiscrepCSWCharDict = {}

var timeDiscrepAstroShapes = {}
const timeDiscrepAstroScript = preload("res://SCRIPTS/astro_timeDiscrepArea.gd")

#keeps track of the in which areas the object body is present in
var timeDiscrepBodyPresentDict2 = {}
var timeDiscrepManuallyRemovingArea = []
var timeDiscrepRemovingArea

func getLvlSceneName():
	var path = get_tree().get_edited_scene_root().filename if Engine.editor_hint else global.lvl().filename
	
	#return global.getSceneName(path)
	#have to just copy directly because auto loaded singletons don't run in tool mode :/
	path = path.substr(path.find_last("/")+1)
	return path.substr(0, path.find_last("."))
	
	
func consistentCharSet():
	for astroChar in global.charResDict.keys():
		var charRes = global.charResDict[astroChar]
		
		charRes.level = getLvlSceneName()
		
		
#//////////// START OF TOOL AND SETGET CODE ////////////////

func setAddAstroAndCam(garboVal):
	if !Engine.editor_hint:
		return
	if !readyDone: return
	addAstroAndCamPerChar()
	property_list_changed_notify()
	
func setAddAllChildNodes(garboVal):
	if !Engine.editor_hint:
		return
	CSWrapsAddAll1stGenChildNodes = false
	
	addAstroAndCamPerChar()
	
	for child in get_children():
		
		if child.get_name() == "InteractFont" : continue
		var alreadyPresent = false
		
		for resNode in charSwitchWrappers.values():
			if resNode.nodePath == resNode.getActualNodePath(child.get_path(), self):
				alreadyPresent = true
				break
				
		if !alreadyPresent:
			var childRes = CharacterSwitchingWrapper.new()
			
			childRes.connect("requestLvlNodeSig", self, "sendLvlNode2CSW")
			
			childRes.setNodePath(child.get_path())
			
			
			if !child.has_method("CSWrapSaveStartState"):
				childRes.staticNode = true
			charSwitchWrappers[childRes.getCSWName(self)] = childRes
			
	print("^^Ignore 'Node not found' errors (because the path only exists at runtime)^^")
	property_list_changed_notify()

func sendLvlNode2CSW(csw):
	csw.currLvlNode = self#emit_signal("sendLvlNode", self)


func addAstroAndCamPerChar():
	if !Engine.editor_hint:
		return

	var astroPresent = false
	var camPresent = false
	
	var astro = null
	var camNode = null
			
	for child in get_children():
		if child is Camera2D:
			camNode = child 
			
		if child is KinematicBody2D:
			if child.is_in_group("astro"):
				astro = child
	
	if astro == null || camNode == null: return
	
	for csWrap in charSwitchWrappers.values():
		if get_node(csWrap.nodePath) == astro || csWrap.nodePath == csWrap.getActualNodePath(astro.get_path(), self):
			astroPresent = true
		
		if get_node(csWrap.nodePath) == camNode || csWrap.nodePath == csWrap.getActualNodePath(camNode.get_path(), self):
			camPresent = true
			
	
	if !astroPresent:
		var astroCharRes = CharacterSwitchingWrapper.new()
		astroCharRes.connect("requestLvlNodeSig", self, "sendLvlNode2CSW")
		#connect("sendLvlNode", astroCharRes, "getLvlNode")
		#astroCharRes.nodePath = astro.get_path()
		astroCharRes.setNodePath(astro.get_path())#
		#CharacterSwitchingWrapper.addGroupsToCSW(astro, astroCharRes)
		
		for child in astro.get_children():
			if child is CollisionShape2D:
				
				astroCharRes.nodeCollShapePaths.resize(astroCharRes.nodeCollShapePaths.size() + 1)
				var index = astroCharRes.nodeCollShapePaths.size() -1
				astroCharRes.nodeCollShapePaths[index] = astroCharRes.getActualNodePath(child.get_path(), self)
				break
				
		charSwitchWrappers[astroCharRes.getCSWName(self)] = astroCharRes#.append(astroCharRes)
	
	if !camPresent:
		var camCharRes = CharacterSwitchingWrapper.new()
		camCharRes.connect("requestLvlNodeSig", self, "sendLvlNode2CSW")
		#connect("sendLvlNode", camCharRes, "getLvlNode")
		#camCharRes.nodePath = camNode.get_path()
		camCharRes.setNodePath(camNode.get_path())
		#CharacterSwitchingWrapper.addGroupsToCSW(camNode, camCharRes)
		charSwitchWrappers[camCharRes.getCSWName(self)] = camCharRes#.append(camCharRes)
	print("^^Ignore 'Node not found' errors (because the path only exists at runtime)^^")

func setAddNewWrapper(garboVal):
	CSWrapsAddNewWrapper = false
	if !Engine.editor_hint: return
	var newName = "newWrapper"
	while charSwitchWrappers.has(newName):
		newName = newName + "r"
		if newName.length() > 100: return
	
	charSwitchWrappers[newName] = CharacterSwitchingWrapper.new()
	charSwitchWrappers[newName].connect("requestLvlNodeSig", self, "sendLvlNode2CSW")
	property_list_changed_notify()
	#connect("sendLvlNode", charSwitchWrappers[newName], "getLvlNode")
	
func setClearAllNodes(garboVal):
	if !CSWrapConfirmClear: return
	if !garboVal: return
	#CSWrapsClearCSWs = false
	if !Engine.editor_hint: return
	for node in charSwitchWrappers.values():
		if node == null:
			continue
		
		node.nodeCollShapePaths.resize(0)
	charSwitchWrappers.clear()
	CSWrapConfirmClear = false
	property_list_changed_notify()
	#setClearCSWStates(null)

func setSaveCSWStates(garboVal):
	if !CSWrapConfirmSave: return
	
	#in case it reloads the scene, don't automatically save everything
	if !garboVal: return
	
	#only for editor use
	if !Engine.editor_hint: return
	
	for cswKey in charSwitchWrappers.keys():
		var csw = charSwitchWrappers[cswKey]
		if csw is CharacterSwitchingWrapper:
			csw.saveThisResource(getLvlSceneName(), cswKey)#saveAllVariables()

	CSWrapConfirmSave = false
	property_list_changed_notify()

func setLoadCSWStates(garboVal):
	if !CSWrapConfirmLoad: return

	#in case it reloads the scene, don't automatically save everything
	if !garboVal: return
	
		#only for editor use
	if !Engine.editor_hint: return
	
	var file = File.new()
	
	var dir = Directory.new()
	var dirPath = CharacterSwitchingWrapper.getSaveFileDirPath(getLvlSceneName())
	if dir.dir_exists(dirPath):
		if dir.open(dirPath) == OK:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir(): 
					file_name = dir.get_next()
					continue
					#print("Found directory: " + file_name)
				var filePath = dirPath + file_name
				var cswKey = file_name.substr(0, file_name.find_last("."))
				charSwitchWrappers[cswKey] = load(filePath).duplicate(true)
				file_name = dir.get_next()
		else:
			print("An error occurred when trying to access the character resource path.")
	
#	for cswKey in charSwitchWrappers.keys():
#		var filePath = CharacterSwitchingWrapper.getSaveFilePath(getLvlSceneName(), cswKey)
#		if filePath != null && file.file_exists(filePath):
#			charSwitchWrappers[cswKey] = load(filePath).duplicate(true)
#		elif filePath != null:
#			print("file path " + filePath + " could not be found.")
		
	CSWrapConfirmLoad = false
	property_list_changed_notify()
	print("CSWrappers loading finished.")

func changeCSWKey(csw, newName):
	if !Engine.editor_hint:
		return
		
	var keyToErase = null
	
	for key in charSwitchWrappers.keys():
		if charSwitchWrappers[key] is CharacterSwitchingWrapper:
			if charSwitchWrappers[key] == csw:
				keyToErase = key
				break
	
	if keyToErase != null:
		charSwitchWrappers.erase(keyToErase)
		
	charSwitchWrappers[newName] = csw
		
		
#//////////// END OF TOOL AND SETGET CODE ////////////////

#//////////// START OF LEVEL INITIALIZATION CODE ////////////////



func _physics_process(delta):
	if Engine.editor_hint:
		readyDone = true
		return

	if readyDone && !processDone && oneShotFrameWait:
	
		loadCSWrappersFromGlobal()
		addCSWrapperTimeDiscrepencyAreas()

		removeDisabledCSWrapperNodes()
		applyCSWrapperChanges()
		saveCSWrapperStartStates()
		processDone = true

		astroNode.set_physics_process(true)
		for child in get_children():
			if child.is_in_group("object"):
				child.set_physics_process(true)
		
		set_physics_process(false)

	elif readyDone && !oneShotFrameWait:
		oneShotFrameWait = true
		


func _ready():
	#prevent from running in editor
	if Engine.editor_hint:
		readyDone = true
		return
	

	
	global.playTest = playTest
	astroNode = get_node(astroNodePath)
	if (trigChunkNodePath != null):
		trigChunkNode = get_node(trigChunkNodePath)
	global.interactNode = astroNode.INTERACT_TEXT_NODE
	
	
	if allCharToThisScene: consistentCharSet()
	
	
	readyDone = true

func loadCSWrappersFromGlobal():
	if global.currCharRes == null: return
	var currLvlPath = global.getScenePath(global.currCharRes.level)
	var currChar = global.currCharRes.id
	
	if global.levelWrapperDict.has(currLvlPath):
		if global.levelWrapperDict[currLvlPath].gravity.has(currChar):
			var gravMag = global.levelWrapperDict[currLvlPath].gravity[currChar][0]
			var gravDeg = global.levelWrapperDict[currLvlPath].gravity[currChar][1]
			global.changeGrav(gravMag, gravDeg, 0)
		
		if global.levelWrapperDict[currLvlPath].lvlNodesCSWrapDict.has(currChar):
			charSwitchWrappers = global.levelWrapperDict[currLvlPath].lvlNodesCSWrapDict[currChar]




func addCSWrapperTimeDiscrepencyAreas():
	if global.currCharRes == null: return
	
	var currChar = global.currCharRes.id
	var currLvlPath = global.getScenePath(global.currCharRes.level)
	
			
	timeDiscrepParentNode = Node.new()
	timeDiscrepParentNode.set_name("TIME_DISCREP")
	
	add_child(timeDiscrepParentNode)
	timeDiscrepParentNode.set_owner(self)


	for csw in charSwitchWrappers.values():
		checkNodePathsAreCorrect(csw)
		
		var csNode = get_node(csw.nodePath)
		var timeDiscrepCSWNode = Node.new()
		timeDiscrepCSWNode.set_name("TIME_DISCREP_" + csNode.get_name())
		timeDiscrepParentNode.add_child(timeDiscrepCSWNode)
		timeDiscrepCSWNode.set_owner(timeDiscrepParentNode)
		timeDiscrepCSWCharDict[csw.nodePath] = [timeDiscrepCSWNode.get_path(), {}]
		
		for astroChar in csw.changesToApply.keys():
			if global.charYearDict[astroChar] <= global.charYearDict[currChar]: continue
			
			#shitty way pf checking its a cable
			if csNode.has_method("addCableChild"):
				addCSWrapCollShape2DiscrepArea(csw, astroChar, null, false)
				#yield(get_tree(),"physics_frame")
				if  csw.changesToApply[astroChar] != null && csw.changesToApply[astroChar] != []:
					csNode.CSWrapSaveTimeDiscrepState(csw, astroChar, true, null, csw.changesToApply[astroChar])
			else:
				addCSWrapCollShape2DiscrepArea(csw, astroChar, null)
	

func checkNodePathsAreCorrect(csw):# : CharacterSwitchingWrapper):
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
	
	
func applyCSWrapperChanges():
	if global.currCharRes == null: return
	var currChar = global.currCharRes.id

	
	for csWrap in charSwitchWrappers.values():
		if csWrap.staticNode: continue
		if csWrap.checkIfInCharLvl(currChar):
			if csWrap.changesToApply[currChar] is Array && csWrap.changesToApply[currChar] == []: continue
			var nd = get_node(csWrap.nodePath)
			nd.CSWrapApplyChanges(csWrap)
			nd.CSWrapApplyDependantChanges(csWrap)



func saveCSWrapperStartStates():
	
	
	#need to add to both registered and charSwitchWrappers
	for csWrap in charSwitchWrappers.values():
		if csWrap.staticNode: continue
		if csWrap.checkIfInCharLvl(global.currCharRes.id):
			get_node(csWrap.nodePath).CSWrapSaveStartState(csWrap)




func removeDisabledCSWrapperNodes():
	for csWrap in charSwitchWrappers.values():
		if !csWrap.checkIfInCharLvl(global.currCharRes.id):
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
	
	

	
#//////////// END OF LEVEL INITIALIZATION CODE ////////////////

#//////////// START OF LEVEL TIME DISCREPENCY AREA2D MANAGEMENT CODE ////////////////
	
	

func addCSWrapCollShape2DiscrepArea(csWrap, astroChar, areaCSW, interactWithOthers : bool = true):
	var currChar = global.currCharRes.id
	var cswNode = get_node(csWrap.nodePath)#find_node(csWrap.nodePath, true, false)
	
	
	if global.charYearDict[astroChar] <= global.charYearDict[currChar]: return false
	if csWrap.staticNode && csWrap.checkIfInCharLvl(currChar): return false
	
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
		
		var collShapeNodePos = collShapeNode.get_position()
		var collShapeNodeRot = collShapeNode.get_rotation()
		var collShapeNodeScale = collShapeNode.get_global_scale()
		
		var parentNodePos
		var parentNodeRot
		
		if areaCSW == null && csWrap.changesToApply[astroChar].size() > 0 && csWrap.changesToApply[astroChar][0] != null:
			parentNodePos = csWrap.changesToApply[astroChar][0]
			parentNodeRot = csWrap.changesToApply[astroChar][1]
		else:
			parentNodePos = cswNode.get_global_position()
			parentNodeRot = cswNode.get_global_rotation()
			
		var collShapeNodeDup = collShapeNode.duplicate() #duplicate(DUPLICATE_USE_INSTANCING)
		collShapeNodeDup.set_name("TIME_DISCREP_SHAPE_%s_%s_%s" % [csWrap.nodePath, global.astroChar2String(astroChar), collShapeNode.get_name()])
		
		if !timeDiscrepCSWCharDict[csWrap.nodePath][1].has(astroChar):
			areaNode = Area2D.new()
			areaNode.set_name("TIME_DISCREP_AREA_%s_%s" % [csWrap.nodePath, global.astroChar2String(astroChar)])
			cswTimeDiscrepNode.add_child(areaNode)
			areaNode.set_owner(cswTimeDiscrepNode)
			
			areaNode.connect("body_entered", self, "bodyEnteredTimeDiscrepArea", [areaNode, astroChar, csWrap])
			areaNode.connect("area_entered", self, "areaEnteredTimeDiscrepArea", [areaNode, astroChar, csWrap])
			areaNode.connect("body_exited", self, "bodyExitedTimeDiscrepArea", [areaNode, astroChar, csWrap])
			areaNode.connect("area_exited", self, "areaExitedTimeDiscrepArea", [areaNode, astroChar, csWrap])
			
			timeDiscrepCSWCharDict[csWrap.nodePath][1][astroChar] = areaNode.get_path()
			
			
			if timeDiscrepAstroShapes.has(astroChar):
				var astroTimeDiscrepArea = timeDiscrepAstroShapes[astroChar]
				if astroTimeDiscrepArea.cswDependant == csWrap:
					astroTimeDiscrepArea.refNode = areaNode
					astroTimeDiscrepArea.refIsRolling = cswNode.is_in_group("object") && cswNode.roll
						
			#if this node we're adding an area from is an astroNode
			#&& it has something it was standing on (a dependant cs wrapper)
			#&& and there isn't already one that exitsts for this astroChar
			# (so that this method can be called from the astro_timeDiscrepArea script correctly)
			#&& 
			if (cswNode == astroNode 
			&& csWrap.dependantCSWrappers[astroChar].size() > 0
			&& !timeDiscrepAstroShapes.has(astroChar) ):

				timeDiscrepAstroShapes[astroChar] = areaNode
				areaNode.set_script(load(global.getScriptPath("astro_timeDiscrepArea.gd")))#set_script(timeDiscrepAstroScript)#
				areaNode.astroChar = astroChar
				areaNode.astroCSW = csWrap
				areaNode.cswDependant = csWrap.dependantCSWrappers[astroChar][csWrap.dependantCSWrappers[astroChar].size()-1]
				areaNode.add_to_group("astro_timeDiscrepArea")
				
				
				for cswDepCheck in charSwitchWrappers.values():
					if areaNode.cswDependant == cswDepCheck:
						
						
						timeDiscrepAstroShapes[astroChar].refIsRolling = cswNode.is_in_group("object") && cswNode.roll
						areaNode.diffPos = areaNode.astroCSW.changesToApply[astroChar][0] - cswDepCheck.changesToApply[astroChar][0]
						
						if timeDiscrepCSWCharDict.has(cswDepCheck.nodePath) && timeDiscrepCSWCharDict[cswDepCheck.nodePath][1].has(astroChar):
							areaNode.refNode = get_node(timeDiscrepCSWCharDict[cswDepCheck.nodePath][1][astroChar])
						else:
							areaNode.refNode = get_node(cswDepCheck.nodePath)#areaNode
							
		areaNode.set_global_position(parentNodePos)
		areaNode.set_global_rotation(parentNodeRot)
		areaNode = get_node(timeDiscrepCSWCharDict[csWrap.nodePath][1][astroChar])
		areaNode.add_child(collShapeNodeDup)
		collShapeNodeDup.set_owner(areaNode)
		collShapeNodeDup.set_position(collShapeNodePos)
		# * 0.98 so that they are not touching 
		#tangentally and give a little wiggle room
		collShapeNodeDup.set_global_scale(collShapeNodeScale* 0.98)
		collShapeNodeDup.set_rotation(collShapeNodeRot)

	return true




func removeCSWrapTimeDiscepArea2D(csWrap, astroChar, areaCSW, interactWithOthers : bool = true):
	
	var currChar = global.currCharRes.id
	var cswNode = get_node(csWrap.nodePath)
	
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
	
	if !timeDiscrepCSWCharDict[csWrap.nodePath][1].has(astroChar): return false
	
	if !interactWithOthers:
		timeDiscrepCSWCharDict[csWrap.nodePath][1].erase(astroChar)
		return true
	
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



func bodyEnteredTimeDiscrepArea(body, areaNode, astroChar, areaCSW):
	if !body.has_method("CSWrapSaveTimeDiscrepState"): return
	if body == astroNode: return
	
	var interactWithOthers = true
	var cswrap = null
	
	if body.is_in_group("cablePoint"):
		if areaCSW.groups.has("astro"): return
		if areaCSW.groups.has("object"): return
		
		interactWithOthers = false
		
		
		var cableCSW = body.get_parent().csWrap
		if cableCSW == null: return
		var extraWraps = cableCSW.extraCSWrappers
		cswrap = extraWraps[body.get_name()]
		
	else:
		for csw in charSwitchWrappers.values():
			if get_node(csw.nodePath) == body:
				cswrap = csw
				break
	
	cswEnteredTimeDiscrepArea(cswrap, body, areaNode, astroChar, areaCSW, interactWithOthers)
	
	
	
func areaEnteredTimeDiscrepArea(area, areaNode, astroChar, areaCSW): 
	if area.is_in_group("astro_timeDiscrepArea"):
		area.areaEntered(areaNode, astroChar, areaCSW)
		return
		
	if !area.is_in_group("plug"): return
	
	if areaCSW.groups.has("astro"): return
	if areaCSW.groups.has("object"): return
	
	var plug = area.get_parent()
	if plug.parentCable == null: return
	
	var csw = null
	for csWrap in charSwitchWrappers.values():
		if get_node(csWrap.nodePath) == area:
			csw = csWrap
	
	cswEnteredTimeDiscrepArea(csw, plug.parentCable, areaNode, astroChar, areaCSW, false)
	
	
func cswEnteredTimeDiscrepArea(cswrap, body, areaNode, astroChar, areaCSW, interactWithOthers = true):
	var currChar = global.currCharRes.id
	
	if cswrap == null: return
	if areaCSW != null:
		if cswrap == areaCSW || cswrap.nodePath == areaCSW.nodePath:
			return
	
	#if astro timediscrep node was the one it ran into, ignore
	if get_node(areaCSW.nodePath) == astroNode:
		if timeDiscrepAstroShapes.has(astroChar) && timeDiscrepAstroShapes[astroChar].cswDependant == cswrap:
			return
	
		
		#if the item exiting does not exist in the astroChar timeline, ignore
	if cswrap.checkIfInCharLvl(astroChar):
	
		#if the area exiting from does not exist in the astroChar timeline, ignore
		if areaCSW.checkIfInCharLvl(astroChar) :
		
			if !timeDiscrepBodyPresentDict2.has(body.get_name()):
				timeDiscrepBodyPresentDict2[body.get_name()] = {}
				
			if !timeDiscrepBodyPresentDict2[body.get_name()].has(astroChar):
				timeDiscrepBodyPresentDict2[body.get_name()][astroChar] = []
				
			if areaNode != null: timeDiscrepBodyPresentDict2[body.get_name()][astroChar].append(areaNode)
				
			if addCSWrapCollShape2DiscrepArea(cswrap, astroChar, areaCSW, interactWithOthers):
				body.CSWrapSaveTimeDiscrepState(cswrap, astroChar, true)
	
	
	
	
func bodyExitedTimeDiscrepArea(body, areaNode, astroChar, areaCSW):

	if timeDiscrepRemovingArea == areaNode: return
	if timeDiscrepManuallyRemovingArea.has([body, areaNode]): return
	if !body.has_method("CSWrapSaveTimeDiscrepState"): return
	if body == astroNode: return

	var cswrap = null
	var interactWithOthers = true
	
	if body.is_in_group("cablePoint"):
		if areaCSW.groups.has("astro"): return
		if areaCSW.groups.has("object"): return
			
		interactWithOthers = false
		if body.get_parent().csWrap == null: return
		cswrap = body.get_parent().csWrap.extraCSWrappers[body.get_name()]
	else:
		for csw in charSwitchWrappers.values():
			if get_node(csw.nodePath) == body:
				cswrap = csw
				break
			
	cswExitedTimeDiscrepArea(cswrap, body, areaNode, astroChar, areaCSW, interactWithOthers)
	
	
func areaExitedTimeDiscrepArea(area, areaNode, astroChar, areaCSW):
	if area.is_in_group("astro_timeDiscrepArea"):
		area.areaExited(areaNode, astroChar, areaCSW)
		return
	if !area.is_in_group("plug"): return
	
	if areaCSW.groups.has("astro"): return
	if areaCSW.groups.has("object"): return
	
	var plug = area.get_parent()
	if plug.parentCable == null: return
	
	var csw = null
	
	for csWrap in charSwitchWrappers.values():
		if get_node(csWrap.nodePath) == plug.parentCable:
			csw = csWrap
	
	cswExitedTimeDiscrepArea(csw, plug.parentCable, areaNode, astroChar, areaCSW, false)


func cswExitedTimeDiscrepArea(cswrap, body, areaNode, astroChar, areaCSW, interactWithOthers = true):
	var currChar = global.currCharRes.id
	
	if cswrap == null: return
	
	if areaCSW != null:
		if cswrap == areaCSW || cswrap.nodePath == areaCSW.nodePath: return
	
	#if astro timediscrep node was the one it ran into, ignore
	if get_node(areaCSW.nodePath) == astroNode:
		if timeDiscrepAstroShapes.has(astroChar) && timeDiscrepAstroShapes[astroChar].cswDependant == cswrap:
			return
	
		
				#if the item exiting does not exist in the astroChar timeline, ignore
	if cswrap.checkIfInCharLvl(astroChar):
		
			#if the area exiting from does not exist in the astroChar timeline, ignore
		if (areaCSW == null || areaCSW.checkIfInCharLvl(astroChar)) != null:
			if timeDiscrepBodyPresentDict2.has(body.get_name()):
				if timeDiscrepBodyPresentDict2[body.get_name()].has(astroChar):
					if areaNode != null && timeDiscrepBodyPresentDict2[body.get_name()][astroChar].has(areaNode):
						timeDiscrepBodyPresentDict2[body.get_name()][astroChar].erase(areaNode)
							
						
					
		
			if removeCSWrapTimeDiscepArea2D(cswrap, astroChar, areaCSW, interactWithOthers):
				body.CSWrapSaveTimeDiscrepState(cswrap, astroChar, false)



#//////////// END OF LEVEL TIME DISCREPENCY AREA2D MANAGEMENT CODE ////////////////

#//////////// START OF LEVEL STATE MANAGEMENT CODE ////////////////



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
	#TODO: place astro at save point spawn point
	#initAstro(customSpawnPoint)....
	#_ready()
	global.goto_scene(global.getScenePath(getLvlSceneName()))




#//////////// END OF LEVEL STATE MANAGEMENT CODE ////////////////

#//////////// START OF INVENTORY MANAGEMENT CODE ////////////////




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
