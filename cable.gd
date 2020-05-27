tool
extends Node2D
var readyDone = false
export (PackedScene) var CABLE_NODE = null#preload("res://cablePoint.tscn")
export (PackedScene) var CABLE_NODE_SPRITE = null#preload("res://cablePointSprite.tscn")
export (NodePath) var START_PIN_PATH = null
var START_PIN = null
export (bool) var START_PIN_REF_ONLY

export (NodePath) var END_PIN_PATH = null
var END_PIN = null
export (bool) var END_PIN_REF_ONLY

export (PackedScene) var START_PLUG_SCENE = null setget startPlug
var START_PLUG = null

export (PackedScene) var END_PLUG_SCENE = null setget endPlug
var END_PLUG = null

export (bool) var DRAW_CABLE_LINE2D = false
export (NodePath) var CABLE_LINE2D_PATH = null
var CABLE_LINE2D = null

export (Array, NodePath) var PHYS_EXCEP = []

export (int, 1, 10, 1) var ROPE_TAUGHTNESS = 1
export (int) var NODE_COUNT = 60
export (float) var CONSTRAIN = 10
export (float) var CABLE_LENGTH = 4000
export (Vector2) var GRAVITY = Vector2(0,9.8)
var gravity = 0
export (float, 0.6, 1.0, 0.01) var FRICTON = 0.95
export (float) var ROT_DIST_THRESHOLD = 28

export (bool) var reloadEditorCable = false setget reload
export (bool) var activeInEditor = false setget activateEditor

export(PackedScene) var test

var parentLinkCable = null
var childLinkCable = null


var pos: PoolVector2Array
var posOld: PoolVector2Array
var prevPos : PoolVector2Array
var prevPosOld : PoolVector2Array
var cableNodes = []

var cNodesFlipped = false

var tempStartNodePos
var tempEndNodePos

var endMonitor = null
var startMonitor = null


#used for determining which plugs changes between character switching takes
#priority
var lastTouchedPlug = null

func startPlug(val):
	START_PLUG_SCENE = val
	if START_PLUG_SCENE != null:
		START_PLUG = START_PLUG_SCENE.instance()
		START_PLUG.set_global_rotation(get_global_rotation() + deg2rad(180))
		START_PLUG.parentCable = self

func endPlug(val):
	END_PLUG_SCENE = val
	if END_PLUG_SCENE != null:
		END_PLUG = END_PLUG_SCENE.instance()
		END_PLUG.set_rotation(deg2rad(180))
		END_PLUG.parentCable = self
		

func reload(val):
	if (val):
		_ready()
		
func activateEditor(val):
	
	if !Engine.editor_hint:
		return
	
	activeInEditor = val
	
	if(val):
		_ready()
	else:
		removeAllChildren()

		resize_arrays()
		
	
func removeAllChildren():
	CABLE_LINE2D = get_node(CABLE_LINE2D_PATH)
	
	if (self.get_children().size() > 0):
		for n in self.get_children():
			if n != CABLE_LINE2D:
				self.remove_child(n)
				

func _ready():
	call_deferred("readyDeferred")
	
func readyDeferred():
	
	#execute in editor if activeInEditor (will execute in game regardless)
	if Engine.editor_hint && !activeInEditor:
		return
		
	
	removeAllChildren()
	
	if (START_PIN_PATH != null):
		START_PIN = get_node(START_PIN_PATH)
		
	if (END_PIN_PATH != null):
		END_PIN = get_node(END_PIN_PATH)
		
	
	if (CABLE_LINE2D_PATH != null):
		CABLE_LINE2D = get_node(CABLE_LINE2D_PATH)
	
	
	resize_arrays()
	
	init_position()
	
	initShapes()
	
	readyDone = true
	
