extends "res://SCRIPTS/lvl.gd"

#ALEJANDRO (Feb-14-2020)
#This is the level 1 global file, where all the game logic shoudl be stored,
#as well as any necessary variables that would be used to trigger things in level
# 1. Got most of it from the original global.gd, (need to clean up global.gd and finalize
#this transition, pretty good for most part right now though.... I think......)

#ALEJANDRO (Feb-23-2020)
#Set this to extend the new lvl.gd to keep things more organized in terms of what a lvl nodes needs and does
var spawnNora
var doorOpened



export (NodePath) var noraNodePath = null
var noraNode = null
var doorShadowTscn= preload("res://SCENES/doorShadow.tscn")

export (bool) var demoVersionOfLevel1 = false

func _ready():
	
	#prevent from running in editor
	if Engine.editor_hint:
		return
	
	._ready()
	
	
#	call_deferred("readyExt")
	
#func readyExt():
	
	noraNode = get_node(noraNodePath)
	
	ASTRO_GLOBAL_START_POS = Vector2(415.3, 766.25)
	ASTRO_FACE_RIGHT = false
	ASTRO_HEALTH = 3
	
	CAM_GLOBAL_START_POS  = Vector2(214.26, ASTRO_GLOBAL_START_POS.y) 
	
	
	initLevel()
	
	
	#volume set at way top
	#gradual music fade in
	audio.sound("music", "lvl01").play(0)
	global.newTween(audio.sound("music", "lvl01"), "volume_db", -50, -2, 3, 0)
	

	astroNode.set_health(ASTRO_HEALTH)

	#settings for playtest
	if(global.playTest):
		initAstro()
		

	
func initLevel():
	.initLevel()
	
#	call_deferred("initLevelExt")
	
#func initLevelExt():
	spawnNora = false
	doorOpened = false
	
	audio.loadLevelSounds("lvl01")
	
	#astroNode.CAMERA_NODE.FadeOutOfBlack()
	if (global.playTest):
		spawnNora = false
		doorOpened = false
		
		#astroNode.CAMERA_NODE.FadeOutOfBlack()
	

func loadNextLevel():
	#all level scenes need to be named via format lvl##
	#this assumes all levels are consecutive
	if (demoVersionOfLevel1):
		var demoVidNode = get_node("DemoOutro")
		demoVidNode.show()
		#demoVidNode.set_global_position(Vector2(0, 0))
		demoVidNode.get_node("DemoOutroCam").make_current()
		demoVidNode.play()
		return
	
	.loadNextLevel()


func _on_DemoOutro_finished():
	global.replay()
