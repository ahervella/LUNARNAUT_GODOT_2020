tool
extends Resource

class_name CharacterSwitchingWrapper


var dependantCSWrappers = {global.CHAR.USA : [], global.CHAR.RUS : [], global.CHAR.FRA : [], global.CHAR.CHN : [], global.CHAR.MAR : []}
var extraCSWrappers = []
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
	kb.set_global_rotation(node.get_global_rotation())
	
	var ogParents = {}
	var ogNodeAbove = {}
	
	var dependantGroupNodes = []
	
	for dp in dependantGroup:
		var dpNode = global.lvl().get_node(dp.node)
		if dpNode.get_name() == "Cam2D": continue
		
		dependantGroupNodes.append(dpNode)
		
		dp.changesToApply[global.CharacterRes.id][0] = null
		
		ogParents[dpNode] = (dpNode.get_parent())
		var nodeInd = dpNode.get_index() if dpNode.get_index() == 0 else dpNode.get_index()-1
		ogNodeAbove[dpNode] = dpNode.get_parent().get_child(nodeInd)
		
		
	
	for child in node.get_children():
		if child is CollisionShape2D:
			var globalPos = child.get_global_position()
			var globalRot = child.get_global_rotation()
			var dup = child.duplicate()
			kb.add_child(dup)
			dup.set_global_position(globalPos)
			dup.set_global_rotation(globalRot)
			break
	
	
	for rb in dependantGroupNodes:
		var thingy = rb
		var thingyPos = thingy.get_global_position()
		var thingyRot = thingy.get_global_rotation()
		rb.get_parent().remove_child(rb)
		kb.add_child(thingy)
		thingy.set_global_position(thingyPos)
		thingy.set_global_rotation(thingyRot)
		
		
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
				
				if collObj != null:
					
					var dirVect = collObj.get_normal().normalized()#.tangent()
					#dirVect.x = abs(dirVect.x) if totalChange.x > 0 else abs(dirVect.x) * -1
					dirVect = dirVect.rotated(deg2rad(90)) if totalChange.x > 0 else dirVect.rotated(deg2rad(-90))
					
					if hitAngle(dirVect, totalChange, kb, collObj, ogNodeAbove, ogParents, dependantGroupNodes):
						return
			
			#move the body slightly away from its point of contact so upong continuing its journey, it does
			#not detect and parallel collisions with the object it just collided
		var dirVect = collObj.get_normal().normalized()#.tangent()
		#dirVect.x = abs(dirVect.x) if totalChange.x > 0 else abs(dirVect.x) * -1
		dirVect = dirVect.rotated(deg2rad(90)) if totalChange.x > 0 else dirVect.rotated(deg2rad(-90))
	
		kb.set_global_position(kb.get_global_position() + collObj.get_normal().normalized() * 2)
	
	
		#the step is either 10 or whatever is remaining
		step = step if totalHorzDistToTrav > 10 else totalHorzDistToTrav
		
		for inx in dependantGroupNodes.size():
			if inx == 0: continue
			
			var nd = dependantGroupNodes[inx]
			
			#equal to null for debugging in case node isn't either
			var wouldCollide = null
			if nd is KinematicBody2D:
				wouldCollide = nd.test_move(nd.get_transform(), dirVect.normalized() * step, false)
			if nd is RigidBody2D:
				wouldCollide = nd.test_motion(dirVect.normalized() * step, false)
			
			if wouldCollide:
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
		
		var collObj2 = kb.move_and_collide(dirVect * step, false)
	

			
		#if the move parallel to its last move intersects again, then get the distance
		#traveled to subtract from the ground covered
		if collObj2 != null:
			if hitAngle(dirVect, totalChange, kb, collObj2, ogNodeAbove, ogParents, dependantGroupNodes):
				return
			
			var blah = collObj2.get_travel()
			totalHorzDistToTrav -= blah.length()
				
			
		#didn't run into anything so subtract the step from the distance to cover still
		else:
			
			totalHorzDistToTrav -= step
			
		overrideDir = collObj2
			
			
			
	
	closeShit(kb, ogNodeAbove, ogParents, dependantGroupNodes)
	
	
func hitAngle(dirVect, totalChange, kb, collObj, ogNodeAbove, ogParents, dependantGroupNodes):
	#prevent object from moving up slopes greater than 30 degrees with respect to the
	#gravity angle
	var tanVector = collObj.get_normal().rotated(deg2rad(90))
	var vectAngToCheck = tanVector.rotated(-global.gravRadAngFromNorm)
	var maxAngle = global.gravMaxDegAngAllowedMove
	if abs(vectAngToCheck.x) != 0 && ((totalChange.x > 0 && vectAngToCheck.x > 0) || (totalChange.x < 0 && vectAngToCheck.x < 0)):
		
		
		#var rotatingVal = tanVector
		var atanVal = atan(abs(vectAngToCheck.y) / abs(vectAngToCheck.x))
		
		
		
		
		if atanVal > deg2rad(maxAngle):
			#return
			
			
			#undo this move if the angle is too great
			kb.set_global_position(kb.get_global_position() - collObj.get_travel())
			kb.set_global_position(kb.get_global_position() + collObj.get_normal().normalized())
			
			closeShit(kb, ogNodeAbove, ogParents, dependantGroupNodes)
			
			return true
			
	var asfwef = atan(tanVector.y/tanVector.x)#kb.look_at(kb.get_global_position() + dirVect)#rotate(atan(dirVect.y / dirVect.x))
	kb.set_global_rotation(asfwef)
	
	return false
	
func closeShit(kb, ogNodeAbove, ogParents, dependantGroupNodes):
	for nddd in kb.get_children():
		#var nd = nddd
		var globalPos = nddd.get_global_position()
		kb.remove_child(nddd)
		if nddd is CollisionShape2D: continue
		
		var nodeAbove = findNodeAbove(dependantGroupNodes, ogNodeAbove, nddd)
				#check again!!!! and do same for when removing child above
		
		#see if node was set to itself from the beginning of this method
		#indicating that it is the first node index of its parent's children
		if nodeAbove == nddd:
			ogParents[nddd].add_child(nddd)
			ogParents[nddd].move_child(nddd, 0)
		else:
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
	if ogNodeAbove[node] == node:
		return ogNodeAbove[node]
	
	for dpNode in dependantGroupNodes:
		if ogNodeAbove[node] == dpNode:
			return findNodeAbove(dependantGroupNodes, ogNodeAbove, dpNode)
			
	return ogNodeAbove[node]
	
	
	
	
	
func checkIfInCharLvl(currChar):
	match currChar:
		global.CHAR.USA:
			return USA
		global.CHAR.RUS:
			return RUS
		global.CHAR.FRA:
			return FRA
		global.CHAR.CHN:
			return CHN
		global.CHAR.MAR:
			return MAR
	
	

