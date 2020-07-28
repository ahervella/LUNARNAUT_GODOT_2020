extends "res://SCRIPTS/lvl.gd"

export (NodePath) var BG_PATH
export (float) var BG_OFFSET = 1000
export (float) var BG_SPEED = 1
onready var BG = get_node(BG_PATH)
onready var BG_POS = BG.get_position()
onready var BG_TWEEN = Tween.new()

export (NodePath) var CF_PATH
export (float) var CF_OFFSET = 1000
export (float) var CF_SPEED = 1
onready var CF = get_node(CF_PATH)
onready var CF_POS = CF.get_position()
onready var CF_TWEEN = Tween.new()
export (NodePath) var spawnNodePath
onready var spawnNode = get_node(spawnNodePath)
export (NodePath) var shuttleNodePath
onready var shuttleNode = get_node(shuttleNodePath)
export (float) var transitionTime = 10.0
#cool this works if I ever need this anywhere else! Guess I'll leave it here....lol
#export(int, LAYERS_2D_PHYSICS) var layers_2d_physics
export (bool) var shuttleFaceRight = false
export (PackedScene) var customNextScene

onready var timer = Timer.new()


func _ready():
	pass
	
	global.controls_enabled = false
	
	if global.dev_transitionShuttle_faceRight != null:
		shuttleFaceRight = global.dev_transitionShuttle_faceRight
	
	if shuttleFaceRight:
		spawnNode.flip = false
		CF_OFFSET = -CF_OFFSET
		BG_OFFSET = -BG_OFFSET
		BG_POS.x = -BG_POS.x
		
		
		shuttleNode.set_global_scale(shuttleNode.get_global_scale() * Vector2(-1, 1))

	
	add_child(BG_TWEEN)
	add_child(CF_TWEEN)
	add_child(timer)
	
	BG_TWEEN.connect("tween_completed", self, "StartBGTween")
	CF_TWEEN.connect("tween_completed", self, "StartCFTween")
	#timer.connect("timeout", global, "replay")
	
	var fadeTimerTime = max(5, transitionTime)
	
	
	global.newTimer(fadeTimerTime, funcref(self, "gotoCustomNextScene"))
	
	global.newTimer(fadeTimerTime - 5, funcref(astroNode.CAMERA_NODE, "FadeIntoBlack"))
	
	StartCFTween(null, null)
	StartBGTween(null, null)
	
	
func gotoCustomNextScene():
	if global.dev_transitionShuttle_transScenePath != null:
		global.goto_scene(global.dev_transitionShuttle_transScenePath)
		return
	
	if customNextScene == null:
		global.replay()
		return
		
	global.goto_scene(customNextScene.get_path())
		
	
func StartCFTween(obj, key):
	CF.set_position(CF_POS)
	CF_TWEEN.interpolate_property(CF, "position", CF_POS, CF_POS + Vector2(CF_OFFSET, 0), CF_SPEED, Tween.TRANS_LINEAR)
	CF_TWEEN.start()
	
func StartBGTween(obj, key):
	#BG.set_position(BG_POS)
	BG_TWEEN.interpolate_property(BG, "position", BG_POS, BG_POS + Vector2(BG_OFFSET, 0), BG_SPEED, Tween.TRANS_LINEAR)
	BG_TWEEN.start()
