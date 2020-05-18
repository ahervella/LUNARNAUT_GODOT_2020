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
export (Array, Resource) var charSwitchWrappers

var trigChunkNode
var ASTRO_GLOBAL_START_POS : Vector2
var ASTRO_FACE_RIGHT : bool
var ASTRO_HEALTH : int

var CAM_GLOBAL_START_POS : Vector2

var levelNodes : Dictionary

var Inventory : Dictionary

var oneShotAddAstroAndCam = true

func setAddAstroAndCam(garboVal):
	addAstroAndCamPerChar()
	
func setAddAllChildNodes(garboVal):
	addAstroAndCamPerChar()
	
	for child in get_children():
		var alreadyPresent = false
		
		for resNode in charSwitchWrappers:
			if get_node(resNode.node) == child:
				alreadyPresent = true
				break
		
		if !alreadyPresent:
			var childRes = CharacterSwitchingWrapper.new()
			#name can actually act as a readable node path
			childRes.node = child.get_name()
			charSwitchWrappers.append(childRes)
	
	
func setClearAllNodes(garboVal):
	charSwitchWrappers.resize(0)
	

func _ready():
	
	#prevent from running in editor
	if Engine.editor_hint:
		return
	
	
	global.playTest = playTest
	astroNode = get_node(astroNodePath)
	if (trigChunkNodePath != null):
		trigChunkNode = get_node(trigChunkNodePath)
	global.interactNode = astroNode.INTERACT_TEXT_NODE
	

	
	for node in characterSpecificNodes():
		remove_child(node)
	
	#laod the first ever positions if first time loading this level with this character
	for csWrap in charSwitchWrappers:
		if csWrap.charNodeFormerPosDict[global.CharacterRes.id] == null:
			csWrap.charNodeFormerPosDict[global.CharacterRes.id] = get_node(csWrap.node).get_global_position()
	
func addAstroAndCamPerChar():
	var astroPresent = false
	var astroAnimSpritePresent = false
	var camPresent = false
	
	var astro = get_node(astroNodePath)
	var astroAnimSprite
	var camNode
	for astroChild in astro.get_children():
		if astroChild is AnimatedSprite:
			astroAnimSprite = astroChild
	for child in get_children():
		if child is Camera2D:
			camNode = child 
	
	
	for resNode in charSwitchWrappers:
		if get_node(resNode.node) == astro:
			astroPresent = true
		
		if get_node(resNode.node) == astroAnimSprite:
			astroAnimSpritePresent = true
		
		if get_node(resNode.node) == camNode:
			camPresent = true
			


	
	if !astroPresent:
		var astroCharRes = CharacterSwitchingWrapper.new()
		astroCharRes.node = astroNodePath
		charSwitchWrappers.append(astroCharRes)
		astroCharRes.neverAffectFuture = true
	
#	if !astroAnimSpritePresent:
#		var astroSpriteCharRes = CharacterSwitchingWrapper.new()
#		#name can actually act as a readable nodePath
#		astroSpriteCharRes.node = astro.get_name() + "/" + astroAnimSprite.get_name()
#		charSwitchWrappers.append(astroSpriteCharRes)

	if !camPresent:
		var camCharRes = CharacterSwitchingWrapper.new()
		camCharRes.node = camNode.get_name()
		charSwitchWrappers.append(camCharRes)
		camCharRes.neverAffectFuture = true

	
func characterSpecificNodes(restoreNodePos = true, node = self):
	
	var currChar = global.CharacterRes.id
	var delChildren = []
	for child in node.get_children():
		for charID in charSwitchWrappers:
			if charID is CharacterSwitchingWrapper:
				var nodee = get_node(charID.node)
				if nodee == child:
					print(child.name)
					
					var keep = true
					
					match currChar:
						global.CHAR.USA:
							keep = charID.USA
							
							continue
						global.CHAR.RUS:
							keep = charID.RUS
							continue
						global.CHAR.FRA:
							keep = charID.USA
							continue
						global.CHAR.CHN:
							keep = charID.CHN
							continue
						global.CHAR.MAR:
							keep = charID.MAR
							
							
					if !keep:
						delChildren.append(child)
						break
					
					if charID.processed:
						charID.processed = false
						break
					
					if restoreNodePos:
						if child.has_method("handleCharSwitchRestore"):
							child.handleCharSwitchRestore(charID)
							
						else:
							var relNode = null
							if charID.relativeNode[currChar] != null:
								relNode = get_node(charID.relativeNode[currChar])
							
							charID.defaultRestore(currChar, child, relNode)
#							if charID.charNodePosDict[currChar] != null:
#								var pos = charID.charNodePosDict[currChar]
#								#if position was relative to an object, set pos relative to it
#								if charID.relativeNode[currChar] != null:
#									pos += get_node(charID.relativeNode[currChar]).get_global_position()
#								child.set_global_position(pos)
#
#							if charID.isFlipped[currChar] != null:
#								child.set_flip_h(charID.isFlipped[currChar])
					
						
					if !restoreNodePos:
						
						if child.has_method("handleCharSwitchSave"):
							child.handleCharSwitchSave(charID)
							
						else:
							var relNode = null
							if child.has_method("getRelativeNodeBelow"):
							
								relNode = child.getRelativeNodeBelow()
							
							charID.defaultSave(currChar, child, relNode)
						
#						getRelativeNodeBelow(child)
#
#						var relNodePos = child.get_global_position()
#						if charID.relativeNode[currChar] != null:
#							relNodePos -= get_node(charID.relativeNode[currChar]).get_global_position()
#
#						charID.charNodePosDict[currChar] = relNodePos
#
#						if child.has_method("is_flipped_h"):
#							print(charID.node)
#							charID.isFlipped[currChar] = child.is_flipped_h()
#
#						if child == astroNode:
#							print(charID.charNodePosDict)
#							print(charID.isFlipped)
						
					break
					
					
					
		if child.get_children().size() > 0:
			for childNode in characterSpecificNodes(restoreNodePos, child):
				delChildren.push_front(childNode)
	return delChildren
	
#here we set relative node for objects that can change location.
#right now: astro, movable objs, and cables
func getRelativeNodeBelow(node):
	if node.has_method("getRelativeNodeBelow"):
		return node.getRelativeNodeBelow()
	return null
	
#	if node.is_in_group("astro"):
#		return node.firstSolidBodyNode
#
#	if node.is_in_group("object"):
#
	
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
