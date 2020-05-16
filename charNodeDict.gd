tool
extends Resource

class_name CharacterNodeDict

var charNodePosDict = {global.CHAR.USA : null, global.CHAR.RUS : null, global.CHAR.FRA : null, global.CHAR.CHN : null, global.CHAR.MAR : null}

export (NodePath) var node
export (bool) var USA = true
export (bool) var RUS = true
export (bool) var FRA = true
export (bool) var CHN = true
export (bool) var MAR = true


#func setNode(val):
#	node = val
#	if node != null && node.has_method("get_name"):
#		nodeName = node.get_name()
#
#func setName(val):
#	return
