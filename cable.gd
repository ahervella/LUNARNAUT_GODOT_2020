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
var nodeCount = 0
export (float) var CONSTRAIN = 10
export (float) var EXTRA_SPRITE_THRESHOLD = 35
export (float) var CABLE_LENGTH = 4000
export (Vector2) var GRAVITY = Vector2(0,9.8)
export (float, 0.6, 1.0, 0.01) var FRICTON = 0.95
export (float) var ROT_DIST_THRESHOLD = 28

export (bool) var reloadEditorCable = false setget reload
export (bool) var activeInEditor = false setget activateEditor

export(PackedScene) var test

var parentLinkCable = null
var parentLinkCableIsStart = null
var childLinkCable = null
var childLinkCableIsStart = null

var headCable = self
var footCable = self

var cableNodePosDict = {}

var extraRenderingSprites = []
var pos: PoolVector2Array
var posOld: PoolVector2Array
var cableNodes = []

var newChild = null
var parNode = null

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
		
	nodeCount = NODE_COUNT
	
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
	
	#executes on first frame after ready, seems to only work then
	#if START_PLUG != null:
	#	call_deferred("attemptCableConnection", true)
	
	#if END_PLUG != null:
	#	call_deferred("attemptCableConnection", false)
		
	readyDone = true
	
func initShapes():
	for n in range(nodeCount):
		cableNodes.append(CABLE_NODE.instance())
		if (!CABLE_NODE_SPRITE):
			cableNodes[n].setCableNodeSprite(CABLE_NODE_SPRITE)
		#need to add child to make active
		add_child(cableNodes[n])
		setCNPos(n, pos[n])
		
		
		if (n == 0):
			if START_PLUG != null:
				cableNodes[n].add_child(START_PLUG)
			
		if (n == nodeCount - 1):
			if END_PLUG != null:
				cableNodes[n].add_child(END_PLUG)
		
	#prevent parts of cable from colliding with eachother
	for n in range (nodeCount):
		for k in range (nodeCount):
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
	
	cableNodePosDict[self] = []
	for cn in cableNodes:
		cableNodePosDict[self].append(cn)
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
	pos.resize(nodeCount)
	posOld.resize(nodeCount)

func init_position():
	
	for i in range(nodeCount):
		if (i == 0):
			var startPos = get_global_position()
			if (START_PIN != null):
				startPos = START_PIN.get_global_position()
				if (START_PIN_REF_ONLY && !Engine.editor_hint):
						START_PIN = null
				
			pos[i] = startPos
			posOld[i] = startPos
		
		elif (i == nodeCount - 1):
			var endPos = get_global_position() + Vector2(400, 0)
			if (END_PIN != null):
				endPos = END_PIN.get_global_position()
				if (END_PIN_REF_ONLY && !Engine.editor_hint):
					END_PIN = null
				
			pos[nodeCount - 1] = endPos
			posOld[nodeCount - 1] = endPos
		
		else:
			pos[i] = position + Vector2(CONSTRAIN *i, 0) + pos[0]
			posOld[i] = position + Vector2(CONSTRAIN *i, 0) + posOld[0]
			
			
		
		position = Vector2.ZERO
	
	
	
#supposedly need to to this instead of _process in order for move_and_slide
#to work alright, but I didn't really notice a difference with just _proccess
func _physics_process(delta):
	if !readyDone || parentLinkCable != null:
		return
	
	#execute in editor if activeInEditor (will execute in game regardless)
	if Engine.editor_hint && !activeInEditor:
		return
	
	var prevPos = pos
	var prevPosOld = posOld
	
	#for i in range (extraRenderingSprites.size()):
	#	remove_child(extraRenderingSprites[i])
	
	#extraRenderingSprites.resize(0)
	
	
	update_points(delta)
	
	for i in range(ROPE_TAUGHTNESS):
		update_distance(delta)
	
	
	if (getRopeLength() > CABLE_LENGTH):
		pos = prevPos
		posOld = prevPosOld
		
		for i in range(nodeCount):
			setCNPos(i, pos[i])
	
	
	
	#addExtraSprites()
	
	
	renderLines()
	#if childLinkCable != null || parentLinkCable != null:
		#print(setgetTotalCableStartPlugPin(true, true))
		#print(setgetTotalCableEndPlugPin(true, true))
		#print(setgetTotalCableStartPlugPin(true, true) == setgetTotalCableEndPlugPin(true, true))
	#attemptCableConnection(true)
	#attemptCableConnection(false)
