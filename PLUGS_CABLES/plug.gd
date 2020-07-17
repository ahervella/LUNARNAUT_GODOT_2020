tool
extends "res://SCRIPTS/INTERACT/intr_default.gd"

const hazardScene = preload("res://SCENES/hazard.tscn")
const sparkScene = preload("res://SCENES/PLUG_SCENES/PLUG_SPARK.tscn")

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

export (bool) var male = false setget setPlugSex
#fixed port implies whether the plug can be grabbed and whether it has a parentCable
export (bool) var isFixedPort = false setget setIsFixedPort
#for identifying if a plug is temporarily fixed due to its connection
export (bool) var tempFixed = false
export (PLUG_REGION) var plugRegion = PLUG_REGION.USA setget setPlugRegion
export (PLUG_TYPE) var plugType = PLUG_TYPE.AUX setget setPlugType
export (bool) var isPowerHazard = false setget setIsPowerHazard
var powerPlugHazard = null
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

var changesApplied = false
var triedConn = null

var readyDone = false

func setIsFixedPort(val):
	if val:
		tempFixed = true
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
	if (plugNode.has_method("receivedEntity")):
		if (plugNode.male != male
		&& (plugNode.plugRegion == plugRegion || plugNode.plugRegion == PLUG_REGION.UNI)
		&& (plugNode.plugType == plugType)):
			connPlug = plugNode
		
	
	
func setLightMask(val):
	$plugSprite.set_light_mask(val)
	
	
func setIsPowerHazard(val):
	
	if plugType != PLUG_TYPE.PWR:
		isPowerHazard = false
		return
	
	isPowerHazard = val
	
	if Engine.editor_hint || !readyDone: return
	attempAddPowerHazard()
	
	
func attempAddPowerHazard():
	if Engine.editor_hint: return
	
	if isPowerHazard:
		
		powerPlugHazard = hazardScene.instance()
		
		add_child(powerPlugHazard)
		powerPlugHazard.set_owner(self)
		
		powerPlugHazard.clearTextures()
		
		var plugShape = null
		for child in get_children():
			if child is Area2D:
				plugShape = child.get_child(0)
				break
				
		powerPlugHazard.setCustomShape(plugShape)
		powerPlugHazard.deathUponTouchingSource = true
		setPlugSpark(true)

	else:
		remove_child(powerPlugHazard)
		powerPlugHazard = null
		
		setPlugSpark(false)
	
func setPlugSpark(enable):
	if enable:
		var spark = sparkScene.instance()
		add_child(spark)
		spark.set_owner(self)
		
	else:
		for child in get_children():
			if child is AnimatedSprite:
				child.queue_free()
	
func _ready():
	#only proccess at run time
	if Engine.editor_hint: return
	
	for node in get_children():
		if node is Area2D:
			connArea = node
		if node is Sprite:
			plugSprite = node
			
	setPlugTcAuto()
	useNextInterNodeIfNeeded = true
	cancelOverlappingInteractables = false
	
	if isFixedPort:
		setLightMask(get_light_mask())
#	readyEXT()#call_deferred("readyEXT")
#
	readyDone = true
#func readyEXT():
#	pass
	
	attempAddPowerHazard()
	
func setPlugSex(val):
	male = val
	setPlugTcAuto()
	
func setPlugRegion(val):
	plugRegion = val
	if !Engine.editor_hint: return
	setPlugTcAuto()
	
func setPlugType(val):
	plugType = val
	setPlugTcAuto()
	
	#if !Engine.editor_hint: return
	setIsPowerHazard(isPowerHazard)
	
	property_list_changed_notify()
	
func setPlugTcAuto():
	
	#don't do on runtime
	if !Engine.editor_hint: return
	
	if TC_AUTO == null:
		TC_AUTO = TextConfig.new()
		TC_AUTO.ColorType = TC_AUTO.colorType.info
	
	#if (TC_AUTO.text == null || TC_AUTO.text == ""):
	TC_AUTO.ColorType = TC_AUTO.colorType.info
	var plugSexString = "MALE" if male else "FEMALE"
	TC_AUTO.text = "//" + PLUG_REGION.keys()[plugRegion] + " _" + PLUG_TYPE.keys()[plugType] + " _" + plugSexString
	
	TC_AUTO.property_list_changed_notify()
	property_list_changed_notify()
	


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
			if (connPlug.tempFixed || connPlug.isFixedPort):
				
				self.tempFixed = true
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
		if !connPlug.isFixedPort && !connPlug.tempFixed:
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
		if connPlug.isFixedPort || connPlug.tempFixed:
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
	tempFixed = false
	if (connPlug.parentCable != null):
		connPlug.set_rotation(deg2rad(180))
		if connPlug.parentCable.START_PLUG == self:
			connPlug.parentCable.START_PIN = null
		elif connPlug.parentCable.END_PLUG == self:
			connPlug.parentCable.END_PIN = null
		
		
			
	connPlug = null
	

