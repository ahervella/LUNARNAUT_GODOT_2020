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


func _ready():
	pass
	#global.controls_enabled = false
	
	#astroNode.CAMERA_NODE.setZoom(global.ZOOM.CLOSE, 0)
	
	
	add_child(BG_TWEEN)
	add_child(CF_TWEEN)
	
	BG_TWEEN.connect("tween_completed", self, "StartBGTween")
	CF_TWEEN.connect("tween_completed", self, "StartCFTween")
	
	StartCFTween(null, null)
	StartBGTween(null, null)
	
func StartCFTween(obj, key):
	CF.set_position(CF_POS)
	CF_TWEEN.interpolate_property(CF, "position", CF_POS, CF_POS + Vector2(CF_OFFSET, 0), CF_SPEED, Tween.TRANS_LINEAR)
	CF_TWEEN.start()
	
func StartBGTween(obj, key):
	#BG.set_position(BG_POS)
	BG_TWEEN.interpolate_property(BG, "position", BG_POS, BG_POS + Vector2(BG_OFFSET, 0), BG_SPEED, Tween.TRANS_LINEAR)
	BG_TWEEN.start()