func getRopeLength():
	var length = 0
	for i in range(nodeCount-1):
		length += getCNPos(i).distance_to(getCNPos(i+1))
	return length
	


func update_points(delta):
	
	for i in range (nodeCount):
		
		if (i == 0 && setgetTotalCableStartPlugPin(true, true) != null):
			pos[0] = setgetTotalCableStartPlugPin(true, true).get_global_position()
			posOld[0] = setgetTotalCableStartPlugPin(true, true).get_global_position()
			continue
			
		if (i==nodeCount-1 && setgetTotalCableEndPlugPin(true, true) != null):
			pos[nodeCount -1] = setgetTotalCableEndPlugPin(true, true).get_global_position()
			posOld[nodeCount -1] = setgetTotalCableEndPlugPin(true, true).get_global_position()
			continue
	
	
		#var dist = getCNPos(i).distance_to(getCNPos(i+1))
		#var acc = dist/ROT_DIST_THRESHOLD
		#if (acc > 1-FRICTON):
		#	acc = 1-FRICTON
	
		var vec2 = (pos[i] - posOld[i]) * (FRICTON) #+ acc)
		posOld[i] = pos[i]
		pos[i] += vec2 + (GRAVITY * delta)

func update_distance(delta):
	
	for i in range (nodeCount):
		if i == nodeCount-1:
			applyRotation(i)
			return
			
		var distance = pos[i].distance_to(pos[i+1])
		if (distance == 0):
			distance = 0.0001
		var difference = CONSTRAIN - distance
		var percent = difference / distance
		var vec2 = pos[i+1] - pos[i]
		
		if i == 0:
			if setgetTotalCableStartPlugPin(true, true) != null:
				pos[i+1] += vec2 * percent
				applyRotation(i)
				#continue
			else:
				pos[i] -= vec2 * (percent/2)
				pos[i+1] += vec2 * (percent/2)
		else:
			if i+1 == nodeCount-1 && setgetTotalCableEndPlugPin(true, true) != null:
				pos[i] -= vec2 * percent
			else:
				pos[i] -= vec2 * (percent/2)
				pos[i+1] += vec2 * (percent/2)
				
		applyCollisionRestraint(i, delta)
				
	
	
func applyCollisionRestraint(i, delta):
	
	applyRotation(i)
	
	var target = pos[i]
	var ogPos = getCNPos(i)
	#if ((target - ogPos) != Vector2(0, 0)):
	var dir = (target - ogPos).normalized()
	cableNodes[i].move_and_slide((target-ogPos)/delta, Vector2( 0, 0 ), false, 16)
	

	
	var target2 = pos[i+1]
	var ogPos2 = getCNPos(i+1)
	#if ((target2 - ogPos2) != Vector2(0, 0)):
	var dir2 = (target2 - ogPos2).normalized()
	cableNodes[i+1].move_and_slide((target2-ogPos2)/delta)
	
	pos[i] = getCNPos(i)
	pos[i+1] = getCNPos(i+1)
	
