tool
extends Node2D

export (PackedScene) var CABLE_NODE = null#preload("res://cablePoint.tscn")
export (PackedScene) var CABLE_NODE_SPRITE = null#preload("res://cablePointSprite.tscn")
export (NodePath) var START_PIN_PATH = null
var START_PIN = null
export (NodePath) var END_PIN_PATH = null
var END_PIN = null

export (Resource) var START_PLUG = null
export (Resource) var END_PLUG = null

export (bool) var DRAW_CABLE_LINE2D = false
export (NodePath) var CABLE_LINE2D_PATH = null
var CABLE_LINE2D = null

var START_SPRITE = null
var END_SPRITE = null

export (int, 1, 10, 1) var ROPE_TAUGHTNESS = 1
export (int) var NODE_COUNT = 60
export (float) var CONSTRAIN = 10
export (float) var EXTRA_SPRITE_THRESHOLD = 35
export (float) var CABLE_LENGTH = 4000
export (Vector2) var GRAVITY = Vector2(0,9.8)
export (float, 0.6, 1.0, 0.01) var FRICTON = 0.95
export (float) var ROT_DIST_THRESHOLD = 28

export (bool) var reloadEditorCable = false setget reload
export (bool) var activeInEditor = false setget activateEditor


var extraRenderingSprites = []
var pos: PoolVector2Array
var posOld: PoolVector2Array
var cableNodes = []

var startArea = null
var endArea = null

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
	startArea = get_node("startPinArea")
	endArea = get_node("endPinArea")
		
	if (self.get_children().size() > 0):
		for n in self.get_children():
			if n != startArea && n != endArea && n != CABLE_LINE2D:
				self.remove_child(n)

func _ready():
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
	
		
	
func initShapes():
	for n in range(NODE_COUNT):
		cableNodes.append(CABLE_NODE.instance())
		cableNodes[n].setCableNodeSprite(CABLE_NODE_SPRITE)
		#need to add child to make active
		add_child(cableNodes[n])
		setCNPos(n, pos[n])
		
		
		if (n == 0):
			if START_PLUG != null:
				if START_PLUG.plugSprite != null:
					print(START_PLUG.plugSprite)
					START_SPRITE = Sprite.new()
					START_SPRITE.set_texture(START_PLUG.plugSprite)
					START_SPRITE.set_scale(Vector2(4, 4))
					cableNodes[n].add_child(START_SPRITE)
			
		if (n == NODE_COUNT - 1):
			if END_PLUG != null:
				if END_PLUG.plugSprite != null:
					
					END_SPRITE = Sprite.new()
					END_SPRITE.set_texture(END_PLUG.plugSprite)
					#END_SPRITE.set_flip_h(true)
					END_SPRITE.set_scale(Vector2(4, 4))
					cableNodes[n].add_child(END_SPRITE)
		
	#prevent parts of cable from colliding with eachother
	for n in range (NODE_COUNT):
		for k in range (NODE_COUNT):
			if (n == k):
				pass
			cableNodes[n].add_collision_exception_with(cableNodes[k])
		if (START_PIN_PATH != null):
			if (START_PIN is PhysicsBody2D):
				cableNodes[n].add_collision_exception_with(START_PIN)
			
		if (END_PIN_PATH != null):
				if (END_PIN is PhysicsBody2D):
					cableNodes[n].add_collision_exception_with(END_PIN)	
	
	
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
			if (START_PIN_PATH != null):
				startPos = START_PIN.get_global_position()
				
			pos[i] = startPos
			posOld[i] = startPos
		
		elif (i == NODE_COUNT - 1):
			var endPos = get_global_position() + Vector2(400, 0)
			if (END_PIN_PATH != null):
				endPos = END_PIN.get_global_position()
				
			pos[NODE_COUNT - 1] = endPos
			posOld[NODE_COUNT - 1] = endPos
		
		else:
			pos[i] = position + Vector2(CONSTRAIN *i, 0) + pos[0]
			posOld[i] = position + Vector2(CONSTRAIN *i, 0) + posOld[0]
			
			
		startArea.set_global_position(pos[i])
		endArea.set_global_position(pos[NODE_COUNT-1])
		
		position = Vector2.ZERO
	
	
#supposedly need to to this instead of _process in order for move_and_slide
#to work alright, but I didn't really notice a difference with just _proccess
func _physics_process(delta):
	#execute in editor if activeInEditor (will execute in game regardless)
	if Engine.editor_hint && !activeInEditor:
		return
	
	var prevPos = pos
	var prevPosOld = posOld
	
	for i in range (extraRenderingSprites.size()):
		remove_child(extraRenderingSprites[i])
	
	extraRenderingSprites.resize(0)
	
	
	update_points(delta)
	
	for i in range(ROPE_TAUGHTNESS):
		update_distance(delta)
	
	updateAreaNodes()
	
	if (getRopeLength() > CABLE_LENGTH):
		pos = prevPos
		posOld = prevPosOld
		
		for i in range(NODE_COUNT):
			setCNPos(i, pos[i])
	
	
	addExtraSprites()
	
	
	if (DRAW_CABLE_LINE2D && CABLE_LINE2D_PATH != null):
		CABLE_LINE2D.points = pos
	else:
		CABLE_LINE2D = []

