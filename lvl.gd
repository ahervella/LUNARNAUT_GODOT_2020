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

#keeps track of the in which areas the object body is present in
#var timeDiscrepBodyPresentDict = {}
var timeDiscrepBodyPresentDict2 = {}
var timeDiscrepManuallyRemovingArea = []

func setAddAstroAndCam(garboVal):
	if !Engine.editor_hint:
		return
	if !readyDone: return
	addAstroAndCamPerChar()
	
func setAddAllChildNodes(garboVal):
	if !Engine.editor_hint:
		return
	if !readyDone: return
	addAstroAndCamPerChar()
	
	for child in get_children():
		if child.get_name() == "InteractFont" : return
		var alreadyPresent = false
		
		for resNode in charSwitchWrappers:
			if get_node(resNode.node) == child:
				alreadyPresent = true
				break
		
		if !alreadyPresent:
			var childRes = CharacterSwitchingWrapper.new()
			#name can actually act as a readable node path
			var nodePath =  child.get_name()
			childRes.node = NodePath(nodePath)

			for childChild in child.get_children():
				if childChild is CollisionShape2D:
					var collPathString = nodePath + "/" + childChild.get_name()
					
					childRes.nodeCollShapes.resize(childRes.nodeCollShapes.size()+1)
					var index = childRes.nodeCollShapes.size() -1
					childRes.nodeCollShapes[index] = NodePath(collPathString)
					
				if childChild is StaticBody2D:
					for childChildChild in childChild.get_children():
						if childChildChild is CollisionShape2D:
							var childCollpath = nodePath + "/" + childChild.get_name() + "/" + childChildChild.get_name()
							childRes.nodeCollShapes.resize(childRes.nodeCollShapes.size() + 1)
							var index = childRes.nodeCollShapes.size()-1
							
							childRes.nodeCollShapes[index] = NodePath(childCollpath)

			if !child.has_method("CSWrapSaveStartState"):
				childRes.staticNode = true
			charSwitchWrappers.append(childRes)

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
		if get_node(csWrap.node) == astro || csWrap.node == "astro":
			astroPresent = true
		
		if get_node(csWrap.node) == camNode || csWrap.node == "Cam2D":
			camPresent = true
			
	
	if !astroPresent:
		var astroCharRes = CharacterSwitchingWrapper.new()
		astroCharRes.node = astroNodePath
		for child in astro.get_children():
			if child is CollisionShape2D:
				#var path = astroNodePath + child.get_name()
				var nodePath = (child.get_name())
				astroCharRes.nodeCollShapes.resize(astroCharRes.nodeCollShapes.size() + 1)
				var index = astroCharRes.nodeCollShapes.size() -1
				astroCharRes.nodeCollShapes[index] = NodePath(astroNode.get_name() + "/" + nodePath)
				
				break
				
		charSwitchWrappers.append(astroCharRes)
	
	if !camPresent:
		var camCharRes = CharacterSwitchingWrapper.new()
		camCharRes.node = camNode.get_name()
		charSwitchWrappers.append(camCharRes)

	
func setClearAllNodes(garboVal):
	#var size = charSwitchWrappers.size()
	for node in charSwitchWrappers:
		if node == null:
			continue
		
		node.nodeCollShapes.resize(0)
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
		applyCSWrapperChanges(delta)
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
	
#	if global.levelWrapperDict.has(currLvlPath):
#		if global.levelWrapperDict[currLvlPath].lvlTimeDiscrepAreaDict.has(currChar):
#			var timeDiscrepDatas = global.levelWrapperDict[currLvlPath].lvlTimeDiscrepAreaDict[currChar][0]
#			timeDiscrepCSWCharDict = timeDiscrepDatas[0]
#			timeDiscrepBodyPresentDict2 = timeDiscrepDatas[1]
#			timeDiscrepManuallyRemovingArea = timeDiscrepDatas[2]
#			timeDiscrepParentNode = global.levelWrapperDict[currLvlPath].lvlTimeDiscrepAreaDict[currChar][1].instance()
#			add_child(timeDiscrepParentNode)
#			timeDiscrepParentNode.set_owner(self)
#			return
			
			
	timeDiscrepParentNode = Node.new()
	timeDiscrepParentNode.set_name("TIME_DISCREP")
