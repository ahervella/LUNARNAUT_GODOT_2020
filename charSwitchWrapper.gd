tool
extends Resource

class_name CharacterSwitchingWrapper


var dependantCSWrappers = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var saveStartState = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var changesToApply = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}



export (NodePath) var node
export (bool) var staticNode = false
export (bool) var USA = true
#export (NodePath) var USA_relativeNode = null
export (bool) var RUS = true
#export (NodePath) var RUS_relativeNode = null
export (bool) var FRA = true
#export (NodePath) var FRA_relativeNode = null
export (bool) var CHN = true
#export (NodePath) var CHN_relativeNode = null
export (bool) var MAR = true
#export (NodePath) var MAR_relativeNode = null


func getDependantGroup():
	var groupArray = [self]
	
	for dependant in dependantCSWrappers[global.CharacterRes.id]:
		var dependantArray = dependant.getDependantGroup()
		for val in dependantArray:
			groupArray.append(val)
	return groupArray
	
func getFinalPosAfterCollisions2(node, totalChange, kBody, dependantGroup):
	
	if totalChange.length() < 5: return node.get_global_position()
	
	var kb = KinematicBody2D.new()
	
	global.lvl().add_child(kb)
	kb.set_global_position(node.get_global_position())
	
	var ogParents = {}
	var ogNodeAbove = {}
	
	var dependantGroupNodes = []
	
	for dp in dependantGroup:
		var dpNode = global.lvl().get_node(dp.node)
		
		dependantGroupNodes.append(dpNode)
		
		dp.changesToApply[global.CharacterRes.id][0] = null
		
		ogParents[dpNode] = (dpNode.get_parent())
		var nodeInd = dpNode.get_index() if dpNode.get_index() == 0 else dpNode.get_index()-1
		ogNodeAbove[dpNode] = dpNode.get_parent().get_child(nodeInd)
		
		
	
	for child in node.get_children():
		if child is CollisionShape2D:
			var globalPos = child.get_global_position()
			var dup = child.duplicate()
			kb.add_child(dup)
			dup.set_global_position(globalPos)
			break
	
	
	for rb in dependantGroupNodes:
		var thingy = rb
		var thingyPos = thingy.get_global_position()
		rb.get_parent().remove_child(rb)
		kb.add_child(thingy)
		thingy.set_global_position(thingyPos)
		
		
	for dgn in dependantGroupNodes:
		
		for child in dgn.get_children():
			if child is CollisionShape2D:
				kb.add_collision_exception_with(child)
		
		kb.add_collision_exception_with(dgn)
		for dgn2 in dependantGroupNodes:
			if dgn == dgn2: continue
			
