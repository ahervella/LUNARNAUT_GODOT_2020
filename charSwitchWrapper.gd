tool
extends Resource

class_name CharacterSwitchingWrapper


var dependantCSWrappers = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var extraCSWrappers = []
var saveStartState = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var changesToApply = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var savedTimeDiscrepencyState = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}


export (NodePath) var nodePath
export (String) var customNodePath
export (bool) var assignCustomNodePath = false
export (bool) var addPlugConfig = false setget setPlugConfiguration
export (bool) var addBlockConfig = false setget setBlockConfiguration
export (bool) var addObjectConfig = false setget setObjectConfigurtion
export (Array) var groups
export (Array, NodePath) var nodeCollShapePaths
export (String) var customNCSPath
export (bool) var addCustomNCSPath = false setget setCustomNCSPath
# setting this default to [] was causeing weird ass shit where it was saving its state
#across every new(). Should report to godot community
export (bool) var staticNode = false
export (bool) var USA = true
#export (NodePath) var USA_relativeNode = null
export (bool) var RUS = true
#export (NodePath) var RUS_relativeNode = null
export (bool) var FRA = true
#export (NodePath) var FRA_relativeNode = null
export (bool) var CHN = true
#export (NodePath) var CHN_relativeNode = null
export (bool) var MAR = true
#export (NodePath) var MAR_relativeNode = null


		
	

func setPlugConfiguration(val):
	addPlugConfig = false
	setConfig("/plugArea/plugAreaShape")
	if !groups.has("plug"):
		groups.append("plug")
	
func setBlockConfiguration(val):
	addBlockConfig = false
	setConfig("/StaticBody2D/CollisionShape2D")
	if !groups.has("block"):
		groups.append("block")
	if !groups.has("solid"):
		groups.append("solid")

func setObjectConfigurtion(val):
	addObjectConfig = false
	setConfig("/OBJ_SHAPE")
	if !groups.has("object"):
		groups.append("object")
	if !groups.has("solid"):
		groups.append("solid")
	
func setConfig(shapeStringPath: String):
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
	assignCustomNodePath = false
	if customNodePath != null && customNodePath != "":
		nodePath = NodePath(customNodePath)
	customNodePath = ""

func setCustomNCSPath(val):
	addCustomNCSPath = false
	if customNCSPath != null && customNCSPath != "" && !nodeCollShapePaths.has(NodePath(customNCSPath)):
		nodeCollShapePaths.append(NodePath(customNCSPath))
	customNCSPath = ""


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
	
	

