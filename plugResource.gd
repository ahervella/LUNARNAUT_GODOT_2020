tool
extends Resource

class_name Plug

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

signal get_self

export (bool) var male = false
export (bool) var canGrab = true
export (Texture) var plugTexture = null setget setTexture
export (PLUG_REGION) var plugRegion = PLUG_TYPE.AUX
export (PLUG_TYPE) var plugType = PLUG_REGION.USA
#connPlug is set by cable when its cable end collision area runs into another
#cable or port collision area
var connPlug = null setget setConnection

var sourcePlug = null setget setSource

export (NodePath) var connAreaPath = null setget setConnArea
var connArea : Area2D = null

export (NodePath) var plugSpritePath = null setget setPlugSpritePath
var plugSprite : Sprite = null

func setPlugSpritePath(val):
	plugSpritePath = val
	plugSprite = plugSprite.get_node(plugSpritePath)
	
	if (plugTexture != null):
		plugSprite.set_texture(plugTexture)
	

func setConnArea(val):
	connAreaPath = val
	connArea = connArea.get_node(connAreaPath)
	
	if !connArea.has_group("plug"):
		connArea.add_group("plug")
	

func _ready():
	pass
	#plugNode = Node2D.new()
	
	#connArea = Area2D.new()
	
	
	#var collShape = CollisionShape2D.new()
	#var shape = CircleShape2D.new()
	#shape.set_radius(10)
	#collShape.set_shape (shape)
	#connArea.add_child(collShape)
	
	#connArea.connect("get_self", self, "getSelf")
	
	
	#plugNode.add_child(connArea)
	
	#plugSprite = Sprite.new()
	#plugNode.add_child(plugSprite)
	#plugNode.add_child(self)
	
	
func setTexture(val):
	plugTexture = val
	if (plugSprite != null):
		plugSprite.set_texture(plugTexture)


func getTexture():
	return plugTexture

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
	
func attemptConnection():
	if connPlug != null:
		return CONN_RESULT.SELF_ALREADY_CONN
	for area in connArea.get_overlapping_areas():
		if area.get_groups().has("plug"):
			var otherPlug = self
			
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
