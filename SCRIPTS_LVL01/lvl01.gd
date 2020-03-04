extends "res://SCRIPTS/lvl.gd"

#ALEJANDRO (Feb-14-2020)
#This is the level 1 global file, where all the game logic shoudl be stored,
#as well as any necessary variables that would be used to trigger things in level
# 1. Got most of it from the original global.gd, (need to clean up global.gd and finalize
#this transition, pretty good for most part right now though.... I think......)

#ALEJANDRO (Feb-23-2020)
#Set this to extend the new lvl.gd to keep things more organized in terms of what a lvl nodes needs and does

var has_key
var spawn_key
var spawnNora
var doorOpened

export (NodePath) var noraNodePath = null
var noraNode = null
var doorShadowTscn= preload("res://SCENES/doorShadow.tscn")


func _ready():
	
	._ready()
	
	noraNode = get_node(noraNodePath)
	
	ASTRO_GLOBAL_START_POS = Vector2(415.3, 766.25)
	ASTRO_FACE_RIGHT = false
	ASTRO_HEALTH = 3
	
	CAM_GLOBAL_START_POS  = Vector2(214.26, ASTRO_GLOBAL_START_POS.y) 
	
	initLevel()
	
	#volume set at way top
	#gradual music fade in
	global.newTween(audio.sound("music", "lvl01"), "volume_db", -50, -2, 3, 0)


	#settings for playtest
	if(global.get("playtest")):
		initAstro()
		

	
func initLevel():
	has_key = true
	spawn_key = true
	spawnNora = false
	doorOpened = false
	
	audio.loadLevelSounds("lvl01")
	
	
	if (global.playTest):
		spawnNora = false
		has_key = false
		spawn_key = true
		doorOpened = false
	

	