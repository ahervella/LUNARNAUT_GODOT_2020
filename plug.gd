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
	PART_OF_SAME_CABLE
}

const DIST_BETWEEN_PLUGS = 12

export (bool) var male = false
#fixed port implies whether the plug can be grabbed and whether it has a parentCable
export (bool) var isFixedPort = false setget setIsFixedPort
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


func setIsFixedPort(val):
	if val:
		fixed = true
	isFixedPort = val
	
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
		
	
	
	
	
func _ready():
	for node in get_children():
		if node is Area2D:
			connArea = node
		if node is Sprite:
			plugSprite = node

	




func Interact():
	
	if (processed):
		return
	
	if (isFixedPort):
		return
	
	var astro = global.lvl().astroNode
	#var isStartPlug = null
	
	var result = attemptConnection()
	var grabbed = currentlyGrabbed()
	var astroHasPlug = astroIsHoldingPlug()
	#print(result)
	#print(self)
	
	processed = true
	
	match result:
		CONN_RESULT.INCOMPATIBLE, CONN_RESULT.WRONG_TYPE:
			#check if one is already grabbed
			if !grabbed && !astroHasPlug:
				grabPlug()
			else:
				dropPlug()
			return
			
		CONN_RESULT.SELF_ALREADY_CONN:
			connPlug.processed = true
			
			if grabbed:
				dropPlug()
				connPlug.dropPlug()
				if (!connPlug.isFixedPort && !isFixedPort):
					if connPlug.parentCable.parentLinkCable == null:
						parentCable.addCableChild(connPlug.parentCable)
					elif connPlug.parentCable.childLinkCable == null:
						connPlug.parentCable.addCableChild(parentCable)
			else:
				if !isFixedPort:
					disconnectPlug()
					grabPlug()
				else: #if its a fixed port
					connPlug.grabPlug()
					disconnectPlug()
			return
					
		CONN_RESULT.OTHER_ALREADY_CONN, CONN_RESULT.OTHER_NOT_PLUG, CONN_RESULT.NO_PLUG_FOUND, CONN_RESULT.PART_OF_SAME_CABLE:
			if !grabbed && !astroHasPlug:
				print(astroHasPlug)
				#print("grabbed")
				grabPlug()
			else:
				#print("dropped")
				dropPlug()
			return
			
		CONN_RESULT.SUCCESS:
			
			if connPlug.isFixedPort:
				if grabbed:
					dropPlug()
				else:
					disconnectPlug()
					grabPlug()
			
			
			elif !grabbed && !connPlug.currentlyGrabbed():
				disconnectPlug()
				grabPlug()
				
			else:
				if !grabbed:
					grabPlug()
				if !connPlug.currentlyGrabbed():
					connPlug.grabPlug()
					connPlug.processed = true
			
			return



func attemptConnection():
	if connPlug != null:
		return CONN_RESULT.SELF_ALREADY_CONN
		
	var totalOverlappingAreas = connArea.get_overlapping_areas()
	
	
	#if grabbed, use astro's area to be able to find other near by plugs
	if currentlyGrabbed():
		var astro = global.lvl().astroNode
		for area in astro.get_node("Item_check").get_overlapping_areas():
			if area.get_groups().has("plug"):
				if area.get_parent() != self:
					totalOverlappingAreas.append(area)
	
	
	#check areas until a plug is found
	for area in totalOverlappingAreas:
		if area.get_groups().has("plug"):
			var otherPlug = area.get_parent()
			
			#only interact with plugs that haven't been processed
			if otherPlug.processed: continue
			
			if otherPlug.connPlug != null:
				return CONN_RESULT.OTHER_ALREADY_CONN
			
			#check they are not part of the same cable
			if parentCable != null && otherPlug.parentCable != null:
				if (parentCable == otherPlug.parentCable
					|| parentCable.setgetTotalCableEndPlugPin(false, true) == otherPlug.parentCable.setgetTotalCableEndPlugPin(false, true)
					|| parentCable.setgetTotalCableStartPlugPin(false, true) == otherPlug.parentCable.setgetTotalCableStartPlugPin(false, true)):
						return CONN_RESULT.PART_OF_SAME_CABLE
			
			
			connPlug = otherPlug
			otherPlug.connPlug = self
			
			#if either rejected the other, both are set to null
			if connPlug == null || otherPlug.connPlug == null:
				connPlug = null
				otherPlug.connPlug = null
				return CONN_RESULT.INCOMPATIBLE
				
				
			#connection worked, so allign plugs properly
			
			if (connPlug.fixed || connPlug.isFixedPort):
				
				self.fixed = true
				var connPlugRot = connPlug.get_global_rotation()
				self.set_global_position(connPlug.get_global_position() + Vector2(cos(connPlugRot) , sin(connPlugRot)) * DIST_BETWEEN_PLUGS)
				
				self.look_at(connPlug.get_global_position())
				
				if !isFixedPort:
					parentCable.setFixPlug(self)
				
			return CONN_RESULT.SUCCESS
	
	return CONN_RESULT.NO_PLUG_FOUND
	