func receivedEntity(entity):
	if sourcePlug != null:
		return sourcePlug.transmitEntity(entity)
	return ("NO sourcePlug found at " + get_name())
	
func transmitEntity(entity):
	if connPlug != null:
		return connPlug.receivedEntity(entity)
	
	return ("NO connPlug found at " + get_name())
	
	
	
	
	
	
func CSWrapSaveTimeDiscrepState(CSWrap, astroChar, set : bool):
	if parentCable != null:
		var lvlNode = global.lvl()
		for csw in lvlNode.charSwitchWrappers.values():
			var cswNode = lvlNode.get_node(csw.nodePath)
			if cswNode == parentCable:
				cswNode.CSWrapSaveTimeDiscrepState(csw, astroChar, set, self.get_name())
				return
	
func CSWrapSaveStartState(CSWrap ):
	var currChar = global.currCharRes.id
	
	CSWrap.saveStartState[currChar].resize(6)
	
	
	
	CSWrap.saveStartState[currChar][0] = get_global_position()
	CSWrap.saveStartState[currChar][1] = get_global_rotation()
	CSWrap.saveStartState[currChar][2] = connPlug
	CSWrap.saveStartState[currChar][3] = sourcePlug
	CSWrap.saveStartState[currChar][4] = parentCable
	CSWrap.saveStartState[currChar][5] = get_parent()
	
#	for otherChar in CSWrap.savedTimeDiscrepencyState.keys():
#		CSWrap.savedTimeDiscrepencyState[otherChar].resize(6)
#		for i in CSWrap.savedTimeDiscrepencyState[otherChar].size():
#			CSWrap.savedTimeDiscrepencyState[otherChar][i] = -1
	
func CSWrapDetectChange(CSWrap ):
	var currChar = global.currCharRes.id
		
		
	if (CSWrap.saveStartState[currChar][0] - get_global_position()).length() > 5:
		return true
			
	#rotation is always freaking out so lets not check this for now
	#if (CSWrap.saveStartState[currChar][5].get_global_rotation() + CSWrap.saveStartState[currChar][1] - get_global_rotation()) > PI/8:
	#	return true
		
	if (CSWrap.saveStartState[currChar][2] != connPlug):
		return true
		
	if CSWrap.saveStartState[currChar][3] != sourcePlug:
		return true
		
	if CSWrap.saveStartState[currChar][4] != parentCable:
		return true
		
	if CSWrap.saveStartState[currChar][5] != get_parent():
		return true
		
	return false
	
func CSWrapSavePlugTimeDiscrepState(CSWrap , astroChar, set : bool, INITChange = false):
	CSWrap.savedTimeDiscrepencyState[astroChar].resize(6)
	
	if !set:
		for i in CSWrap.savedTimeDiscrepencyState[astroChar].size():
			CSWrap.savedTimeDiscrepencyState[astroChar][i] = -1
		return
	
	CSWrap.savedTimeDiscrepencyState[astroChar].resize(6)
	
	var connPlugName = connPlug.get_name() if connPlug != null else null
	var sourcePlugName = sourcePlug.get_name() if sourcePlug != null else null
	var parentCableName = parentCable.get_name() if parentCable != null else null
	
	CSWrap.savedTimeDiscrepencyState[astroChar][0] = get_position() if !INITChange else CSWrap.changesToApply[astroChar][0]
	CSWrap.savedTimeDiscrepencyState[astroChar][1] = get_rotation() if !INITChange else CSWrap.changesToApply[astroChar][1]
	CSWrap.savedTimeDiscrepencyState[astroChar][2] = connPlugName if !INITChange else CSWrap.changesToApply[astroChar][2]
	CSWrap.savedTimeDiscrepencyState[astroChar][3] = sourcePlugName if !INITChange else CSWrap.changesToApply[astroChar][3]
	CSWrap.savedTimeDiscrepencyState[astroChar][4] = parentCableName if !INITChange else CSWrap.changesToApply[astroChar][4]
	CSWrap.savedTimeDiscrepencyState[astroChar][5] = get_parent().get_name() if !INITChange else CSWrap.changesToApply[astroChar][5]
	
