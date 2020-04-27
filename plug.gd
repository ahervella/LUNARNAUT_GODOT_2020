tool
extends "res://SCRIPTS/intr_default.gd"

enum PLUG_TYPE {
	AUX,
	PWR,
	VGA, 
	NET,
	OXY
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

const DIST_BETWEEN_PLUGS = 12

export (bool) var male = false
export (bool) var canGrab = true
export (bool) var fixed = false
export (PLUG_REGION) var plugRegion = PLUG_TYPE.AUX
export (PLUG_TYPE) var plugType = PLUG_REGION.USA
#connPlug is set by cable when its cable end collision area runs into another
#cable or port collision area
var connPlug = null setget setConnection

var sourcePlug = null setget setSource

var parentCable = null setget setParentCable

#export (NodePath) var connAreaPath = null setget setConnAreaPath
var connArea = null

#export (NodePath) var plugSpritePath = null setget setPlugSpritePath
var plugSprite = null

#func setPlugSpritePath(val):
#	plugSpritePath = val
#	if (plugSpritePath != null):
#		plugSprite = get_node(plugSpritePath)
#
#func setConnAreaPath(val):
#	connAreaPath = val
#	if (connAreaPath != null):
#		connArea = get_node(connAreaPath)
func setParentCable(parentCableNode):
	parentCable = null
	if parentCableNode.has_method("attemptCableConnection"):
		parentCable = parentCableNode

func setSource(plugPath):
	if plugPath.has_method("transmitEntity"):
		sourcePlug = plugPath

func setConnection(plugNode):
	
	connPlug = null
	
	if plugNode == null:
		return
	
	#if is not of type plug && its not a port && this is male, return && not null && not astro
	if (plugNode.has_method("recievedEntity")):
		if (plugNode.male != male
		&& (plugNode.plugRegion == plugRegion || plugNode.plugRegion == PLUG_REGION.UNI)
		&& (plugNode.plugType == plugType)):
			connPlug = plugNode
			
			
				#print(self.get_global_position())
				
			return
	#	return
	
func _ready():
	for node in get_children():
		if node is Area2D:
			connArea = node
		if node is Sprite:
			plugSprite = node

	
func attemptConnection():
	if connPlug != null:
		return CONN_RESULT.SELF_ALREADY_CONN
	for area in connArea.get_overlapping_areas():
		if area.get_groups().has("plug"):
			var otherPlug = area.get_parent()
			
			if otherPlug.connPlug != null:
				return CONN_RESULT.OTHER_ALREADY_CONN
			
			connPlug = otherPlug
			otherPlug.connPlug = self
			
			if connPlug == null || otherPlug == null:
				return CONN_RESULT.INCOMPATIBLE
				
			#print(self.get_global_position())
			if (connPlug.fixed):
				
				self.fixed = true
				var connPlugRot = connPlug.get_global_rotation()
				self.set_global_position(connPlug.get_global_position() + Vector2(cos(connPlugRot) , sin(connPlugRot)) * DIST_BETWEEN_PLUGS)
				
				self.look_at(connPlug.get_global_position())
				
			return CONN_RESULT.SUCCESS
	
	return CONN_RESULT.NO_PLUG_FOUND

func Interact():
	
	var astro = global.lvl().astroNode
	
	#attempt to connect plug if currently grabbed
	#if no connection found or connection successful, let go of plug
	if currentlyGrabbed():
		var startPlug = true
		
		#if parentCable.START_PLUG == self:
			#parentCable.START_PIN = null
		if parentCable.END_PLUG == self:
			#parentCable.END_PIN = null
			startPlug = false
			print("endPlug")
		else:
			print("startPlug")
			
		var result = parentCable.attemptCableConnection(startPlug)
		print(result)
		if result == CONN_RESULT.NO_PLUG_FOUND:
			if startPlug:
				parentCable.START_PIN = null
			else:
				parentCable.END_PIN = null
		return
		
		
	
	
	
	#pick up plug if possible
	#check null before further checking parent cable
	if (canGrab):
		if (parentCable != null):
			#if either end of the cable already does not equal astto
			if (parentCable.START_PIN != astro && parentCable.END_PIN != astro):
				if parentCable.START_PLUG == self:
					parentCable.START_PIN = astro
				elif parentCable.END_PLUG == self:
					parentCable.END_PIN = astro
					
			else:
				return
				
		else:
			return
			
	else:
		return
		
	if (connPlug != null):
		if (connPlug.canGrab):
			if (connPlug.parentCable != null):
				if (connPlug.parentCable.START_PIN != astro && connPlug.parentCable.END_PIN != astro):
					if connPlug.parentCable.START_PLUG == self:
						connPlug.parentCable.START_PIN = astro
					elif connPlug.parentCable.END_PLUG == self:
						connPlug.parentCable.END_PIN = astro
		else:
			disconnectPlug()
			
func currentlyGrabbed():
	if canGrab == false:
		return false
		
	if parentCable != null:
		
		var astro = global.lvl().astroNode
		
		if parentCable.START_PLUG == self && parentCable.START_PIN == astro:
			print("start grabbed")
			return true
		elif parentCable.END_PLUG == self && parentCable.END_PIN == astro:
			print("end grabbed")
			return true
	return false
				

func disconnectPlug():
	print("disconn")
	if connPlug == null:
		return
	connPlug.connPlug = null
	fixed = false
	connPlug = null

func recievedEntity(entity):
	return sourcePlug.transmitEntity(entity)

func transmitEntity(entity):
	return connPlug.recievedEntity(entity)
