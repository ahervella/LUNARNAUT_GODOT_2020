extends Node2D

var earthNode = preload("res://ropePoint.tscn")
export (float) var length = 30
export (float) var constrain = 1
export (Vector2) var gravity = Vector2(0,9.8)
export (float) var friction = 0.9
export (bool) var start_pin = true
export (bool) var end_pin = true

var blah = 0

var pos: PoolVector2Array
var pos_ex: PoolVector2Array
var earthImg = []
var earthImgSpeed = []
var joints = []
var count: int
const speed = 5000
var mousePos
func _ready():
	count = get_count(length)
	resize_arrays()
	
	for n in range(count):
		earthImg.append(earthNode.instance())
		earthImgSpeed.append(speed)
		
		add_child(earthImg[n])
		
	for n in range (count):
		for k in range (count):
			if (n == k):
				pass
			earthImg[n].add_collision_exception_with(earthImg[k])
			
		earthImg[n].add_collision_exception_with(get_node("/root/Node/astro"))
		
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

func resize_arrays():
	#print(count)
	pos.resize(count)
	pos_ex.resize(count)

func init_position():
	
	for i in range(count):
		if (i == 0):
			pos[i] = get_node("/root/Node/PROTO_BLOCK_CORN").get_global_position() + Vector2(0, -200)
			pos_ex[i] = get_node("/root/Node/PROTO_BLOCK_CORN").get_global_position() + Vector2(0, -200)
		else:
			pos[i] = position + Vector2(constrain *i, 0)
			pos_ex[i] = position + Vector2(constrain *i, 0)
			earthImg[i].set_global_position(pos[i])
		position = Vector2.ZERO
	

func _process(delta):
	#for n in range(count):
	#	earthImg[n].position.x = 1
	
	if Input.is_action_pressed("click"):	#Move start point
		pos[0] = get_global_mouse_position()
		pos_ex[0] = get_global_mouse_position()
		#find the best feel length ratio
		#print("length ratio to distance ",length/pos[count-1].distance_to(pos[0]))
	if Input.is_action_pressed("right_click"):	#Move start point
		mousePos = get_global_mouse_position()
		
		
		if (getRopeLength() > 500): #&& Input.is_action_pressed("right_click")):
				#var mousePos = get_global_mouse_position()
			mousePos = (mousePos-pos[count-1]).normalized() * 500 + pos[count -1]
		pos[count-1] = mousePos
			#print (get_global_mouse_position())
		pos_ex[count-1] = mousePos
		
	else:
		pos[count-1] = get_node("/root/Node/astro").get_global_position()
		pos_ex[count-1] = get_node("/root/Node/astro").get_global_position()
		
	update_points(delta)
	update_distance()
	
	print(getRopeLength())
	
	#update_distance()	#Repeat to get tighter rope
	#update_distance()
	$Line2D.points = pos

func getRopeLength():
	var length = 0
	for i in range(count-1):
		length += earthImg[i].get_global_position().distance_to(earthImg[i+1].get_global_position())
	return length

func update_points(delta):
	blah += 1
	
	for i in range (count):
		# not first and last || first if not pinned || last if not pinned
		if (i!=0 && i!=count-1) || (i==0 && !start_pin) || (i==count-1 && !end_pin):
			var vec2 = (pos[i] - pos_ex[i]) * friction
			#print(vec2)
			pos_ex[i] = pos[i]
			pos[i] += vec2 + (gravity * delta)
		#if (i < count):
			
			var target = pos[i]
			var positionb = earthImg[i].get_global_position()
			var dir = (target - positionb).normalized()
			#var move_amount = Vector2(move_toward(positionb.x, target.x, dir.x * speed  * delta), move_toward(positionb.y, target.y, dir.y * speed * delta))
			#var moveVel = move_vel(positionb, target, i)
			var newVec = earthImg[i].move_and_slide((target-positionb)/delta) # or move_and_slide(move_amount / delta)
			
			var newPoint = positionb + newVec
			
			if blah > 100 && newPoint != earthImg[i].get_global_position():
				print(" ")
				print (positionb)
				print(earthImg[i].get_global_position())
				print (newPoint)
				print(target)
				print(" ")
				pos[i] = earthImg[i].get_global_position()
			
				
				#earthImg[i].move_and_slide(pos[i+1] + pos[i])
		
#
#
#func move_vel(orig : Vector2, target : Vector2, index : int):
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

func update_distance():
	for i in range(count):
		if i == count-1:
			return
		var distance = pos[i].distance_to(pos[i+1])
		#clamp(distance, -10, 10)
		var difference = constrain - distance
		var percent = difference / distance
		var vec2 = pos[i+1] - pos[i]
		if i == 0:
			if start_pin:
				pos[i+1] += vec2 * percent
			else:
				pos[i] -= vec2 * (percent/2)
				pos[i+1] += vec2 * (percent/2)
		elif i == count-1:
			pass
		else:
			if i+1 == count-1 && end_pin:
				pos[i] -= vec2 * percent
			else:
				pos[i] -= vec2 * (percent/2)
				pos[i+1] += vec2 * (percent/2)
