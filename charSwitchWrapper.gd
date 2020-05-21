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

	
		
func getFinalPosAfterCollisions(node, currPos, newPos, collisionShape = null, groups = ["solid", "wall", "astro", "object"]):
	
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
		var collObj = ray.get_collider()
		while collObj != null && !isObjectInGroups(groups, collObj):
			print("while loop in raycast")
			ray.add_exception(collObj)
			collObj = ray.get_collider()
		
		
		if collObj != null:
			if (ray.get_collision_point().length() < shortestDist):
				shortestDist = ray.get_collision_point().length()
				shortestDistPoint = ray.get_collision_point() + ray.get_global_position()
		
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