#	timeDiscrepArea = Area2D.new()
	add_child(timeDiscrepParentNode)
	timeDiscrepParentNode.set_owner(self)


	for csw in charSwitchWrappers:
		var csNode = get_node(csw.node)
		var timeDiscrepCSWNode = Node.new()
		timeDiscrepCSWNode.set_name("TIME_DISCREP_" + csNode.get_name())
		timeDiscrepParentNode.add_child(timeDiscrepCSWNode)
		timeDiscrepCSWNode.set_owner(timeDiscrepParentNode)
		timeDiscrepCSWCharDict[csw.node] = [timeDiscrepCSWNode.get_name(), {}]
		
		for astroChar in csw.changesToApply.keys():
			addCSWrapCollShape2DiscrepArea(csw, astroChar, null)
	
	print("done")

func addCSWrapCollShape2DiscrepArea(csWrap, astroChar, areaCSW):
	var currChar = global.CharacterRes.id
	var cswNode = get_node(csWrap.node)
	
	
	if global.charYearDict[astroChar] <= global.charYearDict[currChar]: return false
	if csWrap.staticNode && csWrap.checkIfInCharLvl(currChar): return false
	
	#if !csWrap.checkIfInCharLvl(astroChar): return false
	
	
	#if the item exiting does not exist in the astroChar timeline, ignore
	if !csWrap.checkIfInCharLvl(astroChar): return false
	
	#if the area exiting from does not exist in the astroChar timeline, ignore
	if areaCSW != null && !areaCSW.checkIfInCharLvl(astroChar): return false
	
	#if the item exiting is still present in other timeDicrep areas for said timeline, don't add a new spot because one already exists
	if timeDiscrepBodyPresentDict2.has(cswNode.get_name()) && timeDiscrepBodyPresentDict2[cswNode.get_name()].has(astroChar) && timeDiscrepBodyPresentDict2[cswNode.get_name()][astroChar].size() > 0:
		return false
	
	if timeDiscrepCSWCharDict.has(csWrap.node) && timeDiscrepCSWCharDict[csWrap.node][1].has(astroChar): return false

	
	var cswTimeDiscrepNode = timeDiscrepParentNode.get_node(timeDiscrepCSWCharDict[csWrap.node][0])
	
	
	for collShape in csWrap.nodeCollShapes:
		var collShapeNode = get_node(collShape)
		var collShapeNodePos = collShapeNode.get_position()
		var collShapeNodeRot = collShapeNode.get_rotation()
		var collShapeNodeScale = collShapeNode.get_global_scale()
		#assuming every csw will have position has 0 index, and rot as 1
		#TODO: need to make more flexible
		
		if csWrap.changesToApply[astroChar] == null || csWrap.changesToApply[astroChar] == []:
			var csNode = get_node(csWrap.node)
			csWrap.changesToApply[astroChar].resize(2)
			csWrap.changesToApply[astroChar][0] = csNode.get_global_position()
			csWrap.changesToApply[astroChar][1] = csNode.get_global_rotation()
			
		var parentNodePos = csWrap.changesToApply[astroChar][0]
		var parentNodeRot = csWrap.changesToApply[astroChar][1]
		
		var collShapeNodeDup = collShapeNode.duplicate() #duplicate(DUPLICATE_USE_INSTANCING)
		collShapeNodeDup.set_name("TIME_DISCREP_SHAPE_%s_%s_%s" % [csWrap.node, global.astroChar2String(astroChar), collShapeNode.get_name()])
		
		if !timeDiscrepCSWCharDict[csWrap.node][1].has(astroChar):
			var areaNode = Area2D.new()
			areaNode.set_name("TIME_DISCREP_AREA_%s_%s" % [csWrap.node, global.astroChar2String(astroChar)])
			cswTimeDiscrepNode.add_child(areaNode)
			areaNode.set_owner(cswTimeDiscrepNode)
			areaNode.connect("body_entered", self, "bodyEnteredTimeDiscrepArea", [areaNode, astroChar, csWrap])
			areaNode.connect("body_exited", self, "bodyExitedTimeDiscrepArea", [areaNode, astroChar, csWrap])
			
			timeDiscrepCSWCharDict[csWrap.node][1][astroChar] = areaNode.get_name()
			
		
		
		var areaNode = cswTimeDiscrepNode.get_node(timeDiscrepCSWCharDict[csWrap.node][1][astroChar])
		areaNode.add_child(collShapeNodeDup)
		collShapeNodeDup.set_owner(areaNode)
		collShapeNodeDup.set_global_position(collShapeNodePos + parentNodePos)
		collShapeNodeDup.set_global_scale(collShapeNodeScale)
		collShapeNodeDup.set_global_rotation(collShapeNodeRot + parentNodeRot)
	return true