func initShapes():
	for n in range(NODE_COUNT):
		var newCN = CABLE_NODE.instance()
		cableNodes.append(newCN)
		if (!CABLE_NODE_SPRITE):
			newCN.setCableNodeSprite(CABLE_NODE_SPRITE)
		#need to add child to make active
		add_child(newCN)
		newCN.set_name("cablePoint_%s_%s" % [n, get_name()])
		setCNPos(n, pos[n])
		
		
		if (n == 0):
			if START_PLUG != null:
				cableNodes[n].add_child(START_PLUG)
				#need to give distince name amongst this cable so that the dictionary
				#in the extra wrappers in the cable cswrapper works
				START_PLUG.set_name("plugA_%s" % self.get_name())
				
		if (n == NODE_COUNT - 1):
			if END_PLUG != null:
				cableNodes[n].add_child(END_PLUG)
				END_PLUG.set_name("plugB_%s" % self.get_name())
		
	#prevent parts of cable from colliding with eachother
	for n in range (NODE_COUNT):
		for k in range (NODE_COUNT):
			if (n == k):
				pass
			cableNodes[n].add_collision_exception_with(cableNodes[k])
		if (START_PIN != null):
			if (START_PIN is PhysicsBody2D):
				cableNodes[n].add_collision_exception_with(START_PIN)
			
		if (END_PIN != null):
			if (END_PIN is PhysicsBody2D):
				cableNodes[n].add_collision_exception_with(END_PIN)	
		
		cableNodes[n].add_collision_exception_with(global.lvl().astroNode)
		for nodePath in PHYS_EXCEP:
			var node = get_node(nodePath)
			if node is PhysicsBody2D:
				cableNodes[n].add_collision_exception_with(node)
			collisionExcep(node, cableNodes[n])
	
#recursive function for getting all children to also be applied as an exception
func collisionExcep(node, collideNode):
	if node.get_child_count() > 0:
		for child in node.get_children():
			if child is PhysicsBody2D:
				collideNode.add_collision_exception_with(child)
				collisionExcep(child, collideNode)
	
	
func getCNPos(index):
	return cableNodes[index].get_global_position()

func setCNPos(index, val):
	cableNodes[index].set_global_position(val)



func resize_arrays():
	#delete any shtuff in there just in case if in editor
	pos.resize(0)
	pos.resize(0)
	
	#resize
	pos.resize(NODE_COUNT)
	posOld.resize(NODE_COUNT)

func init_position():
	
	for i in range(NODE_COUNT):
		if (i == 0):
			var startPos = get_global_position()
			if (START_PIN != null):
				startPos = START_PIN.get_global_position()
				if (START_PIN_REF_ONLY && !Engine.editor_hint):
						START_PIN = null
				
			pos[i] = startPos
			posOld[i] = startPos
		
		elif (i == NODE_COUNT - 1):
			var endPos = get_global_position() + Vector2(400, 0)
			if (END_PIN != null):
				endPos = END_PIN.get_global_position()
				if (END_PIN_REF_ONLY && !Engine.editor_hint):
					END_PIN = null
				
			pos[NODE_COUNT - 1] = endPos
			posOld[NODE_COUNT - 1] = endPos
		
		else:
			pos[i] = position + Vector2(CONSTRAIN *i, 0) + pos[0]
			posOld[i] = position + Vector2(CONSTRAIN *i, 0) + posOld[0]
			
			
		
		position = Vector2.ZERO
	
	
	
#supposedly need to to this instead of _process in order for move_and_slide
#to work alright, but I didn't really notice a difference with just _proccess
func _physics_process(delta):
	if !readyDone || parentLinkCable != null:
		return
	
	gravity = GRAVITY.rotated(global.gravRadAngFromNorm) * global.gravMag
	
	#execute in editor if activeInEditor (will execute in game regardless)
	if Engine.editor_hint && !activeInEditor:
		return
	
	tempStartNodePos = pos[0]
	tempEndNodePos = getUltimateChildCable().pos[pos.size() -1]#END_PIN.get_global_position()
	
	update_points(delta)
	
	for i in range(ROPE_TAUGHTNESS):
		update_distance(delta)
	
	ropeLengthLimit(delta)
	
