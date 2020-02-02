extends Node

var has_key
var spawn_key
var spawnNora
var doorOpened
var playTest = true;

enum LVL1{LeftDoor, RightDoor}

var levelNodes : Dictionary = {LVL1.LeftDoor:"/root/Control/door_left", LVL1.RightDoor:"/root/Control/right_door"}

func _ready():
	init()
	
func init():
	has_key = false
	spawn_key = true
	spawnNora = false
	doorOpened = false
	
	
	if (playTest):
		spawnNora = false
		has_key = false
		spawn_key = true
		doorOpened = false
	
func LevelLogic(nodePath):
	if (nodePath == levelNodes[LVL1.LeftDoor]):
		levelNodes[LVL1.LeftDoor].canOpen = true
		levelNodes[LVL1.LeftDoor].autoOpen = true
		doorOpened = true

	