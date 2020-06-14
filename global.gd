extends Node

#ALEJANDRO (Feb-14-2020)
#this is the global script that should be used across all levels.
#I think its still in development of transitiong all of its original
#functionality to the lvl1 script and leaving here only the actual
#global functionalities across all the levels.

#ALEJANDRO (Feb-23-2020)
#changed the queue_free to deferred with free due to a
#a smart guy on reddit saying to do so... hahaha
#https://www.reddit.com/r/godot/comments/8hp3ok/use_call_deferredfree_instead_of_queue_free/

#ALEJANDRO (Mar-01-2020)
#finally got rid of newTweenNoConnection and newTweenOld and made them work just with newTween
#can always check in the future like I was now if shit is working properly by printing the child count
#and child array of global

	#PROJECT SETTINGS (As of May-12-2020):
	#Physics Engine = GodotPhysics
	#Thread Model = Single-Safe
	#Sleep Threshold Linear = 2
	#Sleep Threshold Angular = 0.14
	#Time Before Sleep = 0.5
	#Bp Hashtable Size = 4096
	#Cell Size = 128
	#Default Gravity = 98
	#Defualt Gravity Vector = Vector2(0, 1)
	#Default Linear Damp = 0
	#Default Angular Damp = 1

enum CHAR {USA, RUS, FRA, CHN, MAR}

var availableChar = [CHAR.RUS, CHAR.USA, CHAR.FRA]
var astroCharDict = {CHAR.USA : "res://RESOURCES/CHARACTERS/CHAR_USA.tres",
					CHAR.RUS : "res://RESOURCES/CHARACTERS/CHAR_RUS.tres", 
					CHAR.FRA : "res://RESOURCES/CHARACTERS/CHAR_FRA.tres"}
var charYearDict = {CHAR.USA : 1984, CHAR.RUS : 1973, CHAR.FRA : 1996, CHAR.CHN : 2021, CHAR.MAR : 2073}

var tempCharSwitchWrapperList = null

var levelWrapperDict = {}

var changingScene = false

#var currChar = astroCharDict[CHAR.USA]
var interactNode #$"/root/Control/astro/InteractFont"
var interactNodes = []
const DEF_MAX_INTERACT = 2
var maxInteractNodes = DEF_MAX_INTERACT
#var infoInteractNodeIndex = 0
var infoInteractNode 

export (Resource) var CharacterRes = null

var current_interact
var controls_enabled
var can_reset
var playTest
var astroDead
var gravTermVel
var gravFor1Frame
var gravMag
var gravRadAng
var gravRadAngFromNorm
var gravMaxDegAngAllowedMove

func getNextInteractNodeIndex():
	print("global.getNextInteractNodeIndex")
	var currIndex = 0
	var overrideFlip = null
	
	destroyInteractNode(infoInteractNode)
	
	while(interactNodes[currIndex] != null):
		overrideFlip = interactNodes[currIndex].flip
		currIndex += 1
		if currIndex == maxInteractNodes:
			return null
			
	var infoInteractNodeIndex = currIndex + 1
	while(interactNodes[infoInteractNodeIndex] != null):
		infoInteractNodeIndex += 1
		if infoInteractNodeIndex == maxInteractNodes:
			break
		
		
	
	var newInteractNode = addNewInteractNode(currIndex, overrideFlip)
	#print("infoInteractNodeIndex")
	#print(infoInteractNodeIndex)
	infoInteractNode = addNewInteractNode(infoInteractNodeIndex, overrideFlip)
	
	return newInteractNode
	
func addNewInteractNode(index, overrideFlip):
	#if interactNodes.size() < index+1: interactNodes.resize(index+1)
	if interactNodes.size() > index && interactNodes[index] == null:
		var newInteractNode = interactNode.duplicate(DUPLICATE_USE_INSTANCING)
		newInteractNode.overrideFlip = overrideFlip
		newInteractNode.ASTRO_NODE = interactNode.ASTRO_NODE
		interactNode.get_parent().add_child_below_node(interactNode, newInteractNode)
		newInteractNode.set_global_position(interactNode.get_global_position())
	
		interactNodes[index] = newInteractNode
		setInterNodeVerticalOffset(index)
		return newInteractNode
	return null
	
