tool
extends Resource

class_name CharacterSwitchingWrapper

const cswSavesFolder = "res://RESOURCES/CSW_SAVES/"



var dependantCSWrappers = {CharacterRes.CHAR.USA : [],
							 CharacterRes.CHAR.RUS : [],
							 CharacterRes.CHAR.FRA : [],
							 CharacterRes.CHAR.CHN : [],
							 CharacterRes.CHAR.MAR : []}

var extraCSWrappers = []

var saveStartState = {CharacterRes.CHAR.USA : [],
						 CharacterRes.CHAR.RUS : [],
						 CharacterRes.CHAR.FRA : [],
						 CharacterRes.CHAR.CHN : [],
						 CharacterRes.CHAR.MAR : []}
						
var changesToApply = {CharacterRes.CHAR.USA : [],
						CharacterRes.CHAR.RUS : [],
						CharacterRes.CHAR.FRA : [],
						CharacterRes.CHAR.CHN : [], 
						CharacterRes.CHAR.MAR : []}
						
var savedTimeDiscrepencyState = {CharacterRes.CHAR.USA : [], 
								CharacterRes.CHAR.RUS : [], 
								CharacterRes.CHAR.FRA : [], 
								CharacterRes.CHAR.CHN : [], 
								CharacterRes.CHAR.MAR : []}

#hack for getting the lvl node (which assigned in lvl.gd whenever a new node is added)
var currLvlNode
signal requestLvlNodeSig

export (NodePath) var nodePath
export (bool) var setFullNodePath = false setget setFullNP
export (bool) var setKeyName = false setget setKey
export (String) var customNodePath
export (bool) var assignCustomNodePath = false setget setCustomNodePath
var assigningCustomPath = false

export (bool) var addPlugConfig = false setget setPlugConfiguration
export (bool) var addBlockConfig = false setget setBlockConfiguration
export (bool) var addObjectConfig = false setget setObjectConfigurtion
export (Array) var groups #setget saveGroups
export (bool) var addNodeGroups = false setget setNodeGroups
	
export (Array, NodePath) var nodeCollShapePaths

	
export (String) var customNCSPath
export (bool) var addCustomNCSPath = false setget setCustomNCSPath
# setting this default to [] was causeing weird ass shit where it was saving its state
#across every new(). Should report to godot community
export (bool) var staticNode = false
export (bool) var USA = true
export (bool) var RUS = true
export (bool) var FRA = true
export (bool) var CHN = true
export (bool) var MAR = true



#//////////////////////  START OF SETGET METHODS  #//////////////////////

func setNodePath(val):
	if !Engine.editor_hint:
		print("wttf")

	else:
		requestLvlNode()
		if currLvlNode == null: return

	nodePath = getActualNodePath(val) if Engine.editor_hint else val

	if !Engine.editor_hint : return

	if currLvlNode!= null:

		if currLvlNode.get_node(val) != null:
			addNCSPsToCSW(currLvlNode.get_node(val))
			addGroupsToCSW(currLvlNode.get_node(val))
#


func setFullNP(garboVal):
	if !garboVal: return
	if !Engine.editor_hint: return
	setFullNodePath = false
	nodePath = getActualNodePath(nodePath)
	property_list_changed_notify()

func setKey(garboVal):
	if !garboVal: return
	if !Engine.editor_hint: return

	requestLvlNode()
	if currLvlNode != null:
		var newName = getCSWName(currLvlNode)
		if newName != null && newName != "":
			print("new name:")
			print(newName)
			newName = newName.replace("/", "---")
			currLvlNode.changeCSWKey(self, newName)
	property_list_changed_notify()
	currLvlNode.property_list_changed_notify()

func setNodeGroups(garboVal):
	addNodeGroups = false

	var path = getEditorNodePath(nodePath)
	if path != null && currLvlNode != null && currLvlNode.get_node(path) != null:

		addNCSPsToCSW(currLvlNode.get_node(path))
		addGroupsToCSW(currLvlNode.get_node(path))
		
	property_list_changed_notify()