func removeCSWrapTimeDiscepArea2D(csWrap : CharacterSwitchingWrapper, astroChar, areaCSW):
	
	var currChar = global.CharacterRes.id
	var cswNode = get_node(csWrap.node)
	
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
		if !timeDiscrepBodyPresentDict2.has(cswNode.get_name()): return false
		if !timeDiscrepBodyPresentDict2[cswNode.get_name()].has(astroChar): return false
	
	
#	if the item exiting is still present in other timeDicrep areas for said timeline, don't remove
	if timeDiscrepBodyPresentDict2.has(cswNode.get_name()) && timeDiscrepBodyPresentDict2[cswNode.get_name()].has(astroChar) && timeDiscrepBodyPresentDict2[cswNode.get_name()][astroChar].size() != 1:
		return false
	
	if !timeDiscrepCSWCharDict.has(csWrap.node): return false
	#if cswNode == astroNode: return false
	
	var cswTimeDiscrepNode = timeDiscrepParentNode.get_node(timeDiscrepCSWCharDict[csWrap.node][0])
	
	
	if !timeDiscrepCSWCharDict[csWrap.node][1].has(astroChar): return false
	var charAreaNode = cswTimeDiscrepNode.get_node(timeDiscrepCSWCharDict[csWrap.node][1][astroChar])
	if charAreaNode == null: return false
	
	var childrenToDelete = charAreaNode.get_children()
	for ind in childrenToDelete.size():
		charAreaNode.remove_child(childrenToDelete[ind])
		childrenToDelete[ind].queue_free()
	charAreaNode.get_parent().remove_child(charAreaNode)
	charAreaNode.queue_free()
	
	timeDiscrepCSWCharDict[csWrap.node][1].erase(astroChar)
	
	return true



func bodyEnteredTimeDiscrepArea(body, areaNode, astroChar, areaCSW):
	if !body.has_method("CSWrapSaveTimeDiscrepState"): return
	if body == astroNode: return
	
	var currChar = global.CharacterRes.id
	
	var cswrap = null
	for csw in charSwitchWrappers:
		if get_node(csw.node) == body:
			cswrap = csw
			break
			
	if cswrap == null: return
	