func applyRotation(i):
	if (i == 0):
		if (setgetTotalCableStartPlugPin(true, true) == null):
			cableNodes[i].look_at(getCNPos(i+1))
		return
	
	if (i == nodeCount-1):
		if (setgetTotalCableEndPlugPin(true, true) == null):
			cableNodes[i].look_at(getCNPos(i-1))
		return
	
	var dist = getCNPos(i-1).distance_to(getCNPos(i+1))
	var prevDifVec = getCNPos(i) - getCNPos(i-1)
	var nextDifVec = getCNPos(i+1) - getCNPos(i)
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
	for cn in cableNodePosDict.keys():
		cn.CABLE_LINE2D.points = []
		
		if (cn.DRAW_CABLE_LINE2D && cn.CABLE_LINE2D_PATH != null):
			var pnts = []
			for cableNode in cableNodePosDict[cn]:
				pnts.append(cableNode.get_global_position())
			cn.CABLE_LINE2D.points = pnts
		else:
			cn.CABLE_LINE2D.points = []
			
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
#left over function from original code I got for nodeCount
#func get_count(distance: float):
#	var new_count = ceil(distance / CONSTRAIN)
#	return distance
func setFixPlug(plug):
	var newVect = plug.get_global_position()
	var isStartPlug = START_PLUG == plug
			
	if (isStartPlug):
		cableNodes[0].set_global_position(newVect)
		plug.set_global_position(newVect)
	else:
		cableNodes[cableNodes.size()-1].set_global_position(newVect)
		plug.set_global_position(newVect)



func addCableChainChild(cableNode):
	for individualCableChain in getUltimateParentCable().cableNodePosDict.keys():
		individualCableChain.addCableChild(cableNode)


func addCableChild(cableNode):
	print("addCableChild")
	cableNode.parentLinkCable = self
	childLinkCable = cableNode
	
	print(parentLinkCable)
	print(childLinkCable)
	#var ultimatePLC = getUltimateParentCable()
	
	#cableNodePosDict[cableNode] = []
	for cnKey in cableNode.cableNodePosDict.keys():
		cableNodePosDict[cnKey] = (cableNode.cableNodePosDict[cnKey])
	
	#change this to get th
	
	if START_PLUG.connPlug == cableNode.END_PLUG:
		print("opt 1")
		#flip both
		childLinkCableIsStart = true
		cableNode.parentLinkCableIsStart = false
		
		headCable = cableNode
		
		#setgetTotalCableStartPlugPin(true, false, null, true)
		START_PIN = null
		cableNode.END_PIN = null
		print(cableNode.pos[0])
		invertArrays(true, cableNode)
		#invertPoolVectorArray(cableNode)
		#print(cableNode.cableNodes[0])
		appendCableNode(cableNode)
		#cableNode.pos.invert()
		#cableNode.posOld.invert()
		#cableNode.cableNodes.invert()
			
		invertArrays(true, cableNode)
		
		print(pos[0])
		#print(cableNode.cableNodes[0].get_global_position())
		
	elif START_PLUG.connPlug == cableNode.START_PLUG:
		print("opt 2")
		#flip this
		childLinkCableIsStart = true
		cableNode.parentLinkCableIsStart = true
		
		headCable = cableNode
		
		#setgetTotalCableStartPlugPin(true, false, null, true)
		START_PIN = null
		cableNode.START_PIN = null
		
		invertArrays(true)
		
		appendCableNode(cableNode)
			
		invertArrays(true)
	
	elif END_PLUG.connPlug == cableNode.END_PLUG:
		print("opt 3")
		#flip cableNode
		childLinkCableIsStart = false
		cableNode.parentLinkCableIsStart = false
		
		footCable = cableNode
		
		#setgetTotalCableEndPlugPin(true, false, null, true)
		END_PIN = null
		cableNode.END_PIN = null
		
		invertArrays(false, cableNode)
		
		appendCableNode(cableNode)
		#cableNode.pos.invert()
		#cableNode.posOld.invert()
		#cableNode.cableNodes.invert()
		invertArrays(false, cableNode)
		
		
	elif END_PLUG.connPlug == cableNode.START_PLUG:
		print("opt 4")
		#dont flip
		childLinkCableIsStart = false
		cableNode.parentLinkCableIsStart = true
		
		footCable = cableNode
		
		#setgetTotalCableEndPlugPin(true, false, null, true)
		END_PIN = null
		cableNode.START_PIN = null
		
		appendCableNode(cableNode)
		
	nodeCount = cableNodes.size()
	
func getUltimateParentCable():
	if parentLinkCable != null:
		return parentLinkCable.getUltimateParentCable()
	return self
	
	
