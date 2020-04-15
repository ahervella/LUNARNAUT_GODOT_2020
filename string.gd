extends Node2D

var earthNode = preload("res://ropePoint.tscn")
export (float) var length = 30
export (float) var constrain = 1
export (Vector2) var gravity = Vector2(0,9.8)
export (float) var friction = 0.9
export (bool) var start_pin = true
export (bool) var end_pin = true

#var pos: PoolVector2Array
#var pos_ex: PoolVector2Array
var nodes = []
var nodesSpeed = []
#var earthImg = []
#var earthImgSpeed = []
var stringCounts = []
var strings = []
var strings_ex = []

var countt: int
const speed = 5000
var mousePos
func _ready():
	countt = get_count(length)
	resize_arrays()
	
	var earthImg = []
	var earthImgSpeed = []
	for n in range(countt):
		
		earthImg.append(earthNode.instance())
		earthImgSpeed.append(speed)
		
		add_child(earthImg[n])
		
	nodes.append(earthImg)
	nodesSpeed.append(earthImgSpeed)
		
	for n in range (countt):
		for k in range (countt):
			if (n == k):
				pass
			nodes[0][n].add_collision_exception_with(nodes[0][k])
			
		nodes[0][n].add_collision_exception_with(get_node("/root/Node/astro"))
		
		if (n != countt -1):
			nodes[0][n].get_node("PinJoint2D").node_b = nodes[0][n+1].get_path()
#		earthImg[n].set_global_position(Vector2(1000, 100 + 20 * n))
#
	
#
#		if (n> 0):
#			joints[n-1].node_b = earthImg[n].get_path()
#
#		if (n != count-1):
#			var joint = PinJoint2D.new()
#			#joint.position = earthImg[n].get_global_position() + Vector2(0, 5)
#			joints.append(joint)
#			#joint.position = earthImg[n].get_global_position() + Vector2(0, 5)
#			earthImg[n].add_child(joint)
#			joint.node_a = earthImg[n].get_path()
	
	init_position()
	
	
		
	
func get_count(distance: float):
	var new_count = ceil(distance / constrain)
	return new_count
	
func getPos(index):
	return strings[index]
	
func getPosEx(index):
	return strings_ex[index]
	
func setPos(indexString, indexPos, val):
	strings[indexString][indexPos] = val
	
func setPosEx(indexString, indexPos, val):
	strings_ex[indexString][indexPos] = val

func getNodes(indexString):
	return nodes[indexString]

func setNodes(indexString, indexPos, val):
	nodes[indexString][indexPos] = val
	
func getNodesSpeed(indexString):
	nodesSpeed[indexString]
	
func setNodesSpeed(indexString, indexPos, val):
	nodesSpeed[indexString][indexPos] = val

func resize_arrays():
	#print(count)
	var pos: PoolVector2Array
	var pos_ex: PoolVector2Array
	
	pos.resize(countt)
	pos_ex.resize(countt)
	
	strings.append(pos)
	strings_ex.append(pos_ex)
	stringCounts.append(countt)

func init_position():
	
	for i in range(countt):
		if (i == 0):
			setPos(0, i, get_node("/root/Node/PROTO_BLOCK_CORN").get_global_position() + Vector2(0, -200))
			setPosEx(0, i, get_node("/root/Node/PROTO_BLOCK_CORN").get_global_position() + Vector2(0, -200))
		else:
			setPos(0, i, position + Vector2(constrain *i, 0))
			setPosEx(0, i, position + Vector2(constrain *i, 0))
			getNodes(0)[i].set_global_position(getPos(0)[i])
	position = Vector2.ZERO
	

func _process(delta):
	
	$"Line2D".points = []
	$"Line2D2".points = []
	
	var totalPoints = 0
	
	for i in range (stringCounts.size()):
		_processEach(delta, i)
		
		totalPoints += stringCounts.size()
	
	
	for i in range (nodes.size()):
		for k in range (nodes[i].size()):
			if (nodes[i][k].get_slide_count() > 0):
				#var pos = earthImg[h].get_slide_collision(earthImg[h].get_slide_count()-1).position
				splitPoints(i, k)

func splitPoints(i, k):
	pass