#	if (getRopeLength() > CABLE_LENGTH):
#		pos = prevPos
#		posOld = prevPosOld
#
#		for i in range(NODE_COUNT):
#			setCNPos(i, pos[i])
			
		
	
	
	
	
	renderLines()
	#startMonitor = setgetTotalCableStartPlugPin(true, true)
	#endMonitor = setgetTotalCableEndPlugPin(true, true)
func ropeLengthLimit(delta):
	
	var head = getUltimateParentCable()
	var ropeLength = head.getRopeLength()
	var resLength = head.getTotalRestrictedLength()
	var ultimateCC = getUltimateChildCable()
	if ropeLength > resLength:
		var diff = ropeLength - resLength
		var astro = global.lvl().astroNode
		if START_PIN == astro:
			#print("wooooop1111")
			var diffVect = astro.get_global_position() - tempStartNodePos
			diffVect = diffVect.normalized() * diff
			astro.restrictAndMove2Point = tempStartNodePos - diffVect
			update_points(delta)
	
			for i in range(ROPE_TAUGHTNESS):
				update_distance(delta)
			
			
			return
		
		
		elif ultimateCC.END_PIN == astro:
			#print("wooooop222")
			var diffVect = astro.get_global_position() - tempEndNodePos
			diffVect = diffVect.normalized() * diff
			astro.restrictAndMove2Point = (tempEndNodePos - diffVect)
			update_points(delta)
	
			for i in range(ROPE_TAUGHTNESS):
				update_distance(delta)
			return
		#resetToPrevFrame()
	
func getTotalRestrictedLength():
	var resLength = CABLE_LENGTH
	
	if childLinkCable != null:
		resLength += childLinkCable.getTotalRestrictedLength()
	
	return resLength
	
func getRopeLength():
	var length = 0
	for i in range(NODE_COUNT-1):
		length += getCNPos(i).distance_to(getCNPos(i+1))
		
	if childLinkCable != null:
		length += childLinkCable.getRopeLength()
	
	return length
	
func resetToPrevFrame():
	pos = prevPos
	posOld = prevPosOld
		
	for i in range(NODE_COUNT):
		setCNPos(i, pos[i])
		
	if childLinkCable != null:
		childLinkCable.resetToPrevFrame()

func update_points(delta):
	prevPos = pos
	prevPosOld = posOld
	
	
	
	for i in range (NODE_COUNT):
		
		if (i == 0 && parentLinkCable != null):
			pos[0] = parentLinkCable.pos[parentLinkCable.pos.size() -1 ]
			posOld[0] = parentLinkCable.posOld[parentLinkCable.posOld.size() -1 ]
			continue
			
		if (i == 0 && START_PIN != null):
			pos[0] = START_PIN.get_global_position()
			posOld[0] = START_PIN.get_global_position()
			continue
			
		if (i==NODE_COUNT-1 && END_PIN != null):
			pos[NODE_COUNT -1] = END_PIN.get_global_position()
			posOld[NODE_COUNT -1] = END_PIN.get_global_position()
			continue
	
	
		#var dist = getCNPos(i).distance_to(getCNPos(i+1))
		#var acc = dist/ROT_DIST_THRESHOLD
		#if (acc > 1-FRICTON):
		#	acc = 1-FRICTON
	
		var vec2 = (pos[i] - posOld[i]) * (FRICTON) #+ acc)
		posOld[i] = pos[i]
		pos[i] += vec2 + (gravity * delta)
	
	if childLinkCable != null:
		childLinkCable.update_points(delta)