#			for child in dgn.get_children():
#				if child is CollisionShape2D:
#					dgn2.add_collision_exception_with(child)
			
			dgn.add_collision_exception_with(dgn2)
		
	
	
	var totalHorzDistToTrav = totalChange.length()
	var overrideDir = null
	var step = 10
	
	#while there is still distance to cover, keep incrementing
	while totalHorzDistToTrav > 0:
		var collObj = overrideDir
		
		if collObj == null:
			#Kinematic bodies and move_and_collide have odd behaviors where
			#if the vector it is moving along is very long, the less accurate
			#it becomes in getting the object as close as possible
			#therefore, since there will always be ground somewhere, test at small values
			#and increment until it makes contact
			
			var multiplyer = 0
			while collObj == null:
				multiplyer += 100
				#kBodies[i].set_global_position(kBodies[i].get_global_position() - global.gravVect())
				kb.set_global_position(kb.get_global_position() - global.gravVect() * 2)
				#collObj[i] = kBodies[i].move_and_collide(global.gravVect() * multiplyer, false)
				collObj = kb.move_and_collide(global.gravVect() * multiplyer, false)
				#dependantGroupNodes[i].set_global_position(kBodies[i].get_global_position())
				
			
			#move the body slightly away from its point of contact so upong continuing its journey, it does
			#not detect and parallel collisions with the object it just collided
		#kBodies[k].set_global_position(kBodies[k].get_global_position() - (global.gravVect()*4* (k+1)) )#collObj[i].get_normal().normalized())
	
		kb.set_global_position(kb.get_global_position() - global.gravVect() * 2)
	
	
		var dirVect = collObj.get_normal().tangent()
		dirVect.x = abs(dirVect.x) if totalChange.x > 0 else abs(dirVect.x) * -1
	
		#the step is either 10 or whatever is remaining
		step = 10 if totalHorzDistToTrav > 10 else totalHorzDistToTrav
		
		for inx in dependantGroupNodes.size():
			if dependantGroupNodes[inx].test_motion(dirVect.normalized() * step, false):
				var blah = dependantGroupNodes[inx]
				var blahPos = blah.get_global_position()
				kb.remove_child(dependantGroupNodes[inx])
				
				var nodeAbove = findNodeAbove(dependantGroupNodes, ogNodeAbove, blah)
		
				ogParents[blah].add_child_below_node(nodeAbove, blah)#add_child(nd)
				if blah.get_owner() == null:
					blah.set_owner(ogParents[blah])
				#ogParents[blah].add_child(blah)
				blah.set_global_position(blahPos)
				
				if kb.get_child_count() == 1:
					closeShit(kb, ogNodeAbove, ogParents, dependantGroupNodes)
					return
		
		var collObj2 = kb.move_and_collide(dirVect.normalized() * step, false)
	

			
		#if the move parallel to its last move intersects again, then get the distance
		#traveled to subtract from the ground covered
		if collObj2 != null:
			
#			var testVect = collObj2.get_travel()
#
			
			#prevent object from moving up slopes greater than 30 degrees with respect to the
			#gravity angle
			var tanVector = collObj2.get_normal().rotated(-global.gravRadAngFromNorm)
			var totalAngle = 30
			if abs(tanVector.x) != 0:
				
				tanVector.y = abs(tanVector.y) if totalChange.x > 0 else -abs(tanVector.y)
				var atanVal = atan(tanVector.y / abs(tanVector.x))
				if atanVal > deg2rad(totalAngle):
					#return
					
					
					#undo this move if the angle is too great
					kb.set_global_position(kb.get_global_position() - collObj2.get_travel())
					kb.set_global_position(kb.get_global_position() + collObj2.get_normal().normalized())
					
					closeShit(kb, ogNodeAbove, ogParents, dependantGroupNodes)
					
					return
			
			
				var blah = collObj2.get_travel()
				
				#if k == 0:
					
				totalHorzDistToTrav -= blah.length()
			
		#didn't run into anything so subtract the step from the distance to cover still
		else:
				#if k == 0:
			totalHorzDistToTrav -= step
			
		overrideDir = collObj2
			
			
			
	
	closeShit(kb, ogNodeAbove, ogParents, dependantGroupNodes)
	
	

	
func closeShit(kb, ogNodeAbove, ogParents, dependantGroupNodes):
	for nddd in kb.get_children():
		#var nd = nddd
		var globalPos = nddd.get_global_position()
		kb.remove_child(nddd)
		if nddd is CollisionShape2D: continue
		
		var nodeAbove = findNodeAbove(dependantGroupNodes, ogNodeAbove, nddd)
				#check again!!!! and do same for when removing child above
		
		ogParents[nddd].add_child_below_node(nodeAbove, nddd)#add_child(nd)
		if nddd.get_owner() == null:
			nddd.set_owner(ogParents[nddd])
		nddd.set_global_position(globalPos)
		
	kb.free()
	
	for dgn in dependantGroupNodes:
		for dgn2 in dependantGroupNodes:
			if dgn == dgn2: continue
			dgn.remove_collision_exception_with(dgn2)
	