func invertArrays(invertSelf, cableNode = null):
	
	print("invertArrays")
	if (invertSelf):
		#pos.invert()
		#posOld.invert()
		invertPoolVector2Arrays(self)
		cableNodes.invert()
	
	if (cableNode != null):
		#cableNode.pos.invert()
		#cableNode.posOld.invert()
		invertPoolVector2Arrays(cableNode)
		cableNode.cableNodes.invert()
		
		
#for what ever reason, invert() does not work on poolVector2Arrays, made my own
func invertPoolVector2Arrays(cableN):
	var ogPool = cableN.pos
	var ogPool2 = cableN.posOld
	for i in ogPool.size():
		cableN.pos[i] = ogPool[ogPool.size() - 1 - i]
		
	for i in ogPool2.size():
		cableN.posOld[i] = ogPool2[ogPool2.size() - 1 - i] 



func appendCableNode(cableNode):
	#var ultimatePLC = getUltimateParentCable()
	
	print("appendCableNode")
	for i in cableNode.pos.size():
		if i == 0: continue
		pos.append(cableNode.pos[i])
			
	for j in cableNode.posOld.size():
		if j == 0: continue
		posOld.append(cableNode.posOld[j])
		
	for k in cableNode.cableNodes.size():
		if k == 0:
			newChild = cableNode.cableNodes[k]
			cableNode.remove_child(cableNode.cableNodes[k])
			parNode = cableNodes[cableNodes.size() - 1]
			#newChild.set_global_position(parNode.get_global_position())
			parNode.add_child(newChild)
			newChild.set_position(Vector2(0, 0))
			continue
		cableNodes.append(cableNode.cableNodes[k])
	


#below are two functions that are custom getters and setters for the plugs or pins
#which are needed inorder to get the correct plug or pin when cables are connected
#need to optimize using this in process in the cables so it only sets a new plug or pin
#for the overall cable when things connect or disconnect
func setgetTotalCableStartPlugPin(getPin, getter, val = null, forceThisAsHead = false):
	
	var head = headCable
	
	if forceThisAsHead:
		head = self
	
	if head.childLinkCableIsStart != null:
		if getter:
			if getPin:
				return head.END_PIN if head.childLinkCableIsStart else head.START_PIN
			else: return head.END_PLUG if head.childLinkCableIsStart else head.START_PIN 
		else:
			if getPin:
				if head.childLinkCableIsStart:
					head.END_PIN = val
				else: head.START_PIN = val
				return
			else:
				if head.childLinkCableIsStart:
					head.END_PLUG = val
				else: head.START_PLUG = val
				return
				
	if head.parentLinkCableIsStart != null:
		if getter:
			if getPin:
				return head.END_PIN if head.parentLinkCableIsStart else head.START_PIN
			else: return head.END_PLUG if head.parentLinkCableIsStart else head.START_PIN 
		else:
			if getPin:
				if head.parentLinkCableIsStart:
					head.END_PIN = val
				else: head.START_PIN = val
				return
			else:
				if head.parentLinkCableIsStart:
					head.END_PLUG = val
				else: head.START_PLUG = val
				return
				
	# if only one cable entire cable chain, just get the start pin/plug
	if getter:
		if getPin: return head.START_PIN
		else: return head.START_PLUG
		
	else:
		if getPin: head.START_PIN = val
		else: head.START_PLUG = val
	
	