func update_distance(delta):
	
	
	for i in range (NODE_COUNT):
		if i == 0 && parentLinkCable != null:
			pos[i] = parentLinkCable.pos[parentLinkCable.NODE_COUNT -1]
			pos[i] = parentLinkCable.pos[parentLinkCable.NODE_COUNT -1]
			cableNodes[i].set_global_position(parentLinkCable.cableNodes[parentLinkCable.NODE_COUNT-1].get_global_position())
			cableNodes[i].look_at(parentLinkCable.cableNodes[parentLinkCable.NODE_COUNT-1].get_global_position())
			continue
		
		if i == NODE_COUNT-1 && childLinkCable == null:
			applyRotation(i)
			return
			
		var distance = 0
		if (i == NODE_COUNT -1 && childLinkCable != null):
			distance = pos[i].distance_to(childLinkCable.pos[1])
		else:
			distance = pos[i].distance_to(pos[i+1])
		if (distance == 0):
			distance = 0.0001
		var difference = CONSTRAIN - distance
		var percent = difference / distance
		var vec2 = 0
		if (i == NODE_COUNT -1 && childLinkCable != null):
			vec2 = childLinkCable.pos[1] - pos[i]
		else:
			vec2 = pos[i+1] - pos[i]
		
		if i == 0:
			if START_PIN != null:
				pos[i+1] += vec2 * percent
				applyRotation(i)
				#continue
			else:
				pos[i] -= vec2 * (percent/2)
				pos[i+1] += vec2 * (percent/2)
		else:
			if i+1 == NODE_COUNT-1 && END_PIN != null && childLinkCable== null:
				pos[i] -= vec2 * percent
			else:
				pos[i] -= vec2 * (percent/2)
				if (i == NODE_COUNT-1 && childLinkCable != null):
					childLinkCable.pos[1] += vec2 * (percent/2)
				else:
					pos[i+1] += vec2 * (percent/2)
				
		applyCollisionRestraint(i, delta)
				
	if childLinkCable != null:
		childLinkCable.update_distance(delta)
	
func applyCollisionRestraint(i, delta):
	
	applyRotation(i)
	
	var target = pos[i]
	var ogPos = getCNPos(i)
	#if ((target - ogPos) != Vector2(0, 0)):
	var dir = (target - ogPos).normalized()
	cableNodes[i].move_and_slide((target-ogPos)/delta, Vector2( 0, 0 ), false, 16)
	

	if (i == NODE_COUNT -1 && childLinkCable != null):
		var target2 = childLinkCable.pos[1]
		var ogPos2 = childLinkCable.getCNPos(1)
		#if ((target2 - ogPos2) != Vector2(0, 0)):
		var dir2 = (target2 - ogPos2).normalized()
		childLinkCable.cableNodes[1].move_and_slide((target2-ogPos2)/delta)
	else:
		var target2 = pos[i+1]
		var ogPos2 = getCNPos(i+1)
		#if ((target2 - ogPos2) != Vector2(0, 0)):
		var dir2 = (target2 - ogPos2).normalized()
		cableNodes[i+1].move_and_slide((target2-ogPos2)/delta)
	
	pos[i] = getCNPos(i)
	if (i == NODE_COUNT-1 && childLinkCable != null):
		childLinkCable.pos[1] = childLinkCable.getCNPos(1)
	else:
		pos[i+1] = getCNPos(i+1)
	
