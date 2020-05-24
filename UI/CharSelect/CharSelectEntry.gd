extends Node

export (Resource) var Character

export (NodePath) var textName
export (NodePath) var textNationality
export (NodePath) var textDescription
export (NodePath) var texture


func initialize(character):
	Character = character
	get_node(textName).text = "Name: %s" % Character.name
	get_node(textNationality).text = "Nationality: %s" % Character.nationality
	get_node(textDescription).text = "Description: %s" % Character.description
	get_node(texture).texture = Character.texture


func _on_Button_button_up():
	
	saveCurrentLvl()
	
	loadNewCharacterLevel()

	


func loadNewCharacterLevel():
	global.CharacterRes = Character
	var newLvlPath = global.getScenePath(Character.level)
	print(newLvlPath)
	print("print(newLvlPath)")
	if global.levelWrapperDict.has(newLvlPath):
		if global.levelWrapperDict[newLvlPath].charSavedLvlSceneDict.has(Character.id):
			global.goto_scene(global.levelWrapperDict[newLvlPath].charSavedLvlSceneDict[Character.id])
			
			
			return
	
	
	global.goto_scene(newLvlPath)



func saveCurrentLvl():
	if global.CharacterRes != null:
		
		
		
		for CSWrap in global.lvl().charSwitchWrappers:
			if CSWrap.staticNode: continue
			global.lvl().get_node(CSWrap.node).CSWrapAddChanges(CSWrap)
			
			
		
		
		var currLvlPath = global.getScenePath(global.CharacterRes.level)
	
		savedCurrentLvlPackedScene(currLvlPath)
		
		
		reorderAndSaveCurrentLvlWrappers(currLvlPath)
			
		

func savedCurrentLvlPackedScene(currLvlPath):
	var currChar = global.CharacterRes.id
	
	if !global.levelWrapperDict.has(currLvlPath):
		global.levelWrapperDict[currLvlPath] = LevelWrapper.new()
			
	if !global.levelWrapperDict[currLvlPath].charSavedLvlSceneDict.has(currChar):
		global.levelWrapperDict[currLvlPath].charSavedLvlSceneDict[currChar] = PackedScene.new()
	global.levelWrapperDict[currLvlPath].charSavedLvlSceneDict[currChar].pack(global.lvl())
	#ResourceSaver.save("res://name.tscn", global.levelWrapperDict[currLvlPath].charSavedLvlSceneDict[currChar])
#	if !global.levelWrapperDict[currLvlPath].gravity.has(currChar):
#		global.levelWrapperDict[currLvlPath].gravity[currChar] = []
#		global.levelWrapperDict[currLvlPath].gravity[currChar].resize(2)
		
	global.levelWrapperDict[currLvlPath].gravity[currChar] = [global.gravMag, rad2deg(global.gravRadAngFromNorm)]




func reorderAndSaveCurrentLvlWrappers(currLvlPath):
	var currChar = global.CharacterRes.id
	var dependantOrderedCSWrappers = []
	
	for wrap in global.lvl().charSwitchWrappers:
		dependantOrderedCSWrappers.append(wrap)
	
	for wrap in global.lvl().charSwitchWrappers:
		
		for dependantWrap in wrap.dependantCSWrappers[currChar]:
			
			#for all dependant wrappers, place them after the parent node
			dependantOrderedCSWrappers.erase(dependantWrap)
			var wrapIndex = dependantOrderedCSWrappers.find(wrap)
			if wrapIndex > dependantOrderedCSWrappers.size():
				dependantOrderedCSWrappers.resize(dependantOrderedCSWrappers.size()+1)
				
			dependantOrderedCSWrappers.insert(wrapIndex+1, dependantWrap)
			
			
	global.levelWrapperDict[currLvlPath].lvlNodesCSWrapDict[currChar] = dependantOrderedCSWrappers
