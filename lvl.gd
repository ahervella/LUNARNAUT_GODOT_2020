extends Node

#ALEJANDRO (Feb-23-2020)
#This is the node from which to extend level nodes, which basically makes sure each level has the basic
#requirments needed to start the level properly. 
export (bool) var playTest = false
export (NodePath) var astroNodePath = null
var astroNode
export (NodePath) var trigChunkNodePath = null
var trigChunkNode
var ASTRO_GLOBAL_START_POS : Vector2
var ASTRO_FACE_RIGHT : bool
var ASTRO_HEALTH : int

var CAM_GLOBAL_START_POS : Vector2

var levelNodes : Dictionary

func _ready():
	global.playTest = playTest
	astroNode = get_node(astroNodePath)
	trigChunkNode = get_node(trigChunkNodePath)
	global.interactNode = astroNode.INTERACT_TEXT_NODE
	
#initAstro is not called here but in the extended gd scripts
func initAstro(customSpawnPoint = null):
	
	var camNode = astroNode.CAMERA_NODE
	
	
	astroNode.set_global_position(ASTRO_GLOBAL_START_POS)
	
	if (ASTRO_FACE_RIGHT):
		astroNode.directional_force = astroNode.DIRECTION.RIGHT
	else:
		astroNode.directional_force = astroNode.DIRECTION.LEFT
	
	astroNode.Move()

	astroNode.set_health(ASTRO_HEALTH)

	camNode.set_global_position(CAM_GLOBAL_START_POS)
	
	
func gameWon():
	gameOver(true)
	
func gameLost():
	gameOver(false)
	
func gameOver(won):
	astroNode.fadeOutSound()
	astroNode.CAMERA_NODE.FadeIntoBlack(won)
	
	
func loadNextLevel():
	#all level scenes need to be named via format lvl##
	#this assumes all levels are consecutive
	var nextLevelInt = int(global.lvl().name.substr(2,4)) + 1
	global.loadLevel(nextLevelInt)
	
func reloadLevelLastSave():
	#place astro at save point spawn pint
	#initAstro(customSpawnPoint)....
	_ready()
	
	
	


	