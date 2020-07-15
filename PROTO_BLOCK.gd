tool
extends Sprite
const DUP_NAME = "duplicateShadow"

export (global.MAT) var blockMaterial = global.MAT.CONCRETE
var hazardObject = null
var hazardAreaID = null
onready var blockShape = get_node("StaticBody2D/CollisionShape2D")

export (bool) var isRoomWallFloor = true setget setLightMask
var lo
#func _init():

func _ready():
	if Engine.editor_hint: return
	
	setSetLightMask(isRoomWallFloor)

func setLightMask(isWallFloor):
	
	isRoomWallFloor = isWallFloor

	if Engine.editor_hint:
		setSetLightMask(isWallFloor)

func setSetLightMask(isWallFloor):
	for child in get_children():
		if child is LightOccluder2D:
			lo = child
			break
			
	if lo == null: return
	print("oaijdfoaisdjf")
	print(isWallFloor)
	var lightMask = 30 if isWallFloor else 6
	
	
	lo.set_occluder_light_mask(lightMask)
	lo.property_list_changed_notify()
	property_list_changed_notify()

func hazardEnabled(enabled, hazType, hazAreaID, hazObj):
	if !enabled:
		if hazAreaID == hazardAreaID:
			hazObj.removeHazardShape(get_name())
			hazardObject == null
			set_process(false)
		return
		
	if (global.hazardDict[blockMaterial] != hazType): return
	
	if hazardObject != null: return
	
	hazardObject = hazObj
	hazardAreaID = hazAreaID
	
	hazObj.addHazardShape(get_name(), blockShape, hazAreaID)
	
	set_process(true)

func _process(delta):
	if hazardObject == null: return
	
	hazardObject.updateHazardShape(get_name(), get_global_transform())
	
	
	
	
	
	
	