func setInterNodeVerticalOffset(interNodeIndex):
	var interNode = interactNodes[interNodeIndex]
	if interNode == null: return
	if interNodeIndex > 0:
			if interactNodes[interNodeIndex-1] != null:
				var prevInterNode = interactNodes[interNodeIndex-1] 
				#print("interNodeIndex")
				#print(interNodeIndex)
				
				if prevInterNode.text != null && prevInterNode.text != "":
					var actualPrevTextVect = (getRealTextVector2(prevInterNode.text, prevInterNode.get_size().x, prevInterNode.get("custom_fonts/normal_font")))
				#	print(actualPrevTextVect)
					interNode.multiInterNodeOffset = actualPrevTextVect.y + prevInterNode.multiInterNodeOffset
		
func getRealTextVector2(string, width, font):
	
	var cursor = 0
	var words = []
	for i in string.length():
		if string.substr(i, 1) == " ":
			words.append(string.substr(cursor, i-cursor))
			cursor = i+1
		elif(i == string.length() -1):
			words.append(string.substr(cursor))
			
	var lines = []
	var currLine = ""
	
	for word in words:
		if font.get_string_size(currLine + word).x < width || currLine == "":
			currLine += word + " "
		else:
			lines.append(currLine)
			currLine = word# + " "
			while font.get_string_size(currLine).x > width:
				var ogCurrLine = currLine
				while(font.get_string_size(currLine).x > width):
					currLine = currLine.substr(0,currLine.length()-1)
				ogCurrLine = ogCurrLine.substr(currLine.length(), ogCurrLine.length() - currLine.length())
				lines.append(currLine)
				currLine = ogCurrLine
				
	lines.append(currLine)
	
	#plus one because of line spacing I believe
	return Vector2(width, (font.get_string_size(string).y+1) * lines.size())

func enableMultiInteractNodes(enable):
	
	var oldWasDisabled = maxInteractNodes == 1
	
	if enable:
		for item in lvl().astroNode.currItems:
			if !item.useNextInterNodeIfNeeded:
				return
		
		maxInteractNodes = DEF_MAX_INTERACT
		
		
	else:
		for interNode in interactNodes:
			#if i == 0: continue
			if interNode != null && is_instance_valid(interNode):
				destroyInteractNode(interNode)
				
		maxInteractNodes = 1
		
	interactNodes.resize(maxInteractNodes + 1)
	
	if enable && oldWasDisabled:
		for item in lvl().astroNode.currItems:
			item.AutoInteract()

func destroyInteractNode(interNode):
	
	print("global.destroyInteractNode")
#	if !is_instance_valid(interNode):
#		return
	
	for i in interactNodes.size():
		if interactNodes[i] != null && interactNodes[i] == interNode:
			#remove interactNode references from items in astro
			for item in lvl().astroNode.currItems:
				if item == interNode:
					item.interactNode = null
					
			interactNodes[i] = null
			#interactNode.remove_child(interNode)
			if interNode.timer != null  && interNode.timerUniqueID == interNode.timer.to_string():
				interNode.timer.free()
			#interNode.free()
			interNode.call_deferred('free')
			return


func astroChar2String(astroChar):
	match astroChar:
		global.CHAR.USA:
			return "USA"
		global.CHAR.RUS:
			return "RUS"
		global.CHAR.FRA:
			return "FRA"
		global.CHAR.CHN:
			return "CHN"
		global.CHAR.MAR:
			return "MAR"
	return ""

func getAstroCharOrderIndex(astroChar):
	var year = charYearDict[astroChar]
	var order = 0
	for value in charYearDict.values():
		if value == year: continue
		if value < year: order += 1
		
	return order


func getSceneName(path):
	
	path = path.substr(path.find_last("/")+1)
	return path.substr(0, path.find_last("."))


