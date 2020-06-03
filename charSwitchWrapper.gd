tool
extends Resource

class_name CharacterSwitchingWrapper


var dependantCSWrappers = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var extraCSWrappers = []
var saveStartState = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var changesToApply = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var savedTimeDiscrepencyState = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}

export (NodePath) var node
export (Array, NodePath) var nodeCollShapes 
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
	
	

