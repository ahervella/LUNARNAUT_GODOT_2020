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
var processDone = true
var timeDiscrepArea
var timeDiscrepAreaBodyDict = {}

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
				var nodePath = NodePath(child.get_name())
				astroCharRes.nodeCollShapes.resize(astroCharRes.nodeCollShapes.size() + 1)
				var index = astroCharRes.nodeCollShapes.size() -1
				astroCharRes.nodeCollShapes[index] = nodePath
				
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

	if readyDone && !processDone:
		loadCSWrappersFromGlobal()
		addCSWrapperTimeDiscrepencyAreas()
		
		removeDisabledCSWrapperNodes()
		restoreCSWrapperState()
		#restoreExtraCSWrapperState()
		applyCSWrapperChanges(delta)
		saveCSWrapperStartStates()
		set_physics_process(false)
		print("iosudhfaiusdhfiaushdfiaushdfisuhf")
		processDone = true

	elif readyDone:
		processDone = false


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
	
	if global.levelWrapperDict.has(currLvlPath):
		if global.levelWrapperDict[currLvlPath].lvlTimeDiscrepAreaDict.has(currChar):
			timeDiscrepAreaBodyDict = global.levelWrapperDict[currLvlPath].lvlTimeDiscrepAreaDict[currChar][0]
			timeDiscrepArea = global.levelWrapperDict[currLvlPath].lvlTimeDiscrepAreaDict[currChar][1].instance()
			add_child(timeDiscrepArea)
			timeDiscrepArea.set_owner(self)
			timeDiscrepArea.connect("body_entered", self, "bodyEnteredTimeDiscrepArea")
			timeDiscrepArea.connect("body_exited", self, "bodyExitedTimeDiscrepArea")
			return
			
	timeDiscrepArea = Area2D.new()
	add_child(timeDiscrepArea)
	timeDiscrepArea.set_owner(self)
	
	timeDiscrepArea.connect("body_entered", self, "bodyEnteredTimeDiscrepArea")
	timeDiscrepArea.connect("body_exited", self, "bodyExitedTimeDiscrepArea")
	
	for csWrap in charSwitchWrappers:
		if !csWrap.checkIfInCharLvl(currChar):
			for astroChar in global.CHAR:
				if global.charYearDict[global.CHAR[astroChar]] > global.charYearDict[currChar]:
					addCSWrapCollShape2DiscrepArea(csWrap)
				
			#var csWrapNode = get_node(csWrap.node)
			#remove_child(csWrapNode)
		
		if get_node(csWrap.node) == astroNode:
			for astroChar in csWrap.changesToApply.keys():
				if astroChar == currChar : continue
				if csWrap.changesToApply[astroChar] == null: continue
				if global.charYearDict[astroChar] < global.charYearDict[currChar]: continue
				#if array is has at least 3, [3] is not null, and is false
				if csWrap.changesToApply[astroChar].size() > 2 && csWrap.changesToApply[astroChar][3] != null && !csWrap.changesToApply[astroChar][3]:
					for collShape in csWrap.nodeCollShapes:
						var collShapeNode = astroNode.get_node(collShape)
						#assuming all astro chars have the same shape
						var astroPos = csWrap.changesToApply[astroChar][0]
						var astroRot = csWrap.changesToApply[astroChar][1]
						var localPos = collShapeNode.get_position()
						var localRot = collShapeNode.get_rotation()
						var collShapeNodeDup = collShapeNode.duplicate()#DUPLICATE_USE_INSTANCING)
						collShapeNodeDup.set_name("TIME_DISCREP_" + csWrap.node + "_" + collShapeNode.get_name())
						for group in collShapeNodeDup.get_groups():
							collShapeNodeDup.remove_from_group(group)
						timeDiscrepArea.add_child(collShapeNodeDup)
						collShapeNodeDup.set_owner(timeDiscrepArea)
						collShapeNodeDup.set_global_position(astroPos + localPos)
						collShapeNodeDup.set_global_rotation(astroRot + localRot)
						
					#save dictionary of areas!!!
					#need to add area if restricted by area
					#areas may only be certain character exclusives
					
func addCSWrapCollShape2DiscrepArea(csWrap):
	if timeDiscrepAreaBodyDict.has(csWrap.node): return
	
	
	
	timeDiscrepAreaBodyDict[csWrap.node] = []
	for collShape in csWrap.nodeCollShapes:
		var collShapeNode = get_node(collShape)
		var collShapeNodePos = collShapeNode.get_global_position()
		var collShapeNodeScale = collShapeNode.get_global_scale()
		var collShapeNodeRot = collShapeNode.get_global_rotation()
		var collShapeNodeDup = collShapeNode.duplicate() #duplicate(DUPLICATE_USE_INSTANCING)
		collShapeNodeDup.set_name("TIME_DISCREP_" + csWrap.node + "_" + collShapeNode.get_name())
		timeDiscrepArea.add_child(collShapeNodeDup)
		collShapeNodeDup.set_owner(timeDiscrepArea)
		collShapeNodeDup.set_global_position(collShapeNodePos)
		collShapeNodeDup.set_global_scale(collShapeNodeScale)
		collShapeNodeDup.set_global_rotation(collShapeNodeRot)
		timeDiscrepAreaBodyDict[csWrap.node].append(collShapeNodeDup.get_name())
				
func bodyEnteredTimeDiscrepArea(body):
	if body.has_method("CSWrapSaveTimeDiscrepState"):
		for cswrap in charSwitchWrappers:
			if get_node(cswrap.node) == body:
				body.CSWrapSaveTimeDiscrepState(cswrap, true)
				
				if !body.is_in_group("astro"):
					addCSWrapCollShape2DiscrepArea(cswrap)
				
				#var collShapeNode = get_node(cswrap)
				print("Worked!!!!")
	
	
func bodyExitedTimeDiscrepArea(body):
	if body.has_method("CSWrapSaveTimeDiscrepState"):
		for cswrap in charSwitchWrappers:
			if get_node(cswrap.node) == body:
				
				if timeDiscrepAreaBodyDict.has(cswrap.node):
					var childrenToRemove = []
					for child in timeDiscrepArea.get_children():
						if timeDiscrepAreaBodyDict[cswrap.node].has(child.get_name()):
							childrenToRemove.append(child)
					
					for child in childrenToRemove:
						timeDiscrepArea.remove_child(child)
						child.queue_free()
						
					childrenToRemove.resize(0)
					timeDiscrepAreaBodyDict.erase(cswrap.node)
					
				body.CSWrapSaveTimeDiscrepState(cswrap, false)

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
