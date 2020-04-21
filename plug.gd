tool
extends Node2D


enum PLUG_TYPE {
	AUX,
	PWR,
	VGA, 
	NET
}

enum PLUG_REGION {
	USA,
	RUS,
	GER,
	UNI
}

enum CONN_RESULT {
	INCOMPATIBLE
	WRONG_TYPE
	SELF_ALREADY_CONN
	OTHER_ALREADY_CONN
	OTHER_NOT_PLUG
	SUCCESS
	NO_PLUG_FOUND
}


export (bool) var male = false
export (bool) var canGrab = true
export (PLUG_REGION) var plugRegion = PLUG_TYPE.AUX
export (PLUG_TYPE) var plugType = PLUG_REGION.USA
#connPlug is set by cable when its cable end collision area runs into another
#cable or port collision area
var connPlug = null setget setConnection

var sourcePlug = null setget setSource


export (NodePath) var connAreaPath = null setget setConnAreaPath
var connArea = null

export (NodePath) var plugSpritePath = null setget setPlugSpritePath
var plugSprite = null

func setPlugSpritePath(val):
	plugSpritePath = val
	if (plugSpritePath != null):
		plugSprite = get_node(plugSpritePath)

func setConnAreaPath(val):
	connAreaPath = val
	if (connAreaPath != null):
		connArea = get_node(connAreaPath)


func setSource(plugPath):
	if plugPath.has_method("transmitEntity"):
		sourcePlug = plugPath

func setConnection(plugPath):
	connPlug = null
	
	#if is not of type plug && its not a port && this is male, return && not null && not astro
	if (plugPath.has_method("recievedEntity")):
		if (plugPath.male != male
		&& (plugPath.plugRegion == plugPath || plugPath.plugRegion == PLUG_REGION.UNI)
		&& (plugPath.plugType == plugType)):
			connPlug = plugPath
			return
	#	return
	
func _ready():
	setPlugSpritePath(plugSpritePath)
	setConnAreaPath(connAreaPath)

func setSpriteFlip(hflip):
	if (plugSprite != null):
		plugSprite.set_flip_h(hflip)
	
func attemptConnection():
	if connPlug != null:
		return CONN_RESULT.SELF_ALREADY_CONN
	for area in connArea.get_overlapping_areas():
		if area.get_groups().has("plug"):
			var otherPlug = area.get_parent()
			
			if otherPlug != null:
				return CONN_RESULT.OTHER_ALREADY_CONN
			
			connPlug = otherPlug
			otherPlug.connPlug = self
			
			if connPlug == null || otherPlug == null:
				return CONN_RESULT.INCOMPATIBLE
				
			return CONN_RESULT.SUCCESS
	
	return CONN_RESULT.NO_PLUG_FOUND


func recievedEntity(entity):
	return sourcePlug.transmitEntity(entity)

func transmitEntity(entity):
	return connPlug.recievedEntity(entity)