func setPlugConfiguration(val):
	if !Engine.editor_hint : return
	addPlugConfig = false
	setConfig("/plugArea/plugAreaShape")
	if !groups.has("plug"):
		groups.append("plug")
		
	property_list_changed_notify()
	
func setBlockConfiguration(val):
	if !Engine.editor_hint : return
	addBlockConfig = false
	setConfig("/KinematicBody2D/CollisionShape2D")
	if !groups.has("block"):
		groups.append("block")
	if !groups.has("solid"):
		groups.append("solid")
#	if !groups.has("movingPlatform"):
#		groups.append("movingPlatform")
		
	property_list_changed_notify()

func setObjectConfigurtion(val):
	if !val: return
	if !Engine.editor_hint: return
	addObjectConfig = false
	setConfig("/OBJ_SHAPE")
	if !groups.has("object"):
		groups.append("object")
	if !groups.has("solid"):
		groups.append("solid")
		
	property_list_changed_notify()
	
func setConfig(shapeStringPath: String):
	if !Engine.editor_hint: return
	if nodePath == null: return
	var stringPath = ""
	for i in nodePath.get_name_count():
		stringPath = stringPath + "/" + nodePath.get_name(i)
	
	var plugCollShapePath = stringPath + shapeStringPath
	if !nodeCollShapePaths.has(plugCollShapePath):
		var size = nodeCollShapePaths.size()
		nodeCollShapePaths.resize(size + 1)
		nodeCollShapePaths[size] = (NodePath(plugCollShapePath))

func setCustomNodePath(val):
	if !val: return
	if !Engine.editor_hint: return
	assignCustomNodePath = false
	assigningCustomPath = true
	if customNodePath != null && customNodePath != "":
		nodePath = NodePath(customNodePath)
	customNodePath = ""
	assigningCustomPath = false
	property_list_changed_notify()

func setCustomNCSPath(val):
	if !val: return
	if !Engine.editor_hint: return
	addCustomNCSPath = false
	if customNCSPath != null && customNCSPath != "" && !nodeCollShapePaths.has(NodePath(customNCSPath)):
		nodeCollShapePaths.append(NodePath(customNCSPath))
	customNCSPath = ""
	saveNCSP(nodeCollShapePaths)
	
	property_list_changed_notify()





func saveGroups(val):
	groups = val
	

func saveNCSP(val):
	nodeCollShapePaths = val
	if !Engine.editor_hint : return
	for ndpath in nodeCollShapePaths:
		ndpath = val
		

	
	




#//////////////////////  END OF SETGET METHODS  #//////////////////////

#//////////////////////  START OF PREVENTING VARIABLE RESET METHODS  #//////////////////////
#.........(this is all so that when ever I edit code in this file, the current 
#.........data in the wrappers is not reset after saving)
static func getSaveFilePath(sceneName, name):
	if sceneName == null || name == null: return null
	return cswSavesFolder + sceneName + "/" + name + ".tres"

static func getSaveFileDirPath(sceneName):
	if sceneName == null: return null
	return cswSavesFolder + sceneName + "/"

func saveThisResource(sceneName, name):
	if sceneName == null || name == null: return
	var dirPath = cswSavesFolder + sceneName + "/"
	var dir = Directory.new()
	if !dir.dir_exists(dirPath):
		dir.make_dir(dirPath)
		
	ResourceSaver.save(dirPath + name + ".tres", self)

	

func requestLvlNode():
	emit_signal("requestLvlNodeSig", self)

func getLvlNode(thatLvlNode):
	currLvlNode = thatLvlNode




#//////////////////////  END OF PREVENTING VARIABLE RESET METHODS  #//////////////////////

#//////////////////////  START OF WRAPPER HELPER METHODS  #//////////////////////

