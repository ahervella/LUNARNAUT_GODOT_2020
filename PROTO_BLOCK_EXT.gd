tool
extends "res://SCRIPTS/PROTO_BLOCK_BASE.gd"#extends Sprite




const DUP_NAME = "duplicateShadow"

export (global.MAT) var blockMaterial = global.MAT.CONCRETE
var hazardObjectAreaDict = {}
#var hazardAreaIDs = []
onready var blockShape = get_node("KinematicBody2D/CollisionShape2D")

export (bool) var isRoomWallFloor = true setget setLightMask
var lo


func _ready():
	if Engine.editor_hint: return
	
	setSetLightMask(isRoomWallFloor)

	#_ready() is a built in method so parent ready is already called


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

func getHazardID():
	return get_name()

func getCurrHazObj():
	if hazardObjectAreaDict.size() == 0: return null
	return hazardObjectAreaDict.keys()[0]
		
func getCurrHazArea():
	if hazardObjectAreaDict.size() == 0: return null
	return hazardObjectAreaDict[getCurrHazObj()][0]

func hazardEnabled(enabled, hazType, hazAreaID, hazObj, killAstro):
	
	if hazAreaID == getHazardID(): return
	
	if !enabled:
		if hazardObjectAreaDict.has(hazObj) && hazardObjectAreaDict[hazObj].has(hazAreaID):
			#var postAddToDiffHaz = false
			#if hazardAreaIDs[0] == hazAreaID && hazardObjects.size() > 1:
			#	postAddToDiffHaz = true
			#if hazardObjects.has(hazObj):
			hazardObjectAreaDict[hazObj].erase(hazAreaID)
			if hazardObjectAreaDict[hazObj].size() == 0:
				#var currHazObj = hazardObjectAreaDict.keys()[0]
				var assignNewHazObj = getCurrHazObj() == hazObj
				hazardObjectAreaDict.erase(hazObj)
				hazObj.removeHazardShape(hazAreaID)
				
				if hazardObjectAreaDict.size() > 0 && assignNewHazObj:
					getCurrHazObj().addHazardShape(getHazardID(), blockShape, self, getCurrHazArea())
			#if postAddToDiffHaz:
				
			
		return
		
	if (global.hazardDict[blockMaterial] != hazType): return
	
	if hazObj.isAreaInSourceRoute(getHazardID(), hazAreaID): return
	
	if !hazardObjectAreaDict.has(hazObj):
		hazardObjectAreaDict[hazObj] = []
	
	if hazardObjectAreaDict[hazObj].has(hazAreaID): return
	hazardObjectAreaDict[hazObj].append(hazAreaID)
	
	if hazardObjectAreaDict.size() == 1:
		hazObj.addHazardShape(getHazardID(), blockShape, self, hazAreaID)

	
	
	
	