func findNodeAbove(dependantGroupNodes, ogNodeAbove, node):
	for dpNode in dependantGroupNodes:
		if ogNodeAbove[node] == dpNode:
			return findNodeAbove(dependantGroupNodes, ogNodeAbove, dpNode)
			
	return ogNodeAbove[node]
	
	
	
	
func getFinalPosAfterCollisions(node, nodeDim, currPos, newPos, collisionShape, groups = ["solid", "wall", "astro", "object"]):
	
	#var shapePointsArray =  getCollisionShapePoints(node, collisionShape)
	
	var totalChange = (newPos-currPos)
	if totalChange.length() < 10: return currPos
	var totalHorzDistToTrav = totalChange.length()
	var finalPos = Vector2(0, 0)
	var step = 10
	var overrideCollObj = null
	while totalHorzDistToTrav > 0:
		var collObj = overrideCollObj
		if collObj == null:
		#kBody.set_global_position(kBody.get_global_position() - global.gravVect())
			collObj = thingy(node, Vector2(0, 10000), groups, collisionShape, nodeDim)
			#collObj = kBody.move_and_collide(global.gravVect() * 1000)
			#kBody.set_global_position(kBody.get_global_position() - global.gravVect())
		#	if collObj.get_travel().y < 0 :
				#kBody.set_global_position(kBody.get_global_position() - collObj.get_travel())
		
		var dirVect = collObj[1].tangent() if collObj[1] != Vector2(0, 0) else Vector2(totalChange.x, 0)
		dirVect.x = abs(dirVect.x) if totalChange.x > 0 else abs(dirVect.x) * -1
		
		step = 10 if totalHorzDistToTrav > 10 else totalHorzDistToTrav
		var collObj2 = thingy(node, dirVect.normalized() * step, groups, collisionShape, nodeDim)
		#var collObj2 = kBody.move_and_collide(dirVect.normalized() * step)
		
		
		
		if collObj2 != null:
			#var blah = collObj2[2]
			overrideCollObj = collObj2
			
		
			totalHorzDistToTrav -= collObj2[2]
		else:
			totalHorzDistToTrav -= step
	
#	return shortestDistPoint
	
func thingy(node, newChangeVec, groups, collisionShape, nodeDim):
	var currPos = node.get_global_position()
	var shortestDist = newChangeVec.length()
	var shortestDistPoint = newChangeVec + currPos#newPos#(newPos-currPos).length()
	var shortestCollObj = null
	var shortestCollNormal = null
	var shapePointsArray = getPointsFromNode(collisionShape)
	for point in shapePointsArray:
		var ray = RayCast2D.new()
		node.add_child(ray)
		ray.set_global_position(point)
		ray.set_cast_to((newChangeVec))
		ray.set_enabled(true)
		ray.force_raycast_update()
		var globalPos = ray.get_global_position()
		var isColl = ray.is_colliding()
		var collObj = ray.get_collider()
		while collObj != null && !isObjectInGroups(groups, collObj):
			print("while loop in raycast")
			ray.add_exception(collObj)
			collObj = ray.get_collider()
		
		
		if collObj != null:
			var rayCollPoint = ray.get_collision_point()
			var collPoint = rayCollPoint - ray.get_global_position()
			var modifier = collPoint.length() if collPoint.length() < 1 else 1
			var newPosObj = collPoint - (collPoint.normalized()*modifier * nodeDim/2)
			if collPoint == Vector2(0, 0): newPosObj = Vector2(0, 0)
			
			var dis = collPoint.length()
			var collNormal = ray.get_collision_normal()
			if (dis < shortestDist):
				shortestDist = dis
				shortestDistPoint = newPosObj + node.get_global_position()
				shortestCollObj = collObj
				shortestCollNormal = collNormal
				
		
		node.remove_child(ray)
		ray.free()
		
		node.set_global_position(shortestDistPoint)
		
	return [shortestDistPoint, shortestCollNormal, shortestDist]
	
