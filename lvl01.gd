extends Node

#ALEJANDRO (Feb-14-2020)
#This is the level 1 global file, where all the game logic shoudl be stored,
#as well as any necessary variables that would be used to trigger things in level
# 1. Got most of it from the original global.gd, (need to clean up global.gd and finalize
#this transition, pretty good for most part right now though.... I think......)

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

	