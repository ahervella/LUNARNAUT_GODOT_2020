extends Node

const SELECT_COLOR = Color(0, 0, 0, 1)#Color(0, 180, 255, 255)
const NORMAL_COLOR = Color(1, 1, 1, 1)

export (NodePath) var introPath
export (NodePath) var menuPath
export (NodePath) var missionPath
export (NodePath) var blackPath
export (NodePath) var menuContainerPath
export (NodePath) var mainMenuPath
export (NodePath) var devLevelsPath
export (Array, PackedScene) var levels
export (NodePath) var versionPath
export (int) var maxRowsPerCol
export (PackedScene) var menuOptScene

onready var intro = get_node(introPath)
onready var menu = get_node(menuPath)
onready var mission = get_node(missionPath)
onready var black = get_node(blackPath)
onready var menuContainer = get_node(menuContainerPath)
onready var mainMenu = get_node(mainMenuPath)
onready var devLevels = get_node(devLevelsPath)
onready var version = get_node(versionPath)


var currMenuNode
var currMenuOpt
var currColCount
var currRowCount
var currRowHeight

var mainMenuOPT = []
var mainMenuColCount
var mainMenuRowCount
var mainMenuRowHeight

var skipMenu = false
var pressed = false
var validPress = false

func _ready():
	mainMenuOPT.resize(mainMenu.get_child_count())
	mainMenuOPT[0] = "customLevel"
	mainMenuOPT[1] = "demoLevel"
	
	currMenuNode = mainMenu
	currMenuOpt = mainMenuOPT
	currColCount = currMenuNode.get_columns()
	currRowCount = round(currMenuNode.get_child_count()/float(currColCount))
	currRowHeight = currMenuNode.get_size().y / currRowCount

	
	devLevels.hide()
	for lvl in levels:
		var lvlOpt = menuOptScene.instance()
		lvlOpt.menuOptText = global.getSceneName(lvl.get_name())
		devLevels.add_child(lvlOpt)
	
	
	for child in get_children():
		if child == black: continue
		child.hide()
		
	intro.show()
	intro.play()
		


func _on_Intro_finished():
	menu.play()
	intro.hide()
	intro.stop()
	menu.show()
	version.show()
	menuContainer.show()
	currMenuNode.show()


func _on_MenuLOOP_finished():
		menu.set_stream_position(0) # Replace with function body.
		menu.play()


#General input
func _input(event):
	
	
	if event is InputEventMouse: return
	
	if intro.is_playing():
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
		#if mainMenu.is_visible():
		HandleMenuOPT(event)
		#elif devLevels.is_visible():
		#	HandleDevLevelsOPT(event)


func hasPos(obj, point : Vector2):
	var objPos = obj.get_global_position()
	var objSize = obj.get_size()
	if (point.x > objPos.x && point.x < objPos.x + objSize.x
	&& point.y > objPos.y && point.y < objPos.y + objSize.y):
		
		return true
		
	return false



	
func HandleMenuOPT(event):
	if !event is InputEventScreenDrag:
		pressed = event.is_pressed()
	
	
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
			if relY > (currRowHeight * i) && relY < currRowHeight * (i+1):
				selection = i
				
				changeOptionColor(i, pressed)
			else:
				changeOptionColor(i, false)
	
		if selection == null: return
	
		if !event is InputEventScreenDrag && !event.is_pressed():
			call(currMenuOpt[selection])
	
		
func changeOptionColor(optIndex, selected):
	#for node in currMenuNode.get_children():
	if selected:
		currMenuNode.get_child(optIndex).setColor(SELECT_COLOR)
		#print("selectColor")
	else:
		currMenuNode.get_child(optIndex).setColor(NORMAL_COLOR)
			

			
func customLevel():
	
	pass#mainMenuOPT.hide()
	
	
	
func demoLevel():
	mission.play()
	mission.show()
	menu.stop()
	menu.hide()
	menuContainer.hide()
	version.hide()



