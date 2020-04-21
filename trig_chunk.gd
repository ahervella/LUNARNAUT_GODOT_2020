tool
extends Node


export (bool) var PrintLevelChunkingReport = false setget levelChunkingReportSet
export (bool) var IncludeAllGroups = false
export (String) var SearchNodes = ""
var lvlNodes : Array
const LAYER_SEPERATOR = "^^^^"
const INTENDED_CHUNK_GROUPS = ["chunk_ship", "chunk_cave", "chunk_lab"]


func onRightSide(body, shapeNode):
	var detector_pos = shapeNode.get_global_position()
	var astro_pos = global.lvl().astroNode.get_global_position()
	return ((astro_pos.x - detector_pos.x)>0)



func levelChunkingReportSet(val):
	#all of this is only for the editor
	if !Engine.editor_hint:
		return
	
	print("")
	print("vvvvvvvvvvvv CHUNK GROUPS REPORT vvvvvvvvvvvv")
	
	for node in get_parent().get_children():
		if (node.name == name):
			continue
		printNodeTree(node, 0)
	
	PrintLevelChunkingReport = false




func printNodeTree(node, layer):
	
	
	if (layer == 0):
		print("")
	
	var tabString : String = "["
	
	if (node.get_groups().size() > 0):
		for group in node.get_groups():
			if (INTENDED_CHUNK_GROUPS.has(group) || IncludeAllGroups):
				if (SearchNodes != "" && group in SearchNodes):
					tabString = str(tabString, group, ", ")
			
		
	tabString = str(tabString, "] ")
	print(tabString)
	tabString = LAYER_SEPERATOR
	
	if (layer > 0):
		for i in range(0, layer):
			if i == (layer-1):
				tabString = str(tabString, "|-> ", node.name)
				break
			
			tabString = str(tabString, LAYER_SEPERATOR) 
	else:
		tabString = str(tabString, node.name)
	print(tabString)
	
	if (node.get_child_count() > 0):
		for childNode in node.get_children():
			printNodeTree(childNode, layer + 1)