func applyRotation(i):
	if (i == 0):
		if (START_PIN == null):
			cableNodes[i].look_at(getCNPos(i+1))
		return
	
	if (i == NODE_COUNT-1 && childLinkCable == null):
		if (END_PIN == null):
			cableNodes[i].look_at(getCNPos(i-1))
		return
	
	var dist = 0
	if i == NODE_COUNT - 1 && childLinkCable != null:
		dist = getCNPos(i-1).distance_to(childLinkCable.getCNPos(1))
	else:
		dist = getCNPos(i-1).distance_to(getCNPos(i+1))
		
	
	var prevDifVec = getCNPos(i) - getCNPos(i-1)
	
	
	var nextDifVec = 0
	if i == NODE_COUNT - 1 && childLinkCable != null:
		nextDifVec = childLinkCable.getCNPos(1) - getCNPos(i)
	else:
		nextDifVec = getCNPos(i+1) - getCNPos(i)
		
		
	var avgVect = (prevDifVec + nextDifVec) / 2
	
	var acc = dist/ROT_DIST_THRESHOLD
	if (acc > 1):
		acc = 1
	
	#rotation for first node
	if (i == 0):
		avgVect == nextDifVec
		avgVect.x = avgVect.y
		avgVect.y = avgVect.x
	

	var radAngle = atan2(avgVect.y, avgVect.x)
	
	#if (abs(cableNodes[i].get_rotation() - radAngle) > (3.14/4)):
	#	radAngle =  cableNodes[i].get_rotation() + (3.14/4) * radAngle/abs(radAngle)
	
	cableNodes[i].set_rotation(radAngle * acc)
	
	
	
			
func renderLines():
	if (DRAW_CABLE_LINE2D && CABLE_LINE2D != null):
		CABLE_LINE2D.points = pos
	else:
		CABLE_LINE2D.points = []
	
	if childLinkCable != null:
		childLinkCable.renderLines()
	
	
			
#this part is still in progress
func attemptCableConnection(startPlug):
	
	var plug = START_PLUG if startPlug else END_PLUG
	
	var result = plug.attemptConnection()
	#print(result)
	if result == plug.CONN_RESULT.SUCCESS:
		if plug.fixed:
			#set cable node to child plug node position properly
				#so shit doesnt continuously correct itself and fly
			var newVect = plug.get_global_position()
			
			if (startPlug):
				cableNodes[0].set_global_position(newVect)
				plug.set_global_position(newVect)
				START_PIN = plug
			else:
				cableNodes[cableNodes.size()-1].set_global_position(newVect)
				plug.set_global_position(newVect)
				END_PIN = plug
	return result
	
	
	
func setFixPlug(plug):
	var newVect = plug.get_global_position()
	var isStartPlug = START_PLUG == plug
			
	if (isStartPlug):
		cableNodes[0].set_global_position(newVect)
		plug.set_global_position(newVect)
	else:
		cableNodes[cableNodes.size()-1].set_global_position(newVect)
		plug.set_global_position(newVect)




func addCableChild(cableNode):
	if START_PLUG.connPlug == cableNode.END_PLUG:# || START_PLUG.connPlug == cableNode.START_PLUG:
		#there was a stack overflow in the code here:
		cableNode.addCableChild(self)
		return
		
	if START_PLUG.connPlug == cableNode.START_PLUG:
		reverseCable()
		#cableNode.reverseCable()
		
	
	elif END_PLUG.connPlug == cableNode.END_PLUG:
		cableNode.reverseCable()
		#cableNode.addCableChild(self)
				
	END_PIN = null
	cableNode.START_PIN = null
		
	cableNode.parentLinkCable = self
	childLinkCable = cableNode
	
	cableNode.START_PLUG.childRemovedException = true
	cableNode.cableNodes[0].remove_child(cableNode.START_PLUG)
	cableNodes[NODE_COUNT-1].add_child(cableNode.START_PLUG)
	cableNode.START_PLUG.set_rotation(deg2rad(180))
	END_PLUG.set_rotation(0)
	END_PLUG.set_position(END_PLUG.get_position() - Vector2(END_PLUG.DIST_BETWEEN_PLUGS/2, 0))
	cableNode.START_PLUG.set_position(cableNode.START_PLUG.get_position() + Vector2(cableNode.START_PLUG.DIST_BETWEEN_PLUGS/2, 0))
	
	
	
func getUltimateParentCable():
	if parentLinkCable != null:
		return parentLinkCable.getUltimateParentCable()
	return self
	