func _processEach(delta, ind):
	
	var count = stringCounts[ind]
	#for n in range(count):
	#	earthImg[n].position.x = 1
	
	if Input.is_action_pressed("click"):	#Move start point
		setPos(ind, 0, get_global_mouse_position())
		setPosEx(ind, 0, get_global_mouse_position())
		#find the best feel length ratio
		#print("length ratio to distance ",length/pos[count-1].distance_to(pos[0]))
	if Input.is_action_pressed("right_click"):	#Move start point
		mousePos = get_global_mouse_position()
		
		
		if (getRopeLength() > 500): #&& Input.is_action_pressed("right_click")):
				#var mousePos = get_global_mouse_position()
			mousePos = (mousePos-getPos(ind)[count-1]).normalized() * 500 + getPos(ind)[count -1]
		setPos(ind, count-1,mousePos)
			#print (get_global_mouse_position())
		setPosEx(ind, count-1, mousePos)
		
	else:
		setPos(ind, count-1, get_node("/root/Node/astro").get_global_position())
		setPosEx(ind, count-1, get_node("/root/Node/astro").get_global_position())
		
	update_points(delta, ind)
	update_distance(ind)
	
	#print(getRopeLength())
	
	#update_distance()	#Repeat to get tighter rope
	#update_distance()
	$"Line2D".points += getPos(ind)
	$"Line2D2".points += getPosEx(ind)
	
	

func getRopeLength():
	
	var length = 0
	for i in range(nodes.size()):
		for k in range(nodes[i].size()):
			length += nodes[i][k].get_global_position().distance_to(nodes[i][k+1].get_global_position())
	return length

func update_points(delta, stringIndex):
	var count = stringCounts[stringIndex]
#
#
#	var totalBefore = 0
#	for i in range(strings.size() - (strings.size() - stringIndex)):
#		totalBefore += strings[i].size()
				
	
	for i in range (count):
		# not first and last || first if not pinned || last if not pinned
		if (i!=0 && i!=count-1) || (i==0 && !start_pin) || (i==count-1 && !end_pin):
			var vec2 = (getPos(stringIndex)[i] - getPosEx(stringIndex)[i]) * friction
			#print(vec2)
			setPosEx(stringIndex, i, getPos(stringIndex)[i])
			setPos(stringIndex, i, getPos(stringIndex)[i] + restrictPos(vec2 + (gravity * delta)))
			if (i < count):
				
				
				
				var target = getPos(stringIndex)[i]
				var positionb = getNodes(stringIndex)[i].get_global_position()
				var dir = (target - positionb).normalized()
				#var move_amount = Vector2(move_toward(positionb.x, target.x, dir.x * speed  * delta), move_toward(positionb.y, target.y, dir.y * speed * delta))
				#var moveVel = move_vel(positionb, target, i)
				
				var otherMoveVel = getNodes(stringIndex)[i].move_and_slide((target-positionb)/delta) # or move_and_slide(move_amount / delta)
#				return
#				if (i > 0):
#					if(earthImg[i].get_global_position().distance_to(earthImg[i-1].get_global_position()) > 50):
#						earthImg[i].move_and_slide(-otherMoveVel)
#						earthImg[i].move_and_slide(otherMoveVel.normalized())
		


#func move_vel(orig : Vector2, target : Vector2, index : int):
#
#
#	var dist = orig.distance_to(target)
#
#	if (abs (dist) < 150):
#		earthImgSpeed[index] =20 * (dist)#0.2 * pow(1.02, dist + 370) - 190#0.1 * pow(1.025, dist + 300) - 150#0.1 * pow(1.04, dist + 200) - 260# 0.1 * pow(1.04, dist + 160) - 50#1000 * pow(0.0415 * dist, 0.5)#50 * pow(1.025,dist) - 50
#
#	else:
#		earthImgSpeed[index] = 2000
#
#	if (abs (dist) > 1):
#		return (target - orig).normalized() * earthImgSpeed[index]
#	return Vector2.ZERO

func update_distance(stringIndex):
	var count = stringCounts[stringIndex]
	
	for i in range(count):
		if i == count-1:
			return
		var distance = getPos(stringIndex)[i].distance_to(getPos(stringIndex)[i+1])
		#clamp(distance, -10, 10)
		var difference = constrain - distance
		var percent = difference / distance
		var vec2 = getPos(stringIndex)[i+1] - getPos(stringIndex)[i]
		
		if i == 0:
			if start_pin:
				setPos(stringIndex, i+1, getPos(stringIndex)[i+1] + restrictPos(vec2 * percent))
			else:
				setPos(stringIndex, i,  getPos(stringIndex)[i] - restrictPos(vec2 * (percent/2)))
				setPos(stringIndex, i+1, getPos(stringIndex)[i+1] + restrictPos(vec2 * (percent/2)))
		elif i == count-1:
			pass
		else:
			if i+1 == count-1 && end_pin:
				setPos(stringIndex, i, getPos(stringIndex)[i] - restrictPos(vec2 * percent))
			else:
				setPos(stringIndex, i, getPos(stringIndex)[i] - restrictPos(vec2 * (percent/2)))
				setPos(stringIndex, i+1, getPos(stringIndex)[i+1] + restrictPos(vec2 * (percent/2)))

func restrictPos(vari):
	return vari
	
#	if pow(vari.x * vari.x + vari.y * vari.y, 0.5) > 10:
#		vari = vari.normalized() * 10
#	return vari