func currentlyGrabbed():
	if isFixedPort:
		return false
		
	if parentCable != null:
		
		var astro = global.lvl().astroNode
		
		if parentCable.START_PLUG == self && parentCable.START_PIN == astro:
			#print("start grabbed")
			return true
		elif parentCable.END_PLUG == self && parentCable.END_PIN == astro:
			#print("end grabbed")
			return true
	return false
				

func astroIsHoldingPlug():
	var astro = global.lvl().astroNode
	var areas = astro.get_node("Item_check").get_overlapping_areas()
	
	for area in areas:
		if (area.get_groups().has("plug")):
			var plug = area.get_parent()
			if !plug.isFixedPort:
				if plug.parentCable.START_PLUG == plug:
					
					if plug.parentCable.START_PIN == astro:
						return true
				if plug.parentCable.END_PLUG == plug:
					
					if plug.parentCable.END_PIN == astro:
						return true
	return false
		

func dropPlug(isStartPlug = null):
	
	if connPlug != null:
		if !connPlug.isFixedPort && !connPlug.fixed:
			if parentCable.START_PLUG == self:
				parentCable.START_PIN = self
			else:
				parentCable.END_PIN = self
			return
	
	
	if isFixedPort:
		return
	
	
	
	
	if isStartPlug == null:
		isStartPlug = parentCable.START_PLUG == self
	
	if isStartPlug:
		parentCable.START_PIN = null
	else:
		parentCable.END_PIN = null
	
	if connPlug != null:
		if connPlug.isFixedPort || connPlug.fixed:
			if isStartPlug:
				parentCable.START_PIN = self
			else:
				parentCable.END_PIN = self
				
		
	
	



func grabPlug(isStartPlug = null):
	if isFixedPort:
		return
	if isStartPlug == null:
		isStartPlug = parentCable.START_PLUG == self
	
	
	
	var astro = global.lvl().astroNode
	
	if isStartPlug && parentCable.END_PIN != astro:
		
		parentCable.START_PIN = astro
		#print("astro set to start pin")
		#print(astroIsHoldingPlug())
		
	elif (parentCable.START_PIN != astro):
		
		#parentCable.setgetTotalCableEndPlugPin(true, false, astro)
		parentCable.END_PIN = astro
		#print("astro set to end pin")
		#print(parentCable.START_PIN)
		#print(parentCable.END_PIN)
		#print(astroIsHoldingPlug())



func disconnectPlug():
	#print("disconn")
	if connPlug == null:
		return
		
	#disconnect cables if cables are connected
	if parentCable != null:
		if connPlug.parentCable != null:
			if parentCable.childLinkCable != null:
				if parentCable.childLinkCable == connPlug.parentCable:
					parentCable.removeChildCable()
					
			if connPlug.parentCable.childLinkCable != null:
				if connPlug.parentCable.childLinkCable == parentCable:
					connPlug.parentCable.removeChildCable()
		
	connPlug.connPlug = null
	fixed = false
	if (connPlug.parentCable != null):
		if connPlug.parentCable.START_PLUG == self:
			connPlug.parentCable.START_PIN = null
		elif connPlug.parentCable.END_PLUG == self:
			connPlug.parentCable.END_PIN = null
			
	connPlug = null
	

func recievedEntity(entity):
	return sourcePlug.transmitEntity(entity)

func transmitEntity(entity):
	return connPlug.recievedEntity(entity)
