tool
extends Resource

class_name CharacterSwitchingWrapper

var charNodePosDict = {global.CHAR.USA : null, global.CHAR.RUS : null, global.CHAR.FRA : null, global.CHAR.CHN : null, global.CHAR.MAR : null}
var charNodeFormerPosDict = {global.CHAR.USA : null, global.CHAR.RUS : null, global.CHAR.FRA : null, global.CHAR.CHN : null, global.CHAR.MAR : null}
var isFlipped = {global.CHAR.USA : null, global.CHAR.RUS : null, global.CHAR.FRA : null, global.CHAR.CHN : null, global.CHAR.MAR : null}


var relativeNode = {global.CHAR.USA : null, global.CHAR.RUS : null, global.CHAR.FRA : null, global.CHAR.CHN : null, global.CHAR.MAR : null}
#var relativeNodeFormerPos = {global.CHAR.USA : null, global.CHAR.RUS : null, global.CHAR.FRA : null, global.CHAR.CHN : null, global.CHAR.MAR : null}

var nodeStoredData = {global.CHAR.USA : null, global.CHAR.RUS : null, global.CHAR.FRA : null, global.CHAR.CHN : null, global.CHAR.MAR : null}

var processed = false



export (NodePath) var node
export (bool) var neverAffectFuture = false
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

#func _ready():
#	call_deferred("readyDeffered")
		
#func readyDeffered():
#		#initially set old position
#		for key in charNodeFormerPosDict.keys():
#			charNodeFormerPosDict[key] = global.lvl().get_node(node).get_global_position()

func defaultRestore(currChar, nodeObj, relativeNodeObj, returnPosFromDefault = false):
	if isFlipped[currChar] != null:
			nodeObj.set_flip_h(isFlipped[currChar])
	
	if charNodePosDict[currChar] != null:
		var pos = charNodePosDict[currChar]
		#if position was relative to an object, set pos relative to it
		if relativeNode[currChar] != null:
			pos += relativeNodeObj.get_global_position()
		
		if returnPosFromDefault:
			return pos
		
		call_deferred("moveNodePosWithCollisions", nodeObj, nodeObj.get_global_position(), pos)
		#moveNodePosWithCollisions(nodeObj, nodeObj.get_global_position(), charNodePosDict[currChar])
		
								
		
			
		
			
func defaultSave(currChar, nodeObj, relativeNodeObj, affectFuture = true):


	relativeNode[currChar] = relativeNodeObj.get_path() if relativeNodeObj != null else null
		
	
	
	var relNodePos = nodeObj.get_global_position()
	if relativeNode[currChar] != null:
		relNodePos -= relativeNodeObj.get_global_position()

	charNodePosDict[currChar] = relNodePos

	if nodeObj.has_method("is_flipped_h"):
			
		isFlipped[currChar] = nodeObj.is_flipped_h()
		
	if !affectFuture || neverAffectFuture: return
		
	var currPos = charNodePosDict[currChar] + relativeNodeObj.get_global_position() if relativeNode[currChar] else charNodePosDict[currChar]
	var posChangeFromFormer = currPos - charNodeFormerPosDict[currChar]#relativeNodeFormerPos[currChar]
	
	for astroChar in global.CHAR:
		if global.charYearDict[global.CHAR[astroChar]] > global.charYearDict[currChar]:
			if charNodePosDict[global.CHAR[astroChar]] != null:
				charNodePosDict[global.CHAR[astroChar]] += posChangeFromFormer
			
			if isFlipped[global.CHAR[astroChar]] != null:
				isFlipped[global.CHAR[astroChar]] = isFlipped[currChar]
		
	charNodeFormerPosDict[currChar] = nodeObj.get_global_position()
		
func moveNodePosWithCollisions(node, currPos, newPos, setting = true, collisionShape = null, groups = ["solid", "wall", "astro", "object"]):
	
	var shapePointsArray
	
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
		ray.cast_to((newPos-currPos))
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
	
	if setting:
		node.set_global_position(shortestDistPoint)
	else:
		return shortestDistPoint
	
	
func getCollisionShapePoints(node, overrideShapeNode = null):
	
	if overrideShapeNode != null:
		return getPointsFromNode(overrideShapeNode)
	
	var points = []
	
	#assuming shape node will be found in only the first gen of children
	for child in node.get_children:
		if child is StaticBody2D:
			for subChild in child.get_children():
				for point in getPointsFromNode(subChild):
					points.append(point)
			continue
			
		for point in getPointsFromNode(child):
			points.append(point)
		
func getPointsFromNode(node):
	var shapePoints
	
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