func setgetTotalCableEndPlugPin(getPin, getter, val = null, forceThisAsHead = false):
	
	var foot = footCable
	
	if forceThisAsHead:
		foot = self
	
	if foot.childLinkCableIsStart != null:
		if getter:
			if getPin:
				return foot.END_PIN if foot.childLinkCableIsStart else foot.START_PIN
			else: return foot.END_PLUG if foot.childLinkCableIsStart else foot.START_PIN 
		else:
			if getPin:
				if foot.childLinkCableIsStart:
					foot.END_PIN = val
				else: foot.START_PIN = val
				return
			else:
				if foot.childLinkCableIsStart:
					foot.END_PLUG = val
				else: foot.START_PLUG = val
				return
				
	if foot.parentLinkCableIsStart != null:
		if getter:
			if getPin:
				return foot.END_PIN if foot.parentLinkCableIsStart else foot.START_PIN
			else: return foot.END_PLUG if foot.parentLinkCableIsStart else foot.START_PIN 
		else:
			if getPin:
				if foot.parentLinkCableIsStart:
					foot.END_PIN = val
				else: foot.START_PIN = val
				return
			else:
				if foot.parentLinkCableIsStart:
					foot.END_PLUG = val
				else: foot.START_PLUG = val
				return
				
	# if only one cable entire cable chain, just get the end pin/plug
	if getter:
		if getPin: return foot.END_PIN
		else: return foot.END_PLUG
		
	else:
		if getPin: foot.END_PIN = val
		else: foot.END_PLUG = val
	
	
func getUltimateChildCable():
	if childLinkCable != null:
		return childLinkCable.getUltimateChildCable()
		
	return self
	
func removeChildCable():
	#var ultimatePLC = getUltimateParentCable()
	
	print("removedChildCable")
	var blah = newChild.get_global_position()
	parNode.remove_child(newChild)
	newChild.set_global_position(blah)
	childLinkCable.add_child(newChild)
		
	parNode = null
	newChild = null
	
	
	for i in childLinkCable.cableNodes.size():
		
		if childLinkCable.parentLinkCableIsStart:
			if i == 0: continue
		else:
			if i == childLinkCable.pos.size() - 1: continue
			
		for ii in pos.size():
			if pos[ii] == childLinkCable.cableNodes[i].get_global_position():
				pos.remove(ii)
				posOld.remove(ii)
				break
			
#	for j in childLinkCable.cableNodes.size():
#
#		if childLinkCable.parentLinkCableIsStart:
#			if j == 0: continue
#		else:
#			if j == childLinkCable.posOld.size() - 1: continue
#
#
#		for jj in posOld.size():
#			if posOld[jj] == childLinkCable.cableNodes[j].get_global_position():
#				posOld.remove(jj)
#				break
		
	for k in childLinkCable.cableNodes.size():
		
		if childLinkCable.parentLinkCableIsStart:
			if k == 0: continue
		else:
			if k == childLinkCable.cableNodes.size() - 1: continue
		
		for kk in cableNodes.size():
			if cableNodes[kk] == childLinkCable.cableNodes[k]:
				cableNodes.remove(kk)
				break
				
	#minus 1 here because they shared one point when they were connected
	#(aka, if each was OG 60 nodes, connected total was 119)
	nodeCount -= childLinkCable.cableNodes.size() - 1
	
	for cnKey in childLinkCable.cableNodePosDict.keys():
		cableNodePosDict.erase(cnKey)
				
	for i in childLinkCable.cableNodes.size():
		childLinkCable.pos[i] = childLinkCable.cableNodes[i].get_global_position()
		childLinkCable.posOld[i] = childLinkCable.cableNodes[i].get_global_position()
				
	if (childLinkCableIsStart):
		START_PIN = null
	else:
		END_PIN = null
		
	if (childLinkCable.parentLinkCableIsStart):
		childLinkCable.START_PIN = null
	else:
		childLinkCable.END_PIN = null
	
	headCable = redefineHeadCable()
	footCable = redefineFootCable()
	
	childLinkCable.headCable = childLinkCable.redefineHeadCable()
	childLinkCable.footCable = childLinkCable.redefineFootCable()
	
	childLinkCable.parentLinkCableIsStart = null
	childLinkCable.parentLinkCable = null
	childLinkCableIsStart = null
	childLinkCable = null
		
func redefineHeadCable():
	var posToCompare = pos[0]
	
	for c in cableNodePosDict.keys():
		for i in c.pos.size():
			if posToCompare == c.cableNodes[i].get_global_position():
				#headCable = c
				return c
				
func redefineFootCable():
	var posToCompare = pos[pos.size() - 1]
	
	for c in cableNodePosDict.keys():
		for i in c.cableNodes.size():
			if posToCompare == c.cableNodes[i].get_global_position():
				#footCable = c
				return c
	
