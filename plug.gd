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
	HYPO_CONNECTION_SUCCESSFUL
	HYPO_DISCONNECT_PLUGS
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

#apparently removing a plug from a child triggers it leaving astro's
#item area, and adding it again will trigger entering the area
#remapping child takes place in cable script when reversing things
var childRemovedException = false

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
	
	if TC_AUTO == null:
		TC_AUTO = TextConfig.new()
		TC_AUTO.ColorType = TC_AUTO.colorType.info
	
	if (TC_AUTO.text == null || TC_AUTO.text == ""):
		TC_AUTO.ColorType = TC_AUTO.colorType.info
		var plugSexString = "MALE" if male else "FEMALE"
		TC_AUTO.text = "//" + PLUG_REGION.keys()[plugRegion] + " _" + PLUG_TYPE.keys()[plugType] + " _" + plugSexString
	
	useNextInterNodeIfNeeded = true
	


func AutoInteract():
	if childRemovedException:
		childRemovedException = false
		return

	.AutoInteract()
		
	AnimateHypotheticalResult()
		
	
			
func AnimateHypotheticalResult():
	#print("AnimateHypotheticalResult")
	var hypotheticalResult = attemptConnection(true)
	
	var text = TextConfig.new()
	text.text = ""
	match hypotheticalResult:
		CONN_RESULT.INCOMPATIBLE:
			#print("CONN_RESULT.INCOMPATIBLE type")
			text.text = "   >>_plugs _are _incompatible"
			text.ColorType = text.colorType.alert
		CONN_RESULT.WRONG_TYPE:
			#print("CONN_RESULT.WRONG_TYPE")
			text.text = "   >>_plugs _not _correct _type"
			text.ColorType = text.colorType.alert
			#pass#AnimateHypotheticalResult()
		CONN_RESULT.SELF_ALREADY_CONN:
			#print("SELF_ALREADY_CONN")
			continue
		CONN_RESULT.PART_OF_SAME_CABLE:
			#print("CONN_RESULT.PART_OF_SAME_CABLE")
			text.text = "   >>_plugs _from _same _cable"
			text.ColorType = text.colorType.alert
			continue
		CONN_RESULT.OTHER_ALREADY_CONN:
			#print("CONN_RESULT.OTHER_ALREADY_CONN")
			continue
		CONN_RESULT.NO_PLUG_FOUND:
			#print("CONN_RESULT.NO_PLUG_FOUND")
			continue
		CONN_RESULT.OTHER_NOT_PLUG:
			#print("CONN_RESULT.OTHER_NOT_PLUG")
			continue
		CONN_RESULT.HYPO_CONNECTION_SUCCESSFUL:
			#print("CONN_HYPO_RESULT.CONNECTION_SUCCESSFUL")
			text.text = "   <<_connection _successful"
			text.ColorType = text.colorType.good
			continue
		CONN_RESULT.HYPO_DISCONNECT_PLUGS:
			#print("CONN_HYPO_RESULT.DISCONNECT_PLUGS")
			text.text = "   >>_disconnect _plugs"
			text.ColorType = text.colorType.warning
			continue
		CONN_RESULT.SUCCESS:
			#print("CONN_RESULT.SUCCESS")
			text.text = "   >>_connect _plugs"
			text.ColorType = text.colorType.good
	
	#print("hypotheticalResult")
	#print(hypotheticalResult)
	
	#if no change
	if (text.text != ""):
		if global.infoInteractNode != null && is_instance_valid(global.infoInteractNode):
			global.infoInteractNode.animateText(text, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)


func AutoCloseInteract():
	if childRemovedException: return
	
	#print("autoCLosedInteractPlug")
	.AutoCloseInteract()
	if global.infoInteractNode != null && is_instance_valid(global.infoInteractNode):
		global.infoInteractNode.closeText()


