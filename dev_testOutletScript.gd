extends Sprite

export (NodePath) var OUTLET_PATH = null setget setOutletPath
var OUTLET = null

func setOutletPath(val):
	OUTLET_PATH = val
	if (OUTLET_PATH != null):
		OUTLET = get_node(OUTLET_PATH)


#export (PackedScene) var OUTLET_SCENE = null setget setOutletScene
#var OUTLET = null
#
#export (NodePath) var OUTLET_PIN_PATH = null setget setOutletPinPath
#var OUTLET_PIN = null
#
#func setOutletScene(val):
#	OUTLET_SCENE = val
#	if (OUTLET_SCENE != null):
#		OUTLET = OUTLET_SCENE.instance()
#
#func setOutletPinPath(val):
#	OUTLET_PIN_PATH = val
#	if (OUTLET_PIN_PATH != null):
#		OUTLET_PIN = get_node(OUTLET_PIN_PATH)
#
#func _process(delta):
#	if (OUTLET != null && OUTLET_PIN != null):
#		OUTLET != 