#below are two functions that are custom getters and setters for the plugs or pins
#which are needed inorder to get the correct plug or pin when cables are connected
func setgetTotalCableStartPlugPin(getPin, getter, val = null):
	
	
	var ultimatePLC = getUltimateParentCable()
	
	
	if getter:
		return ultimatePLC.START_PIN if getPin else ultimatePLC.START_PLUG
	else:
		if getPin:
			ultimatePLC.START_PIN = val
		else:
			ultimatePLC.START_PLUG = val
		return
	
	
	
	
func setgetTotalCableEndPlugPin(getPin, getter, val = null):
	
	var ultimateCLC = getUltimateChildCable()
	
	if getter:
		return ultimateCLC.END_PIN if getPin else ultimateCLC.END_PLUG
	else:
		if getPin:
			ultimateCLC.END_PIN = val
		else:
			ultimateCLC.END_PLUG = val
		return
	
	
	
	
func getUltimateChildCable():
	if childLinkCable != null:
		return childLinkCable.getUltimateChildCable()
		
	return self
	
#func removeChildCableFromChain():
func reverseCable():
	getUltimateParentCable().reverseSingleCable()
	
func reverseSingleCable():
	var tempSTART_PLUG = START_PLUG
	var tempSTART_PIN = START_PIN
	
	START_PLUG = END_PLUG
	START_PIN = END_PIN
	END_PLUG = tempSTART_PLUG
	END_PIN = tempSTART_PIN
	
	var tempChildLinkCable = childLinkCable
	childLinkCable = parentLinkCable
	parentLinkCable = tempChildLinkCable
	
	if parentLinkCable != null:
		parentLinkCable.reverseSingleCable()
		
	cableNodes.invert()
	cNodesFlipped = !cNodesFlipped
	var tempPos = pos
	var tempPosOld = posOld
	for i in NODE_COUNT:
		pos[i] = tempPos[NODE_COUNT -1 -i]
		posOld[i] = tempPosOld[NODE_COUNT -1 -i]
	
func removeChildCable():
	childLinkCable.START_PLUG.childRemovedException = true
	cableNodes[NODE_COUNT -1].remove_child(childLinkCable.START_PLUG)
	childLinkCable.cableNodes[0].add_child(childLinkCable.START_PLUG)
	
	childLinkCable.START_PLUG.set_rotation(deg2rad(180))
	childLinkCable.START_PLUG.set_position(Vector2(0, 0))
	
	END_PLUG.set_rotation(deg2rad(180))
	END_PLUG.set_position(Vector2(0, 0))
	
	childLinkCable.parentLinkCable = null
	childLinkCable = null