func CSWrapAddChanges(CSWrap , thisObjChangeDetected = null):
	if thisObjChangeDetected == null:
		thisObjChangeDetected = CSWrapDetectChange(CSWrap)
	
	var currChar = global.currCharRes.id
	var parentNode = get_parent()
	CSWrap.changesToApply[currChar].resize(6)
	
	CSWrap.changesToApply[currChar][0] = get_global_position()
	CSWrap.changesToApply[currChar][1] = get_global_rotation()
	CSWrap.changesToApply[currChar][2] = connPlug.get_name() if connPlug != null else null
	CSWrap.changesToApply[currChar][3] = sourcePlug.get_name() if sourcePlug != null else null
	CSWrap.changesToApply[currChar][4] = parentCable.get_name() if parentCable != null else null
	CSWrap.changesToApply[currChar][5] = parentNode.get_name()
	
	if !thisObjChangeDetected: return
	
	for otherChar in CSWrap.changesToApply.keys():
		if otherChar == currChar : continue
		if global.charYearDict[otherChar] > global.charYearDict[currChar]:
			CSWrap.changesToApply[otherChar].resize(6)
			
			if CSWrap.savedTimeDiscrepencyState[otherChar] == null || CSWrap.savedTimeDiscrepencyState[otherChar].size() == 0:
				CSWrap.savedTimeDiscrepencyState[otherChar].resize(6)
				for i in CSWrap.savedTimeDiscrepencyState[otherChar].size():
					CSWrap.savedTimeDiscrepencyState[otherChar][i] = -1
			
			for i in CSWrap.changesToApply[otherChar].size():
				CSWrap.changesToApply[otherChar][i] = CSWrap.changesToApply[currChar][i] if CSWrap.savedTimeDiscrepencyState[otherChar][i] is int else CSWrap.savedTimeDiscrepencyState[otherChar][i]

	changesApplied = false
	triedConn = null

func CSWrapApplyChanges(CSWrap):
	triedConn = false
	var currChar = global.currCharRes.id
	var currLvl = global.lvl()
	
	var changes = CSWrap.changesToApply[currChar]
	
	if changes == []: return
	
	var parentNode = currLvl.find_node(changes[5], true, false)
	
	var selfNode = self

	
	#don't need to do this because the plug is always attached to something
	#set_global_position(changes[0])
	#set_global_rotation(changes[1])
	#savedPos = changes[0]
	#savedRot = changes[1]
	
	sourcePlug = currLvl.find_node(changes[3], true, false) if changes[3] != null else null
	parentCable = currLvl.find_node(changes[4], true, false) if changes[4] != null else null
	
	var newConnPlug = currLvl.find_node(changes[2], true, false) if changes[2] != null else null
	
	changesApplied = true
	
	#need to add this here because apparently areas do not register their new location until
	#the next frame, so attempting a connection (via attemptConnection()) with anything near by 
	# in the attemptConnectionSpecificPlug() will not find any plug overlapping areas
	yield(get_tree(),"physics_frame")
	
	
	var connectionSuccess = attemptConnectionSpecificPlug(newConnPlug)
	
	if parentCable == null || connectionSuccess:
		get_parent().remove_child(self)
		parentNode.add_child(self)
		set_owner(parentNode)
		
	
	elif !connectionSuccess && parentCable != null:
		get_parent().remove_child(selfNode)
		
		if parentCable.START_PLUG == self:
			parentCable.cableNodes[0].add_child(self)
			set_owner(parentCable.cableNodes[0])
			
		elif parentCable.END_PLUG == self:
			parentCable.cableNodes[parentCable.cableNodes.size()-1].add_child(self)
			set_owner(parentCable.cableNodes[parentCable.cableNodes.size()-1])
			
	#because we are already yielding one physics frame above to compensate for
	#that problem, here we have to mark this conn attemmpt as done to
	#signal the cable node to start trying to detect change finally
	triedConn = true
	
	#here parents have been rearranged so need to make a fresh save start staste
	#now that the plugs and the cables are donr applying changes
	parentCable.CSWrapSaveStartState(parentCable.csWrap)

					
func attemptConnectionSpecificPlug(specPlug):
	if specPlug == connPlug: return true
	if specPlug != null && !specPlug.changesApplied: return false
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
	
	
	
	
	
func CSWrapApplyDependantChanges(CSWrap):
	pass
	
	
	
	
	
