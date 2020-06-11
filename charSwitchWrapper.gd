tool
extends Resource

class_name CharacterSwitchingWrapper

const cswSavesFolder = "res://RESOURCES/CSW_SAVES/"
var dontSave = true
var dontInit 


var dependantCSWrappers = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var extraCSWrappers = []
var saveStartState = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var changesToApply = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var savedTimeDiscrepencyState = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}

#hack for getting the lvl node (which assigned in lvl.gd whenever a new node is added)
var currLvlNode
signal requestLvlNodeSig

export (NodePath) var nodePath #= null setget setNodePath
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
	
export (Array, NodePath) var nodeCollShapePaths #setget saveNCSP

	
export (String) var customNCSPath
export (bool) var addCustomNCSPath = false setget setCustomNCSPath
# setting this default to [] was causeing weird ass shit where it was saving its state
#across every new(). Should report to godot community
export (bool) var staticNode = false
export (bool) var USA = true setget saveUSA
export (bool) var RUS = true setget saveRUS
export (bool) var FRA = true setget saveFRA
export (bool) var CHN = true setget saveCHN
export (bool) var MAR = true setget saveMAR



#//////////////////////  START OF SETGET METHODS  #//////////////////////

func setNodePath(val):
	if !Engine.editor_hint:
		print("wttf")
		
	else:
		requestLvlNode()
		if currLvlNode == null: return
		
	nodePath = getActualNodePath(val) if Engine.editor_hint else val

	saveToFile("nodePath")
		
	if !Engine.editor_hint : return

	if currLvlNode!= null:
	
		if currLvlNode.get_node(val) != null:
			addNCSPsToCSW(currLvlNode.get_node(val))
			addGroupsToCSW(currLvlNode.get_node(val))



func setFullNP(garboVal):
	setFullNodePath = false
	nodePath = getActualNodePath(nodePath)

func setKey(garboVal):
	if !Engine.editor_hint: return

	requestLvlNode()
	if currLvlNode != null:
		var newName = getCSWName(currLvlNode)
		if newName != null && newName != "":
			print("neew name:")
			print(newName)
			currLvlNode.changeCSWKey(self, newName)

func setNodeGroups(garboVal):
	addNodeGroups = false

	var path = getEditorNodePath(nodePath)
	if path != null && currLvlNode != null && currLvlNode.get_node(path) != null:

		addNCSPsToCSW(currLvlNode.get_node(path))

func setPlugConfiguration(val):
	if !Engine.editor_hint : return
	addPlugConfig = false
	setConfig("/plugArea/plugAreaShape")
	if !groups.has("plug"):
		groups.append("plug")
	
func setBlockConfiguration(val):
	if !Engine.editor_hint : return
	addBlockConfig = false
	setConfig("/StaticBody2D/CollisionShape2D")
	if !groups.has("block"):
		groups.append("block")
	if !groups.has("solid"):
		groups.append("solid")

func setObjectConfigurtion(val):
	if !Engine.editor_hint : return
	addObjectConfig = false
	setConfig("/OBJ_SHAPE")
	if !groups.has("object"):
		groups.append("object")
	if !groups.has("solid"):
		groups.append("solid")
	
func setConfig(shapeStringPath: String):
	if !Engine.editor_hint : return
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
	if !Engine.editor_hint : return
	assignCustomNodePath = false
	assigningCustomPath = true
	if customNodePath != null && customNodePath != "":
		nodePath = NodePath(customNodePath)
	customNodePath = ""
	assigningCustomPath = false

func setCustomNCSPath(val):
	if !Engine.editor_hint : return
	addCustomNCSPath = false
	if customNCSPath != null && customNCSPath != "" && !nodeCollShapePaths.has(NodePath(customNCSPath)):
		nodeCollShapePaths.append(NodePath(customNCSPath))
	customNCSPath = ""
	saveNCSP(nodeCollShapePaths)





func saveGroups(val):
	groups = val
	
	saveToFile("groups")


func saveNCSP(val):
	nodeCollShapePaths = val
	if !Engine.editor_hint : return
	for ndpath in nodeCollShapePaths:
		ndpath = val
		
	saveToFile("nodeCollShapePaths")


func saveUSA(val):
	USA = val
	saveToFile("USA")
func saveRUS(val):
	RUS = val
	saveToFile("RUS")
func saveFRA(val):
	FRA = val
	saveToFile("FRA")
func saveCHN(val):
	CHN = val
	saveToFile("CHN")
func saveMAR(val):
	MAR = val
	saveToFile("MAR")
	
	

func saveToFile(propertyString):
	if !Engine.editor_hint : return
	if dontSave: return
	var file2Check = File.new()
	var file = {}
	
	var filePath = "res://RESOURCES/CSW_SAVES/dev_cable_gravity.json"#getCSWSaveFilePath(currLvlNode)
	
	if file2Check.file_exists(filePath):
		file2Check.open(filePath, File.READ)
		file = parse_json(file2Check.get_line()).duplicate(true)
		file2Check.close()
		
	if !file.has(to_string()):
		file[to_string()] = {}
		
	file[to_string()][propertyString] = get(propertyString)
	file2Check.open(filePath, File.WRITE)
	
	file2Check.store_line(to_json(file))
	
	file2Check.close()




#//////////////////////  END OF SETGET METHODS  #//////////////////////

#//////////////////////  START OF PREVENTING VARIABLE RESET METHODS  #//////////////////////
#.........(this is all so that when ever I edit code in this file, the current 
#.........data in the wrappers is not reset after saving)
static func getCSWSaveFilePath(lvlNode):
	return cswSavesFolder + lvlNode.getLvlSceneName() + ".json"


func _init():
	if !Engine.editor_hint : return
	call_deferred("init_deferred")

func init_deferred():
	dontSave = true
	if dontInit != null && dontInit: return
	
	var file2Check = File.new()
	var file = {}
	
	var filePath = "res://RESOURCES/CSW_SAVES/dev_cable_gravity.json"#getCSWSaveFilePath(currLvlNode)
	
	if file2Check.file_exists(filePath):
		file2Check.open(filePath, File.READ)
		file = parse_json(file2Check.get_line())
		file2Check.close()
		
	if file.has(to_string()):
		loadAllVariables(to_string(), file)
			
	dontSave = false
	dontInit = true
	
	saveAllVariables()

func loadAllVariables(fileKey, file):

	for key in file[fileKey].keys():
		if key == "nodePath":
			set(key, NodePath(file[fileKey][key]))
			
		elif key == "nodeCollShapePaths":
			var ncspArray = []
			for ncsp in file[fileKey][key]:
				ncspArray.append(NodePath(ncsp))
				
			set(key, ncspArray)
		else:
			set(key, file[fileKey][key])

func saveAllVariables():

	saveToFile("nodePath")
	saveToFile("nodeCollShapePaths")
	saveToFile("groups")
	saveToFile("USA")
	saveToFile("RUS")
	saveToFile("FRA")
	saveToFile("CHN")
	saveToFile("MAR")
	

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

		if child is StaticBody2D:
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
	
	for dependant in dependantCSWrappers[global.CharacterRes.id]:
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
		global.CHAR.USA:
			return USA
		global.CHAR.RUS:
			return RUS
		global.CHAR.FRA:
			return FRA
		global.CHAR.CHN:
			return CHN
		global.CHAR.MAR:
			return MAR
	
#//////////////////////  END OF WRAPPER HELPER METHODS  #//////////////////////

