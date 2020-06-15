extends Node

const SELECT_COLOR = Color(0, 0, 0, 1)#Color(0, 180, 255, 255)
const NORMAL_COLOR = Color(1, 1, 1, 1)

export (NodePath) var introPath
export (NodePath) var menuPath
export (NodePath) var missionPath
export (NodePath) var startPath
export (NodePath) var blackPath
export (NodePath) var menuContainerPath
export (NodePath) var mainMenuPath
export (NodePath) var devLevelsPath
export (Array, PackedScene) var levels
export (PackedScene) var demoLevel
export (NodePath) var versionPath
export(NodePath) var returnButtonPath
export (int) var maxRowsPerCol
export (PackedScene) var menuOptScene

onready var intro = get_node(introPath)
onready var menu = get_node(menuPath)
onready var mission = get_node(missionPath)
onready var start = get_node(startPath)
onready var black = get_node(blackPath)
onready var menuContainer = get_node(menuContainerPath)
onready var mainMenu = get_node(mainMenuPath)
onready var devLevels = get_node(devLevelsPath)
onready var version = get_node(versionPath)
onready var returnButton = get_node(returnButtonPath)


var currMenuNode
var currMenuOpt
var currColCount
var currRowCount
var currRowHeight
var currColWidth
var currSize

var mainMenuOPT = []
var mainMenuColCount
var mainMenuRowCount
var mainMenuRowHeight

var skipMenu = false
var pressed = false
var validPress = false
var validReturnMainPress = false

func _ready():
	mainMenuOPT.resize(mainMenu.get_child_count())
	mainMenuOPT[0] = "setCustomLevelMenu"
	mainMenuOPT[1] = "demoLevel"
	
	
	setMenu(mainMenu, mainMenuOPT)
	
	
	devLevels.hide()
	for lvl in levels:
		var lvlInst = lvl.instance()
		var lvlOpt = menuOptScene.instance()
		lvlOpt.menuOptText = global.getSceneName(lvlInst.filename)
		print(global.getSceneName(lvlInst.filename))
		devLevels.add_child(lvlOpt)
	
	devLevels.set_columns(ceil(levels.size() / float(maxRowsPerCol)))
	
	
	for child in get_children():
		child.hide()
		
	intro.show()
	intro.play()
		


func _on_Intro_finished():
	menu.play()
	intro.hide()
	intro.stop()
	menu.show()
	version.show()
	returnButton.hide()
	devLevels.hide()
	menuContainer.show()
	currMenuNode.show()


func _on_MenuLOOP_finished():
		menu.set_stream_position(0) # Replace with function body.
		menu.play()


#General input
func _input(event):
	
	
	if event is InputEventMouse: return
	
	if intro.is_playing() && !menu.is_playing():
		skipMenu = true
		_on_Intro_finished()
		return
	
	if skipMenu:
		if !event.is_pressed() && (!event is InputEventScreenDrag):
			skipMenu = false
		
		return
	
	# NOTE is_pressed registers as false if event is InputEventScreenDrag
	# which is why this logic is a bit fuzy
		
	if ( (event is InputEventScreenTouch || event is InputEventScreenDrag)):
		
		if !event is InputEventScreenDrag:
			pressed = event.is_pressed()
		
		HandleMenuOPT(event)
		
		HandleReturnToMain(event)


func hasPos(obj, point : Vector2):
	var objPos = obj.get_global_position()
	var objSize = obj.get_size()
	if (point.x > objPos.x && point.x < objPos.x + objSize.x
	&& point.y > objPos.y && point.y < objPos.y + objSize.y):
		
		return true
		
	return false



	
func HandleMenuOPT(event):

	#if currently pressed of released touch moves out of area,
	#make all off and return
	if !hasPos(currMenuNode, event.position):
		for i in currMenuNode.get_child_count():
			changeOptionColor(i, false)
			
		
		if event.is_pressed():
			validPress = false
		return
	
	if !event is InputEventScreenDrag && event.is_pressed():
		validPress = true
	
	
	
	if validPress:
		var relY = event.position.y - currMenuNode.get_global_position().y
		var relX = event.position.x - currMenuNode.get_global_position().x
		var selection = null
		
		
		for i in currMenuNode.get_child_count():
			if (relX > (currColWidth * (i % currColCount)) && relX < (currColWidth * ((i % currColCount) + 1))
			&& relY > (currRowHeight * floor(i/float(currColCount))) && relY < currRowHeight * (floor(i/float(currColCount))+1)):
				selection = i
				
				changeOptionColor(i, pressed)
			else:
				changeOptionColor(i, false)
	
		if selection == null: return
	
		if !event is InputEventScreenDrag && !event.is_pressed():
			if currMenuOpt != null:
				call(currMenuOpt[selection])
			else:
				var scene = levels[selection].instance()
				global.goto_scene(scene.filename)
	
func HandleReturnToMain(event):
	
	if !hasPos(returnButton, event.position):
		returnButton.set("custom_colors/font_color", NORMAL_COLOR)
			
		
		if event.is_pressed():
			validReturnMainPress = false
		return
	
	if !event is InputEventScreenDrag && event.is_pressed():
		validReturnMainPress = true
	
	if validReturnMainPress:
		if pressed:
			returnButton.set("custom_colors/font_color", SELECT_COLOR)
		else:
			returnButton.set("custom_colors/font_color", NORMAL_COLOR)
		
		if !event is InputEventScreenDrag && !event.is_pressed():
			setMainMenu()
			
	
	
func changeOptionColor(optIndex, selected):
	#for node in currMenuNode.get_children():
	if selected:
		currMenuNode.get_child(optIndex).setColor(SELECT_COLOR)
	else:
		currMenuNode.get_child(optIndex).setColor(NORMAL_COLOR)
			

			
func setCustomLevelMenu():
	version.hide()
	returnButton.show()
	mainMenu.hide()
	devLevels.show()
	
	call_deferred("setMenu", devLevels, null)
	
func setMainMenu():
	version.show()
	returnButton.hide()
	devLevels.hide()
	mainMenu.show()
	
	call_deferred("setMenu", mainMenu, mainMenuOPT)
	
func setMenu(m, mOPT = null):
	currMenuNode = m
	currMenuOpt = mOPT
	currColCount = currMenuNode.get_columns()
	currRowCount = round(currMenuNode.get_child_count()/float(currColCount))
	currRowHeight = currMenuNode.get_size().y / currRowCount
	currColWidth = currMenuNode.get_size().x / currColCount
	currSize = currMenuNode.get_size()
	
	
func demoLevel():
	mission.play()
	mission.show()
	menu.stop()
	menu.hide()
	menuContainer.hide()
	version.hide()
	
	global.newTimer(31, funcref(self, "missionTween"))

func missionTween():
	black.set_modulate(Color(1, 1, 1, 0))
	black.show()
	global.newTween(black, "modulate", 
		Color(1, 1, 1, 0), 
		Color(1, 1, 1, 1), 
		5, 0, funcref(self, "missionStart"))

func missionStart():
	for child in get_children():
		child.hide()
	mission.stop()
	start.show()
	global.newTimer(1, funcref(self, "missionStartExt"))
func missionStartExt():
	start.play()


func _on_Start_finished():
	var demo = demoLevel.instance()
	global.goto_scene(demo.filename)