#keeeeep
func CSWrapSaveStartState(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
#	var ignoreY = false
	
	
#	if CSWrap.saveStartState[currChar].size() == 0:
#		ignoreY = true
#		CSWrap.saveStartState[currChar] = []
#		print("ounweoinwoiehfiohwefhiowefiohwefhio")
		
	CSWrap.saveStartState[currChar].resize(7)
	
	
	#start plug
	CSWrap.saveStartState[currChar][0] = START_PLUG
	CSWrap.saveStartState[currChar][1] = START_PIN
	#start pin
	CSWrap.saveStartState[currChar][2] = END_PLUG
	CSWrap.saveStartState[currChar][3] = END_PIN
	
	#initial save spots need to be saved because first frame (due to these methods being called
	#on the first frame by the lvl.gd), points will jump
	#to initially set pins (which will change after frame 1)
	CSWrap.saveStartState[currChar][4] = childLinkCable
	CSWrap.saveStartState[currChar][5] = parentLinkCable
	
	#CSWrap.extraCSWrappers.resize(2)
	
	if !CSWrap.extraCSWrappers is Dictionary:
		CSWrap.extraCSWrappers = {START_PLUG.get_name() : CharacterSwitchingWrapper.new(), END_PLUG.get_name() : CharacterSwitchingWrapper.new()}
		CSWrap.extraCSWrappers[START_PLUG.get_name()].node = cableNodes[0].get_name() + "/" + START_PLUG.get_name()
		CSWrap.extraCSWrappers[END_PLUG.get_name()].node = cableNodes[cableNodes.size()-1].get_name() + "/" + END_PLUG.get_name()
		
	START_PLUG.CSWrapSaveStartState(CSWrap.extraCSWrappers[START_PLUG.get_name()])
	END_PLUG.CSWrapSaveStartState(CSWrap.extraCSWrappers[END_PLUG.get_name()])
	
	

#keeeeep
func CSWrapAddChanges(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	CSWrap.changesToApply[currChar].resize(17)
	
	CSWrap.changesToApply[currChar][0] = -1 if CSWrap.saveStartState[currChar][0] == START_PLUG else START_PLUG
	CSWrap.changesToApply[currChar][1] = -1 if CSWrap.saveStartState[currChar][1] == START_PIN else START_PIN
	CSWrap.changesToApply[currChar][2] = -1 if CSWrap.saveStartState[currChar][2] == END_PLUG else END_PLUG
	CSWrap.changesToApply[currChar][3] = -1 if CSWrap.saveStartState[currChar][3] == END_PIN else END_PIN
	CSWrap.changesToApply[currChar][4] = -1 if CSWrap.saveStartState[currChar][4] == childLinkCable else childLinkCable
	CSWrap.changesToApply[currChar][5] = -1 if CSWrap.saveStartState[currChar][5] == parentLinkCable else parentLinkCable
	
	CSWrap.changesToApply[currChar][6] = START_PLUG.get_name()
	CSWrap.changesToApply[currChar][7] = -1 if START_PIN == null else START_PIN.get_name()
	CSWrap.changesToApply[currChar][8] = END_PLUG.get_name()
	CSWrap.changesToApply[currChar][9] = -1 if END_PIN == null else END_PIN.get_name()
	CSWrap.changesToApply[currChar][10] = -1 if childLinkCable == null else childLinkCable.get_name()
	CSWrap.changesToApply[currChar][11] = -1 if parentLinkCable == null else parentLinkCable.get_name()
	CSWrap.changesToApply[currChar][12] = pos
	CSWrap.changesToApply[currChar][13] = posOld
	CSWrap.changesToApply[currChar][14] = cNodesFlipped
	CSWrap.changesToApply[currChar][15] = []
	CSWrap.changesToApply[currChar][16] = []
	for cn in cableNodes:
		CSWrap.changesToApply[currChar][15].append(cn.get_global_position())
		CSWrap.changesToApply[currChar][16].append(cn.get_global_rotation())
		
	
	for astroChar in global.CHAR:
		var otherChar = global.CHAR[astroChar]
		
		if global.charYearDict[otherChar] > global.charYearDict[currChar]:
			CSWrap.changesToApply[otherChar].resize(17)
			#start plug
			if !CSWrap.changesToApply[currChar][0] is int:
				CSWrap.changesToApply[otherChar][0] = CSWrap.changesToApply[currChar][0]
				
			#start pin
			if !CSWrap.changesToApply[currChar][1] is int:
				CSWrap.changesToApply[otherChar][1] = CSWrap.changesToApply[currChar][1]
			
			#end plug
			if !CSWrap.changesToApply[currChar][2] is int:
				CSWrap.changesToApply[otherChar][2] = CSWrap.changesToApply[currChar][2]
				
			#end pin
			if !CSWrap.changesToApply[currChar][3] is int:
				CSWrap.changesToApply[otherChar][3] = CSWrap.changesToApply[currChar][3]
				
			if !CSWrap.changesToApply[currChar][4] is int:
				CSWrap.changesToApply[otherChar][4] = CSWrap.changesToApply[currChar][4]

			if !CSWrap.changesToApply[currChar][5] is int:
				CSWrap.changesToApply[otherChar][5] = CSWrap.changesToApply[currChar][5]
	
		#-comment on this last part
		#-make enums to use

	START_PLUG.CSWrapAddChanges(CSWrap.extraCSWrappers[START_PLUG.get_name()])
	END_PLUG.CSWrapAddChanges(CSWrap.extraCSWrappers[END_PLUG.get_name()])
	
	
func CSWrapRecieveTransformChanges(CSWrap : CharacterSwitchingWrapper, currChar, posToAdd, rotToAdd):
	return
#	CSWrap.changesToApply[currChar].resize(3)
#
#	if CSWrap.changesToApply[currChar][0] == null:
#		CSWrap.changesToApply[currChar][0] = Vector2(0, 0)
#
#	if CSWrap.changesToApply[currChar][1] == null:
#		CSWrap.changesToApply[currChar][1] = 0
#
#	CSWrap.changesToApply[currChar][0] += posToAdd
#	CSWrap.changesToApply[currChar][1] += rotToAdd
	
				
func CSWrapRestoreState(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	var changes = CSWrap.changesToApply[currChar]
	var lvlNode = global.lvl()
	
	var START_PLUGname = CSWrap.changesToApply[currChar][6]
	var START_PINname = CSWrap.changesToApply[currChar][7]
	var END_PLUGname = CSWrap.changesToApply[currChar][8]
	var END_PINname = CSWrap.changesToApply[currChar][9]
	var clcName = CSWrap.changesToApply[currChar][10]
	var plcName = CSWrap.changesToApply[currChar][11]
	
	#return to initial set up, because frame one fucks this up
	START_PLUG = lvlNode.find_node(START_PLUGname, true, false)
	START_PIN = lvlNode.find_node(START_PINname, true, false) if !START_PINname is int else null
	END_PLUG = lvlNode.find_node(END_PLUGname, true, false)
	END_PIN = lvlNode.find_node(END_PINname, true, false) if !END_PINname is int else null
	childLinkCable = lvlNode.find_node(clcName, true, false) if !clcName is int else null
	parentLinkCable = lvlNode.find_node(plcName, true, false) if !plcName is int else null
	pos = CSWrap.changesToApply[currChar][12]
	posOld = CSWrap.changesToApply[currChar][13]
	cNodesFlipped = CSWrap.changesToApply[currChar][14]
	
	if cNodesFlipped:
		cableNodes.invert()
	
	for index in cableNodes.size():
		cableNodes[index].set_global_position(CSWrap.changesToApply[currChar][15][index])
		cableNodes[index].set_global_rotation(CSWrap.changesToApply[currChar][16][index])
		
	

func CSWrapRestoreExtraState(CSWrap : CharacterSwitchingWrapper):
	START_PLUG.CSWrapRestoreState(CSWrap.extraCSWrappers[START_PLUG.get_name()])
	END_PLUG.CSWrapRestoreState(CSWrap.extraCSWrappers[END_PLUG.get_name()])
	
func CSWrapApplyChanges(CSWrap : CharacterSwitchingWrapper, delta):
	pass
	
func attemptMovePlug():
	pass
	
func CSWrapApplyDependantChanges(CSWrap : CharacterSwitchingWrapper, delta):
	return
	#CSWrap.dependantCSWrappers[global.CharacterRes.id] = []
	
#	var currChar = global.CharacterRes.id
#	if CSWrap.dependantCSWrappers.has(currChar) && CSWrap.dependantCSWrappers[currChar].size() > 0:
#		for dependantCSW in CSWrap.dependantCSWrappers[currChar]:
#
#			var posChange = CSWrap.changesToApply[currChar][0]
#			var rotChange = CSWrap.changesToApply[currChar][1]
#
#			global.lvl().get_node(dependantCSW.node).CSWrapRecieveTransformChanges(dependantCSW, currChar, posChange, rotChange)
#
#	CSWrap.changesToApply[currChar][0] = Vector2(0, 0)
#	CSWrap.changesToApply[currChar][1] = 0