func initCharSwitch(astroChar):
	global.changingScene = true
	saveCurrentLvl()
	
	loadNewCharacterLevel(astroChar)



func saveCurrentLvl():
	if global.CharacterRes != null:
		
		
		
		for CSWrap in global.lvl().charSwitchWrappers.values():
			if CSWrap.staticNode: continue
			if CSWrap.checkIfInCharLvl(global.CharacterRes.id):
				global.lvl().get_node(CSWrap.nodePath).CSWrapAddChanges(CSWrap)
			
			
		
		
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
	var timeDiscrepArray = [global.lvl().timeDiscrepCSWCharDict.duplicate(true), 
		global.lvl().timeDiscrepBodyPresentDict2.duplicate(true), 
		global.lvl().timeDiscrepManuallyRemovingArea.duplicate(true)]
	global.levelWrapperDict[currLvlPath].lvlTimeDiscrepAreaDict[currChar] = [timeDiscrepArray, PackedScene.new()]
	global.levelWrapperDict[currLvlPath].lvlTimeDiscrepAreaDict[currChar][1].pack(global.lvl().timeDiscrepParentNode)




func reorderAndSaveCurrentLvlWrappers(currLvlPath):
	var currChar = global.CharacterRes.id
	var charSwitchWrappersDUP = global.lvl().charSwitchWrappers.duplicate(true)
	
	
#	for wrap in global.lvl().charSwitchWrappers.values():
#		dependantOrderedCSWrappers.append(wrap)
#
#	for wrap in global.lvl().charSwitchWrappers.values():
#
#		for dependantWrap in wrap.dependantCSWrappers[currChar]:
#
#			#for all dependant wrappers, place them after the parent node
#			dependantOrderedCSWrappers.erase(dependantWrap)
#			var wrapIndex = dependantOrderedCSWrappers.find(wrap)
#			if wrapIndex > dependantOrderedCSWrappers.size():
#				dependantOrderedCSWrappers.resize(dependantOrderedCSWrappers.size()+1)
#
#			dependantOrderedCSWrappers.insert(wrapIndex+1, dependantWrap)
			
			
	global.levelWrapperDict[currLvlPath].lvlNodesCSWrapDict[currChar] = charSwitchWrappersDUP



func loadNewCharacterLevel(astroChar):
	if !astroCharDict.has(astroChar) : return
	CharacterRes = load(astroCharDict[astroChar])
	var newLvlPath = getScenePath(CharacterRes.level)
	print(newLvlPath)
	print("print(newLvlPath)")
	#if global.levelWrapperDict.has(newLvlPath):
	#	if global.levelWrapperDict[newLvlPath].charSavedLvlSceneDict.has(Character.id):
	#		global.goto_scene(global.levelWrapperDict[newLvlPath].charSavedLvlSceneDict[Character.id])
			
			
			#return
	
	
	global.goto_scene(newLvlPath)



func getScenePath(sceneName):
	return "res://SCENES/%s.tscn" % sceneName
	
func getScriptPath(scriptFileName) -> String:
	return "res://SCRIPTS/" + scriptFileName
#
func _ready():
	init()
	
func init():
	current_interact = null
	controls_enabled = true
	can_reset = false
	astroDead = false
	
	gravTermVel = 200
	#assuming phsyics is running at 60 fps
	gravFor1Frame = 60 * 3
	gravMag = 1
	#remember y is flipped
	gravRadAng = deg2rad(90)
	gravRadAngFromNorm = deg2rad(0)
	gravMaxDegAngAllowedMove = 30
	
	playTest = true
	#+ 1 for result / report node
	interactNodes.resize(maxInteractNodes + 1)
	


func replay():
	init()
	goto_scene("res://SCENES/MainMenu.tscn")

func loadLevel(lvlNum):
	goto_scene(str("res://SCENES/lvl", "%0*d" % [2, lvlNum], ".tscn"))

	
func goto_scene(path):
	changingScene = true
	#call_deferred("goto_sceneEXT", path)
	