func getFinalPosAfterCollisions3(node, nodeDim, currPos, newPos, collisionShape = null, groups = ["solid", "wall", "astro", "object"]):
	
	var shapePointsArray = []
	
	if collisionShape == null:
		shapePointsArray = getCollisionShapePoints(node)
	else:
		shapePointsArray = getCollisionShapePoints(node, collisionShape)
	
	
	
	var shortestDist = (newPos-currPos).length()
	var shortestDistPoint = newPos#(newPos-currPos).length()
	for point in shapePointsArray:
		var ray = RayCast2D.new()
		node.add_child(ray)
		ray.set_global_position(point)
		ray.set_cast_to((newPos-currPos))
		ray.set_enabled(true)
		ray.force_raycast_update()
		var globalPos = ray.get_global_position()
		var isColl = ray.is_colliding()
		var collObj = ray.get_collider()
		while collObj != null && !isObjectInGroups(groups, collObj):
			print("while loop in raycast")
			ray.add_exception(collObj)
			collObj = ray.get_collider()
		
		
		if collObj != null:
			var collPoint = ray.get_collision_point() - ray.get_global_position()
			var newPosObj = collPoint - (collPoint.normalized() * nodeDim/2)
			var dis = collPoint.length()
			if (dis < shortestDist):
				shortestDist = dis
				shortestDistPoint = newPosObj + ray.get_global_position()
		
		node.remove_child(ray)
		ray.free()
	
	return shortestDistPoint
	
func getCollisionShapePoints(node, overrideShapeNode = null):
	
	if overrideShapeNode != null:
		return getPointsFromNode(overrideShapeNode)
	
	var points = []
	
	#assuming shape node will be found in only the first gen of children
	for child in node.get_children():
		if child is StaticBody2D:
			for subChild in child.get_children():
				for point in getPointsFromNode(subChild):
					points.append(point)
			continue
			
			
			
		var pointsss = getPointsFromNode(child)
		if pointsss != null:
			for point in pointsss:
				points.append(point)
		
	return points
		
func getPointsFromNode(node):
	var shapePoints = []
	
	if node is CollisionShape2D:
		#solid shape, or some other shit
		var shape = node.get_shape()
		var rot = node.get_global_rotation()
		var pos = node.get_global_position()
			
		if shape is RectangleShape2D:
			#add each corner of rect
			var corn1 = pos + (shape.get_extents()*Vector2(1, 1)).rotated(rot)
			var corn2 = pos + (shape.get_extents()*Vector2(-1, 1)).rotated(rot)
			var corn3 = pos + (shape.get_extents()*Vector2(1, -1)).rotated(rot)
			var corn4 = pos + (shape.get_extents()*Vector2(-1, -1)).rotated(rot)
			shapePoints.append(corn1)
			shapePoints.append(corn2)
			shapePoints.append(corn3)
			shapePoints.append(corn4)
		
		if shape is CircleShape2D:
			var radius = shape.get_radius()
			for i in 24:
				var point = pos + Vector2(radius, 0).rotated(rot + ((PI/12.0) * i))
				shapePoints.append(point)
			
		if shape is CapsuleShape2D:
			var radius = shape.get_radius()
			var height = shape.get_height()
			for i in 24:
				var heightToAdd = height if i < 11 else -height
				var point = pos + Vector2(radius, heightToAdd).rotated(rot + ((PI/12.0) * i))
				shapePoints.append(point)
				
		if shape is ConcavePolygonShape2D || shape is ConvexPolygonShape2D:
			for seg in shape.get_segments():
				shapePoints.append(seg)
					
	if node is CollisionPolygon2D:
		for seg in node.get_polygon():
			shapePoints.append(seg)
			
	return shapePoints
		
func isObjectInGroups(groups, object):
	for group in groups:
		if object.is_in_group(group):
			return true
			
	return false
	
	
#func setNode(val):
#	node = val
#	if node != null && node.has_method("get_name"):
#		nodeName = node.get_name()
#
#func setName(val):
#	return