func addNCSPsToCSW(node):
	if node == null: return
	requestLvlNode()
	if currLvlNode == null: return
	for child in node.get_children():
		addGroupsToCSW(child)
		if child is CollisionShape2D:
			

			var pathToSet = getActualNodePath(child.get_path())

			if !nodeCollShapePaths.has(pathToSet): 
	
				nodeCollShapePaths.resize(nodeCollShapePaths.size()+1)
				var index = nodeCollShapePaths.size() -1
	
				nodeCollShapePaths[index] = pathToSet

		if child is StaticBody2D || child is KinematicBody2D:
			for childChild in child.get_children():
				addGroupsToCSW(childChild)
				if childChild is CollisionShape2D:
					
					var pathToSet = getActualNodePath(childChild.get_path())

					if nodeCollShapePaths.has(pathToSet): continue
					nodeCollShapePaths.resize(nodeCollShapePaths.size() + 1)
					var index = nodeCollShapePaths.size()-1

					nodeCollShapePaths[index] = pathToSet


func addGroupsToCSW(node):
	if node == null: return

	for group in node.get_groups():
		if group.find_last("root_canvas") != -1: continue
		if group.find_last("_cameras") != -1: continue
		if group == "physics_process": continue
		if groups.has(group) : continue
		groups.append(group)



func getCSWName(lvlNode = null):
	if lvlNode == null:
		requestLvlNode()
		if currLvlNode == null: return null
		lvlNode = currLvlNode

	var path = nodePath
	if path == null: return
	var track = false
	var nameString = ""
	for i in path.get_name_count():
		var string = path.get_name(i)
		
		if nameString == "":
			nameString = string
		else:
			nameString = nameString + "/" + string

		if !track && string == lvlNode.get_name():
			track = true
			nameString = ""
			continue

		
	return nameString

func getEditorNodePath(path = null, lvlNode = null):
	var newPath = getActualNodePath(path, lvlNode)
	
	if lvlNode == null:
		requestLvlNode()
		if currLvlNode == null: return path
		lvlNode = currLvlNode
	
	if newPath == null: return null
	
	var newPathString = ""
	for i in newPath.get_name_count():
		if newPath.get_name(i) == lvlNode.get_name():
			newPathString = ""
			continue
		if newPathString == "":
			newPathString = newPath.get_name(i)
		else:
			newPathString = newPathString + "/" + newPath.get_name(i)
		
	return NodePath(newPathString)
		
		

func getActualNodePath(path = null, lvlNode = null):
	if path == null:
		path = nodePath
		if path == null: return path

	if lvlNode == null:
		requestLvlNode()
		if currLvlNode == null: return path
		lvlNode = currLvlNode


	var topNodeNameIndex = null
	var nameSoFar = ""
	if !path is NodePath || path.get_name_count() <= 0:
		return path

	for i in path.get_name_count():
		nameSoFar = nameSoFar + "/" + path.get_name(i)
		if path.get_name(i) == lvlNode.get_name():
			topNodeNameIndex = i
			break


	var newPath = "/root"

	if topNodeNameIndex == null:
		newPath = newPath + "/" + lvlNode.get_name() + nameSoFar
	else:
		for k in (path.get_name_count()-topNodeNameIndex):
			newPath = newPath +  "/" + path.get_name(k+topNodeNameIndex)

	#print("vvvvv Ignore 'Node not found' errors (because the path only exists at runtime) vvvv")
	return (NodePath(newPath))




func getDependantGroup():
	var groupArray = [self]
	
	for dependant in dependantCSWrappers[global.currCharRes.id]:
		var dependantArray = dependant.getDependantGroup()
		for val in dependantArray:
			groupArray.append(val)
	return groupArray
	

	
func findNodeAbove(dependantGroupNodes, ogNodeAbove, node):
	if ogNodeAbove[node] == node:
		return ogNodeAbove[node]
	
	for dpNode in dependantGroupNodes:
		if ogNodeAbove[node] == dpNode:
			return findNodeAbove(dependantGroupNodes, ogNodeAbove, dpNode)
			
	return ogNodeAbove[node]
	
	
func checkIfInCharLvl(currChar):
	match currChar:
		CharacterRes.CHAR.USA:
			return USA
		CharacterRes.CHAR.RUS:
			return RUS
		CharacterRes.CHAR.FRA:
			return FRA
		CharacterRes.CHAR.CHN:
			return CHN
		CharacterRes.CHAR.MAR:
			return MAR
	
#//////////////////////  END OF WRAPPER HELPER METHODS  #//////////////////////