#func goto_sceneEXT(path):
	for child in lvl().get_children():
		child.set_physics_process(false)
		
	DestroyAllChildren()
	
	print(path)
	if path is PackedScene:
		get_tree().change_scene_to(path)
		changingScene = false
		return
	
	get_tree().change_scene(path)
	changingScene = false
	
	
#used to get the specific level variables, funcs, and attributes
#will return null if the current scene is not the level given 
func lvl(lvlNum : int = -1):
	var scene = get_tree().get_current_scene()
	#return current lvl (because lvl usually has default vars like astro node
	if (lvlNum == -1):
		return scene
	
	#level scene names must be in "lvl##" format	
	if (int(scene.name.substr(2,4)) == lvlNum):
		return scene
	
	return null
	
	
#VVVVVVV - TWEEN AND TIMER FUNCS - VVVVVVVVVVV#
	
func newTween(object, tweeningMethod, startVars, endVars, time, delay, func_ref = null, transType = Tween.TRANS_LINEAR, tweenType = Tween.EASE_OUT):
	
	var tween = Tween.new()
	#always need to add child to something for it to work
	add_child(tween)

	#connect tween once its done to self destruct (to avoid mem leaks) and call any related funcs if any
	tween.connect("tween_completed", self, "DestroyTween", [tween, func_ref])

	tween.interpolate_property(object, tweeningMethod, startVars, endVars, time, transType, tweenType, delay)
	
	tween.start()
	
	#in case we want to do shit with it
	return tween
	
#here by default func_ref is null if nothing is passed (in case called outside here)
func DestroyTween(object, key, tweenObj, func_ref = null):
	#if any other functions to be called were passed, do that
	
	#print("destroyTweenFuncRef")
	#print(func_ref)
	if (func_ref != null):
		func_ref.call_func()
		#print("destroyTweenFuncRef was called")
	#ensures that next frame free will be called on this tween instance
	tweenObj.call_deferred('free')

	
	

func newTimer(time, ref = null):
	var timer = Timer.new()
	add_child(timer)
	timer.set_one_shot(true)
	timer.set_wait_time(time)
	timer.connect("timeout", self, 'DestroyTimer', [timer, ref])
	timer.start()
	return timer
	

func DestroyTimer(timer, ref):
	#before was using yield which seemed to cause some memory issues,
	#so went back to old way and just used the refs that were being passed
	#that had already been setup
	
	timer.call_deferred('free')
	
	#refered method
	if (ref != null):
		if ref.is_valid():
			ref.call_func()
		
#to clean up shit before switching scenes to not cause scene / node ref errors
func DestroyAllChildren():
	
	for interNode in interactNodes:
		destroyInteractNode(interNode)
		
	interactNode = null
	
	for i in range(0, get_child_count()):
		#print("childcount")
		#print(get_child_count())
		get_child(i).call_deferred('free')


#these are functions that any interact node must have (acts as an interface enforcer)
#ALSO, the interact node MUST have "interact" in node area group to work
func InteractInterfaceCheck(var interactObj):
	if (!interactObj.has_method('Interact')):
		push_error("Interact item missing 'Interact'")
		
	if (!interactObj.has_method('AutoInteract')):
		push_error("Interact item missing 'AutoInteract'")
		
	if (!interactObj.has_method('AutoCloseInteract')):
		push_error("Interact item missing 'AutoCloseInteract'")
		
		
#this is what is used to change overall gravity
func changeGrav(mag = 1, degFromNorm = 0, time = 2):
	if time == 0:
		gravMag = mag
		gravRadAng = deg2rad(degFromNorm + 90)
		gravRadAngFromNorm = deg2rad(degFromNorm)
		return
	
	newTween(self, "gravMag", gravMag, mag, time, 0)
	newTween(self, "gravRadAng", gravRadAng, deg2rad(degFromNorm + 90), time, 0)
	newTween(self, "gravRadAngFromNorm", gravRadAngFromNorm, deg2rad(degFromNorm), time, 0)

#returns the gravity vector
func gravVect():
	return Vector2(cos(gravRadAng), sin(gravRadAng))