func getRopeLength():
	var length = 0
	for i in range(NODE_COUNT-1):
		length += getCNPos(i).distance_to(getCNPos(i+1))
	return length
	


func update_points(delta):
	
	for i in range (NODE_COUNT):
		
		if (i == 0 && START_PIN_PATH != null):
			pos[0] = START_PIN.get_global_position()
			posOld[0] = START_PIN.get_global_position()
			continue
			
		if (i==NODE_COUNT-1 && END_PIN_PATH != null):
			pos[NODE_COUNT -1] = END_PIN.get_global_position()
			posOld[NODE_COUNT -1] = END_PIN.get_global_position()
			continue
	
	
		#var dist = getCNPos(i).distance_to(getCNPos(i+1))
		#var acc = dist/ROT_DIST_THRESHOLD
		#if (acc > 1-FRICTON):
		#	acc = 1-FRICTON
	
		var vec2 = (pos[i] - posOld[i]) * (FRICTON) #+ acc)
		posOld[i] = pos[i]
		pos[i] += vec2 + (GRAVITY * delta)

func update_distance(delta):
	
	for i in range (NODE_COUNT):
		if i == NODE_COUNT-1:
			applyRotation(i)
			return
			
		var distance = pos[i].distance_to(pos[i+1])
		if (distance == 0):
			distance = 0.0001
		var difference = CONSTRAIN - distance
		var percent = difference / distance
		var vec2 = pos[i+1] - pos[i]
		
		if i == 0:
			if START_PIN_PATH != null:
				pos[i+1] += vec2 * percent
			else:
				pos[i] -= vec2 * (percent/2)
				pos[i+1] += vec2 * (percent/2)
		elif i == NODE_COUNT-1:
			pass
		else:
			if i+1 == NODE_COUNT-1 && END_PIN_PATH != null:
				pos[i] -= vec2 * percent
			else:
				
				
				pos[i] -= vec2 * (percent/2)
				pos[i+1] += vec2 * (percent/2)
				
		applyCollisionRestraint(i, delta)
				
	
	
func applyCollisionRestraint(i, delta):
	
	
	applyRotation(i)
	
	var target = pos[i]
	var ogPos = getCNPos(i)
	var dir = (target - ogPos).normalized()
	cableNodes[i].move_and_slide((target-ogPos)/delta, Vector2( 0, 0 ), false, 16)
	

	
	var target2 = pos[i+1]
	var ogPos2 = getCNPos(i+1)
	var dir2 = (target2 - ogPos2).normalized()
	cableNodes[i+1].move_and_slide((target2-ogPos2)/delta)
	
	pos[i] = getCNPos(i)
	pos[i+1] = getCNPos(i+1)
	
func applyRotation(i):
	if (i == 0):
		cableNodes[i].look_at(getCNPos(i+1))
		return
	
	if (i == NODE_COUNT-1):
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
	
	
func updateAreaNodes():
	startArea.set_global_position(pos[0])
	endArea.set_global_position(pos[NODE_COUNT-1])
		
func addExtraSprites():
	# adds a sprite in between nodes if they are more than EXTRA_SPRITE_THRESHHOLD apart
	for i in range (NODE_COUNT-1):
		var dist = getCNPos(i).distance_to(getCNPos(i+1))
		if dist > EXTRA_SPRITE_THRESHOLD:
			var avgPos = (getCNPos(i) + getCNPos(i+1))/2
			var sprite = CABLE_NODE_SPRITE.instance()
			add_child(sprite)
			sprite.set_global_position(avgPos)
			
			var avgRot = (cableNodes[i].get_rotation() + cableNodes[i+1].get_rotation())/2
			
			
			
			var acc = dist/ROT_DIST_THRESHOLD
			if (acc > 1):
				acc = 1
			
			sprite.set_rotation(avgRot * acc)
			extraRenderingSprites.append(sprite)
			
		#adjust node's sprite so that they wrap around curves a bit nicer:
		if (i != 0):
			var middlePos = (getCNPos(i-1) + getCNPos(i+1))/2
			middlePos = (middlePos + getCNPos(i))/2
			
			cableNodes[i].SPRITE.set_global_position(middlePos)
			
			
#this part is still in progress
func attemptCableConnection(startPlug, plugPinPath, conn):
	var plug = START_PLUG if startPlug else END_PLUG
	plug.connPlug = conn
	
	if plug.connPlug != null:
		if startPlug:
			pass
			
	
			
			
#left over function from original code I got for NODE_COUNT
#func get_count(distance: float):
#	var new_count = ceil(distance / CONSTRAIN)
#	return distance