func Interact():
	
	if (processed):
		return
	
	if (isFixedPort):
		return
	
	
	var astro = global.lvl().astroNode

	
	var result = attemptConnection()
	var grabbed = currentlyGrabbed()
	var astroHasPlug = astroIsHoldingPlug()
	#print("interact_result")
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
			continue
			
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
			continue
					
		CONN_RESULT.OTHER_ALREADY_CONN, CONN_RESULT.OTHER_NOT_PLUG, CONN_RESULT.NO_PLUG_FOUND, CONN_RESULT.PART_OF_SAME_CABLE:
			if !grabbed && !astroHasPlug:
				#print(astroHasPlug)
				#print("grabbed")
				grabPlug()
			else:
				#print("dropped")
				dropPlug()
			continue
			
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
			
			continue
	
	#need to use call deferred due to being on the same frame as 
	#interacting and areas not detecting correctly
	call_deferred("AnimateHypotheticalResult")


func attemptConnection(hypothetical = false):
	if connPlug != null:
		if currentlyGrabbed() && connPlug.currentlyGrabbed() && hypothetical:
			return CONN_RESULT.HYPO_CONNECTION_SUCCESSFUL
			
		elif (hypothetical && !currentlyGrabbed() && !connPlug.currentlyGrabbed()):
			return CONN_RESULT.HYPO_DISCONNECT_PLUGS
			
		return CONN_RESULT.SELF_ALREADY_CONN

	var totalOverlappingAreas = connArea.get_overlapping_areas()
	
	#if grabbed, use astro's area to be able to find other near by plugs
	if currentlyGrabbed() || hypothetical:
		var astro = global.lvl().astroNode
		#print("astro overlapping areas")
		#print(astro.get_node("Item_check").get_overlapping_areas())
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
			
			var tempConnPlug = connPlug
			var tempOtherConnPlug = otherPlug.connPlug
			
			connPlug = otherPlug
			otherPlug.connPlug = self
			
			#if either rejected the other, both are set to null
			if connPlug == null || otherPlug.connPlug == null:
				connPlug = null
				otherPlug.connPlug = null
				
				if hypothetical:
					connPlug = tempConnPlug
					otherPlug.connPlug  = tempOtherConnPlug
					
					if (connPlug != null && currentlyGrabbed() && connPlug.currentlyGrabbed()):
						CONN_RESULT.HYPO_CONNECTION_SUCCESSFUL
				
				return CONN_RESULT.INCOMPATIBLE
				
			if hypothetical:
					connPlug = tempConnPlug
					otherPlug.connPlug  = tempOtherConnPlug
					return CONN_RESULT.SUCCESS
					
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
		
		
		#parentCable.lastTouchedPlug = self
		
		
		#print("astro set to start pin")
		#print(astroIsHoldingPlug())
		
	elif (parentCable.START_PIN != astro):
		
		#parentCable.setgetTotalCableEndPlugPin(true, false, astro)
		parentCable.END_PIN = astro
		
		
		#parentCable.lastTouchedPlug = self
		
		
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
		set_rotation(deg2rad(180))
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
		connPlug.set_rotation(deg2rad(180))
		if connPlug.parentCable.START_PLUG == self:
			connPlug.parentCable.START_PIN = null
		elif connPlug.parentCable.END_PLUG == self:
			connPlug.parentCable.END_PIN = null
		
		
			
	connPlug = null
	

func recievedEntity(entity):
	return sourcePlug.transmitEntity(entity)

func transmitEntity(entity):
	return connPlug.recievedEntity(entity)
	
	
	
	
	
	
func CSWrapSaveTimeDiscrepState(CSWrap: CharacterSwitchingWrapper, astroChar, set : bool):
	if parentCable != null:
		var lvlNode = global.lvl()
		for csw in lvlNode.charSwitchWrappers:
			var cswNode = lvlNode.get_node(csw.node)
			if cswNode == parentCable:
				cswNode.CSWrapSaveTimeDiscrepState(csw, astroChar, set, self.get_name())
				return
	
