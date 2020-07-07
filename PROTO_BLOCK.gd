tool
extends Sprite
const DUP_NAME = "duplicateShadow"
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