#	if !timeDiscrepBodyPresentDict2.has(body):
#		timeDiscrepBodyPresentDict2[body] = {}
#		#for astroChar in cswrap.changesToApply.keys():
#		#	timeDiscrepBodyPresentDict[body]
#
#	if astroChar in timeDiscrepBodyPresentDict2[body].keys():
#		if timeDiscrepBodyPresentDict2[body][astroChar] == areaNode: return
#
#	if !timeDiscrepBodyPresentDict.has(body):
#		timeDiscrepBodyPresentDict[body] = []
#
#	if timeDiscrepBodyPresentDict[body].has(areaNode): return
	
	

	

	for astroChar in cswrap.changesToApply.keys():
		
		if astroChar == currChar: continue
		
		if addCSWrapCollShape2DiscrepArea(cswrap, astroChar, areaCSW):
			body.CSWrapSaveTimeDiscrepState(cswrap, astroChar, true)
			if !timeDiscrepBodyPresentDict2.has(body.get_name()):
				timeDiscrepBodyPresentDict2[body.get_name()] = {}
				
			if !timeDiscrepBodyPresentDict2[body.get_name()].has(astroChar):
				timeDiscrepBodyPresentDict2[body.get_name()][astroChar] = []
			timeDiscrepBodyPresentDict2[body.get_name()][astroChar].append(areaNode)
	
	
func bodyExitedTimeDiscrepArea(body, areaNode, astroChar, areaCSW):
	if timeDiscrepManuallyRemovingArea.has([body, areaNode]): return
	if !body.has_method("CSWrapSaveTimeDiscrepState"): return
	if body == astroNode: return
#	if !timeDiscrepBodyPresentDict.has(body):
#		timeDiscrepBodyPresentDict[body] = []
#	if !timeDiscrepBodyPresentDict[body].has(areaNode): return

	var currChar = global.CharacterRes.id
	
	var cswrap = null
	for csw in charSwitchWrappers:
		if get_node(csw.node) == body:
			cswrap = csw
			break
			
	if cswrap == null: return

#	if !timeDiscrepBodyPresentDict2.has(body):
#		timeDiscrepBodyPresentDict2[body] = {}
	
	#for astroChar in cswrap.changesToApply.keys():
		#if !timeDiscrepBodyPresentDict2[body].has(astroChar): return


			

	
	#removeCSWrapTimeDiscepArea2D(cswrap, astroChar)
	
	for astroChar in cswrap.changesToApply.keys():
		
		if astroChar == currChar: continue
		
		
		if removeCSWrapTimeDiscepArea2D(cswrap, astroChar, areaCSW):
			body.CSWrapSaveTimeDiscrepState(cswrap, astroChar, false)
			if timeDiscrepBodyPresentDict2.has(body.get_name()):
				if timeDiscrepBodyPresentDict2[body.get_name()].has(astroChar):
					timeDiscrepBodyPresentDict2[body.get_name()][astroChar].erase(astroChar)
			
			
			




func restoreCSWrapperState():
	if global.CharacterRes == null: return
	var currChar = global.CharacterRes.id
	
	for csWrap in charSwitchWrappers:
		if csWrap.staticNode:continue
		print(csWrap.node)
		if csWrap.checkIfInCharLvl(currChar):
			var nd = get_node(csWrap.node)
			if nd.has_method("CSWrapRestoreState"):
				nd.CSWrapRestoreState(csWrap)
						

func applyCSWrapperChanges(delta):
	if global.CharacterRes == null: return
	var currChar = global.CharacterRes.id

	
	for csWrap in charSwitchWrappers:
		if csWrap.staticNode: continue
		#print(csWrap.node)
		if csWrap.checkIfInCharLvl(currChar):
			if csWrap.changesToApply[currChar] == []: continue
			var nd = get_node(csWrap.node)
			nd.CSWrapApplyChanges(csWrap, delta)
			nd.CSWrapApplyDependantChanges(csWrap, delta)



func saveCSWrapperStartStates():
	
	
	#need to add to both registered and charSwitchWrappers
	for csWrap in charSwitchWrappers:
		if csWrap.staticNode: continue
		if csWrap.checkIfInCharLvl(global.CharacterRes.id):
			get_node(csWrap.node).CSWrapSaveStartState(csWrap)




func removeDisabledCSWrapperNodes():
	for csWrap in charSwitchWrappers:
		if !csWrap.checkIfInCharLvl(global.CharacterRes.id):
			var nodeObj = get_node(csWrap.node)
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