func CSWrapSaveStartState(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	
	
	
	CSWrap.saveStartState[currChar].resize(6)
	
	CSWrap.saveStartState[currChar][0] = get_global_position()
	CSWrap.saveStartState[currChar][1] = get_global_rotation()
	CSWrap.saveStartState[currChar][2] = connPlug
	CSWrap.saveStartState[currChar][3] = sourcePlug
	CSWrap.saveStartState[currChar][4] = parentCable
	CSWrap.saveStartState[currChar][5] = get_parent()
	
	for otherChar in CSWrap.savedTimeDiscrepencyState.keys():
		CSWrap.savedTimeDiscrepencyState[otherChar].resize(6)
		for i in CSWrap.savedTimeDiscrepencyState[otherChar].size():
			CSWrap.savedTimeDiscrepencyState[otherChar][i] = -1
	
func CSWrapDetectChange(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	
	if (CSWrap.saveStartState[currChar][5].get_global_position() + CSWrap.saveStartState[currChar][0] - get_global_position()).length() > 5:
		return true
			
	if (CSWrap.saveStartState[currChar][5].get_global_rotation() + CSWrap.saveStartState[currChar][1] - get_global_rotation()) > PI/16:
		return true
		
	if (CSWrap.saveStartState[currChar][2] != connPlug):
		return true
		
	if CSWrap.saveStartState[currChar][3] != sourcePlug:
		return true
		
	if CSWrap.saveStartState[currChar][4] != parentCable:
		return true
		
	if CSWrap.saveStartState[currChar][5] != get_parent():
		return true
		
	return false
	
func CSWrapSavePlugTimeDiscrepState(CSWrap : CharacterSwitchingWrapper, astroChar, set : bool):
	CSWrap.savedTimeDiscrepencyState[astroChar].resize(6)
	
	if !set:
		for i in CSWrap.savedTimeDiscrepencyState[astroChar].size():
			CSWrap.savedTimeDiscrepencyState[astroChar][i] = -1
		return
	
	CSWrap.savedTimeDiscrepencyState[astroChar].resize(6)
	
	CSWrap.savedTimeDiscrepencyState[astroChar][0] = get_position()
	CSWrap.savedTimeDiscrepencyState[astroChar][1] = get_rotation()
	CSWrap.savedTimeDiscrepencyState[astroChar][2] = connPlug
	CSWrap.savedTimeDiscrepencyState[astroChar][3] = sourcePlug
	CSWrap.savedTimeDiscrepencyState[astroChar][4] = parentCable
	CSWrap.savedTimeDiscrepencyState[astroChar][5] = get_parent()
	
func CSWrapAddChanges(CSWrap : CharacterSwitchingWrapper, changeDetected):
	var currChar = global.CharacterRes.id
	var parentNode = get_parent()
	CSWrap.changesToApply[currChar].resize(6)
	
	CSWrap.changesToApply[currChar][0] = get_position()
	CSWrap.changesToApply[currChar][1] = get_rotation()
	CSWrap.changesToApply[currChar][2] = connPlug.get_name() if connPlug != null else null
	CSWrap.changesToApply[currChar][3] = sourcePlug.get_name() if sourcePlug != null else null
	CSWrap.changesToApply[currChar][4] = parentCable.get_name() if parentCable != null else null
	CSWrap.changesToApply[currChar][5] = parentNode.get_name()
	
	if !changeDetected: return
	
	for otherChar in CSWrap.changesToApply.keys():
		if otherChar == currChar : continue
		if global.charYearDict[otherChar] > global.charYearDict[currChar]:
			CSWrap.changesToApply[otherChar].resize(6)
			for i in CSWrap.changesToApply[otherChar].size():
				CSWrap.changesToApply[otherChar][i] = CSWrap.changesToApply[currChar][i] if CSWrap.savedTimeDiscrepencyState[currChar][i] is int else CSWrap.savedTimeDiscrepencyState[currChar][i]

	
func CSWrapRecieveTransformChanges(CSWrap : CharacterSwitchingWrapper, currChar, posToAdd, rotToAdd):
	pass
	
func CSWrapRestoreState(CSWrap : CharacterSwitchingWrapper):
	return
#	var currChar = global.CharacterRes.id
#	var currLvl = global.lvl()
#	var restorations = CSWrap.changesToApply[currChar][0]
#
#	#resolve parent first
#	var parentNode = currLvl.find_node(restorations[5], true, false)
#
#	if parentNode != get_parent():
#		var selfNode = self
#		get_parent().remove_child(selfNode)
#		parentNode.add_child(selfNode)
#		set_owner(parentNode)
#
#	#then apply pos and rot
#	set_global_position(restorations[0])
#	set_global_rotation(restorations[1])
#	connPlug = currLvl.find_node(restorations[2], true, false) if restorations[2] != null else null
#	sourcePlug = currLvl.find_node(restorations[3], true, false) if restorations[3] != null else null
#	parentCable = currLvl.find_node(restorations[4], true, false) if restorations[4] != null else null

	
	
func CSWrapApplyChanges(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	var currLvl = global.lvl()
	
	var changes = CSWrap.changesToApply[currChar]
	
	if changes == []: return
	
	var parentNode = currLvl.find_node(changes[5], true, false)
	
	var selfNode = self
	get_parent().remove_child(selfNode)
	parentNode.add_child(selfNode)
	set_owner(parentNode)
	
	
	set_position(changes[0])
	set_rotation(changes[1])
	#connPlug = currLvl.find_node(changes[2], true, false) if changes[2] != null else null

	
	var newConnPlug = currLvl.find_node(changes[2], true, false) if changes[2] != null else null
	attemptConnectionSpecificPlug(newConnPlug)
	
	sourcePlug = currLvl.find_node(changes[3], true, false) if changes[3] != null else null
	parentCable = currLvl.find_node(changes[4], true, false) if changes[4] != null else null
	
	
#	if !changes[2] is int && connPlug != changes[2]:
#		attemptConnectionSpecificPlug(changes[2])
#		if connPlug != changes[2] && wasLastTouchedPlug != null && wasLastTouchedPlug:
#			#6 index is the direct location
#			parentCable.attemptMovePlug(changes[6])
#			attemptConnectionSpecificPlug(changes[2])
#
#	#0 is the difference vector (change, not direct position)
#	elif !changes[0] is int:
#		if wasLastTouchedPlug != null && wasLastTouchedPlug:
#			parentCable.attemptMovePlug(changes[0])
	
			
		
					
func attemptConnectionSpecificPlug(specPlug):
	var isStartPlug = null
	if parentCable != null:
		if parentCable.START_PLUG == self:
			isStartPlug = true
		elif parentCable.END_PLUG == self:
			isStartPlug = false
	
	#first disconnect if connected
	if connPlug != null:
		if parentCable != null:
			if isStartPlug && connPlug.parentCable != null:
				connPlug.parentCable.removeChildCable()
			else:
				parentCable.removeChildCable()
		disconnectPlug()
		#if was given null, which just means disconnect plug from anything
		#leave shit right here the way it is
		if specPlug == null:
			return true
		
	#attempt connection
	var result = attemptConnection()
	if result == CONN_RESULT.SUCCESS:
		if connPlug != specPlug:
			disconnectPlug()
			return false
			
		if parentCable != null && connPlug.parentCable != null:
			if parentCable.START_PLUG == self:
				connPlug.parentCable.addCableChild(parentCable)
			elif parentCable.END_PLUG == self:
				parentCable.addCableChild(connPlug.parentCable)
		return true
		
	return false
	
	
	
	
	
func CSWrapApplyDependantChanges(CSWrap : CharacterSwitchingWrapper, delta):
	pass
	
	
	
	
	
