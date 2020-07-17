tool
extends RigidBody2D

enum OBJECT_WEIGHT{HEAVY, MEDIUM, LIGHT}
#enum OBJECT_MATERIAL{METAL, WOOD}

const LINEAR_DAMP = 0.01
const DEFAULT_FRIC = 0.7

export (global.MAT) var objectMaterial = global.MAT.METAL
export (OBJECT_WEIGHT) var objectWeight = OBJECT_WEIGHT.MEDIUM setget changeWeight
export (bool) var roll = false
export (Vector2) var shapeDimensions = Vector2(25, 25) setget setShapeDim
export (NodePath) var CUSTOM_SPRITE_PATH = null
export (Resource) var TC_AUTO
export (Resource) var TC_INTERACT

export (String) var interactSoundNode = null
export (String) var interactSoundGroup = null

export (String) var showSoundNode = null
export (String) var showSoundGroup = null

export (String) var hideSoundNode = null
export (String) var hideSoundGroup = null

var fanForce = null


var rectObjBelow = null
#var rectObjsAbove = []
var CUSTOM_SPRITE
var SHAPE_NODE
var PUSH_PULL_VELOCITY_LIM = 0
var APPLIED_FORCE = 0

#is changed by astro
var movingDir = 0 

var firstFrameOneShot = true
var defaultTextureNode
onready var defaultTexture = getDefaultNode()
var rigidBodyMode

var contactPosDict = {}

var lvlNodeReady = false

var astroIsOnTop = false

var csWrap = null

var changeDetected = {}
var thisObjChangeDetected = false

var translateOffset = null
var translateOffsetDeg = null
var transChange = null
var transJustChanged = false
var transJustChangedPos = null
var deactivated = false

var astroTouchBugOn = false
var astroTouching = false

var hazardObjectAreaDict = {}
var objectShape = null

func getterFunction():
	pass


func getDefaultNode():
	if defaultTextureNode == null:
		for child in get_children():
			if child is Sprite:
				defaultTextureNode = child
	
	if defaultTextureNode != null:
		return defaultTextureNode.get_texture()

func setShapeDim(dim):
	shapeDimensions = dim
	
	if SHAPE_NODE == null:
		for child in get_children():
			if child is CollisionShape2D:
				SHAPE_NODE = child
				
	if SHAPE_NODE == null:
		return
	
	var shape = SHAPE_NODE.get_shape()
	if shape is RectangleShape2D:
		shape.set_extents(shapeDimensions/2)
	if shape is CircleShape2D:
		shape.set_radius(1)
		SHAPE_NODE.set_scale(shapeDimensions/2)

func setCustomSprite():
	
	if CUSTOM_SPRITE_PATH != null && CUSTOM_SPRITE_PATH != "":
		defaultTextureNode.set_texture(null)
		CUSTOM_SPRITE = get_node(CUSTOM_SPRITE_PATH)
	else:
		if defaultTexture != null:
			defaultTextureNode.set_texture(defaultTexture)
		CUSTOM_SPRITE = null
	
		
#set these restrictions so user doesn't
#by accident go changing physics in inspector
func setVarsToDefault():
	set_mode(RigidBody2D.MODE_RIGID)
	set_mass(1)
	set_weight(9.8)
	if get_physics_material_override() == null:
		set_physics_material_override(PhysicsMaterial.new())
	
	var physMat = get_physics_material_override()
	physMat.friction = DEFAULT_FRIC
	physMat.rough = true#false
	physMat.bounce = 0.1
	physMat.absorbent = true#false
	gravity_scale = 1
	set_use_custom_integrator(true)
	set_continuous_collision_detection_mode(0)
	set_sleeping(false)
	set_can_sleep(true)
	set_linear_velocity(Vector2(0, 0))
	set_linear_damp(-1.0)
	set_angular_velocity(0.0)
	set_angular_damp(-1.0)
	set_applied_force(Vector2(0, 0))
	set_applied_torque(0.0)
	
	set_scale(Vector2(1, 1))
	#PROJECT SETTINGS (As of May-12-2020):
	#Physics Engine = GodotPhysics
	#Thread Model = Single-Safe
	#Sleep Threshold Linear = 2
	#Sleep Threshold Angular = 0.14
	#Time Before Sleep = 0.5
	#Bp Hashtable Size = 4096
	#Cell Size = 128
	#Default Gravity = 98
	#Defualt Gravity Vector = Vector2(0, 1)
	#Default Linear Damp = 0
	#Default Angular Damp = 1

func _ready():
	
	#set tc in interact node and trigger node in astro scrupt for movabkle onjs
	
	connect("body_entered", self, "bodyEntered")
	connect("body_exited", self, "bodyExited")
	
	setVarsToDefault()
	
	setCustomSprite()
	
	setForceVelLim()
	
	setInteractVars()
	set_physics_process(false)
	
	for child in get_children():
		if child is CollisionShape2D || child is CollisionPolygon2D:
			objectShape = child
			break
	#if get_name() == "PROTO_OBJ_RECT2":
	#	set_global_position(get_global_position() - Vector2(0, 100))
	
			
			
#had to do this because inter_default extends a sprite, not a rigidbody,
#and I kinda want the rigidbody to be the head node here so it doesn't
#have to update it's parent position and shit and not get scaled (because 
#you're not allowed to scale rigidbodies)


func setInteractVars():
	var spriteNode = getSpriteNode()
	spriteNode.TC_AUTO = TC_AUTO
	spriteNode.TC_INTERACT = TC_INTERACT
	
	spriteNode.interactSoundNode = interactSoundNode
	spriteNode.interactSoundGroup = interactSoundGroup
	
	spriteNode.showSoundNode = showSoundNode
	spriteNode.showSoundGroup = showSoundGroup
	
	spriteNode.hideSoundNode = hideSoundNode
	spriteNode.hideSoundGroup = hideSoundGroup
			
func getSpriteNode():
	for child in get_children():
		if child is Sprite:
			return child
	return get_node("DEFAULT_SPRITE")
	
	

func setForceVelLim(overrideWeight = objectWeight):
	match overrideWeight:
		OBJECT_WEIGHT.HEAVY:
			APPLIED_FORCE = 20
			PUSH_PULL_VELOCITY_LIM = 50
			return
		OBJECT_WEIGHT.MEDIUM:
			APPLIED_FORCE = 30
			PUSH_PULL_VELOCITY_LIM = 80
			return
		OBJECT_WEIGHT.LIGHT:
			APPLIED_FORCE = 50
			PUSH_PULL_VELOCITY_LIM = 120
			return
			
func changeWeight(weight):
	objectWeight = weight
	setForceVelLim()#_ready()

#used for a small bug where astro gets stuck when rolling ball
#is making contact with astro
func enableFric(enabled):
	get_physics_material_override().friction = DEFAULT_FRIC if enabled else 0


func _physics_process(delta):
	#execute only in editor
	if Engine.editor_hint:
		setVarsToDefault()
		setCustomSprite()
		return
		
		
#the deactivate and activate are needed so that objects
#don't collide with one another during the few frames that they are adjusting
#position based on the new transform given from applying charSwitching wrapper
#changes
func deactivate():
	var lvl = global.lvl()
	deactivated = true
	for cswnd in lvl.charSwitchWrappers.values():
		#incase there was one we had already set
		if get_colliding_bodies().has(cswnd):continue
		
		add_collision_exception_with(lvl.get_node(cswnd.nodePath))
		
func activate():
	deactivated = false
	var collBodyExcep = get_collision_exceptions()
	for thing in collBodyExcep:
		remove_collision_exception_with(thing)
		
		
func fanEnabled(enabled, fanAccel = null):
	fanForce = fanAccel if enabled else null
	
func getHazardID():
	return get_name()
	
func getCurrHazObj():
	if hazardObjectAreaDict.size() == 0: return null
	return hazardObjectAreaDict.keys()[0]
		
func getCurrHazArea():
	if hazardObjectAreaDict.size() == 0: return null
	return hazardObjectAreaDict[getCurrHazObj()][0]
	
func hazardEnabled(enabled, hazType, hazAreaID, hazObj, killAstro):
	
	if hazAreaID == getHazardID(): return
	
	if !enabled:
		if hazardObjectAreaDict.has(hazObj) && hazardObjectAreaDict[hazObj].has(hazAreaID):
			#var postAddToDiffHaz = false
			#if hazardAreaIDs[0] == hazAreaID && hazardObjects.size() > 1:
			#	postAddToDiffHaz = true
			#if hazardObjects.has(hazObj):
			hazardObjectAreaDict[hazObj].erase(hazAreaID)
			if hazardObjectAreaDict[hazObj].size() == 0:
				#var currHazObj = hazardObjectAreaDict.keys()[0]
				var assignNewHazObj = getCurrHazObj() == hazObj
				hazardObjectAreaDict.erase(hazObj)
				hazObj.removeHazardShape(hazAreaID)
				
				if hazardObjectAreaDict.size() > 0 && assignNewHazObj:
					getCurrHazObj().addHazardShape(getHazardID(), objectShape, self, getCurrHazArea())
			#if postAddToDiffHaz:
				
			
		return
		
	if (global.hazardDict[objectMaterial] != hazType): return
	
	if hazObj.isAreaInSourceRoute(getHazardID(), hazAreaID): return
	
	if !hazardObjectAreaDict.has(hazObj):
		hazardObjectAreaDict[hazObj] = []
	
	if hazardObjectAreaDict[hazObj].has(hazAreaID): return
	hazardObjectAreaDict[hazObj].append(hazAreaID)
	
	if hazardObjectAreaDict.size() == 1:
		hazObj.addHazardShape(getHazardID(), objectShape, self, hazAreaID)
	
	#var dupShape = null
#	var dupShapeTrans = null
#
#	dupHazardShape = objectShape.duplicate()
#
#	dupHazardShape.add_to_group(get_name())
#
#	hazArea.add_child(dupHazardShape)
#	dupHazardShape.set_owner(hazArea)
#	processHazard()
	
	#dupShape.set_global_transform(dupShapeTrans)
	#dupShape.set_global_scale(dupShape.get_global_scale()*1.05)
		
				
	
#func processHazard():
#	if hazardObject == null: return
#
#	hazardObject.updateHazardShape(get_name(), get_global_transform())
	
	
	
func _integrate_forces(state):
	
#	if get_parent() == null:
#		set_use_custom_integrator(false)
#		return
	
	if transJustChangedPos != null && transJustChanged && transJustChangedPos != get_position():
		activate()
		CSWrapSaveStartState(csWrap)
		transJustChanged = false
	
	if transChange != null:
		deactivate()
		state.set_transform(transChange)
		transChange = null
		if csWrap == null:
			var lvl = global.lvl()
			for csw in lvl.charSwitchWrappers.values():
				if lvl.get_node(csw.nodePath) == self:
					csWrap = csw
					break
		transJustChanged = true
		transJustChangedPos = get_position()
		#CSWrapSaveStartState(csWrap)
		
	if deactivated: return
	
	#translate linear velocity back to standard setup
	var vel = state.get_linear_velocity().rotated(-global.gravRadAngFromNorm)
	
	#need to do this because first frame, the vel will have not been
	#set as rotated yet, so need to unrotate this change first frame
	if (firstFrameOneShot):
		#turn off tool shit
		set_physics_process(false)
		vel = state.get_linear_velocity().rotated(global.gravRadAngFromNorm)
		firstFrameOneShot = false
	
	#gravity
	vel.y += global.gravFor1Frame * global.gravMag * state.get_step()
	vel.y = clamp(vel.y, -global.gravTermVel, global.gravTermVel)
	
	#apply pushing force (will always be perpendicular to astro)
	if rectObjBelow == null || movingDir != 0:
		vel.x += APPLIED_FORCE * movingDir
	elif rectObjBelow != null:
		vel.x = rectObjBelow.get_linear_velocity().rotated(-global.gravRadAngFromNorm).x
	
	rigidBodyMode = RigidBody2D.MODE_RIGID
	if movingDir != 0:
		if (!roll):
			#prevents non rollable objects from rolling and turning
			#as they are being pushed
			rigidBodyMode = RigidBody2D.MODE_CHARACTER
			
		vel.x = clamp(vel.x, -PUSH_PULL_VELOCITY_LIM, PUSH_PULL_VELOCITY_LIM)
		
	#can't edit the mode mid frame apparently
	call_deferred("setMode")
	
	#linear dampening so shit doesn't bounce around everywhere
	# and so the circ obj doesn't roll for ever
	vel.y -= vel.y * LINEAR_DAMP
	if rectObjBelow == null || movingDir != 0:
		vel.x -= vel.x * LINEAR_DAMP
	
	var finalVel = vel.rotated(global.gravRadAngFromNorm)
	if fanForce != null:
		finalVel += fanForce
	state.set_linear_velocity(finalVel)
	
	#record contact positions with the contacting body as the key
	contactPosDict.clear()
	for i in state.get_contact_count():
		#local coll point to object plus global position of object
		var pos = state.get_contact_collider_position(i) + get_global_position()
		contactPosDict[pos] = state.get_contact_collider_object(i)

#	processHazard()

	checkForAndMarkAsChanged()
	thisObjectCheckChange()
	
	if astroTouchBugOn:
		astroTouchBug(state)
		astroTouchBugOn = false


#vvvvvvvvvvvvvv These methods were needed to compensate the mini bug where
# astro gets stuck if touching the rotating movable obj. Fixed by just applying
#a baby impulse to object in opposite directino if when signaled by astro script
# that it is trying to move


func bodyEntered(body):
	if body == global.lvl().astroNode:
		astroTouching = true
func bodyExited(body):
	if body == global.lvl().astroNode:
		astroTouching = false



func astroTouchBug(state):
	
	if !astroTouching: return
	var vect = self.get_global_position() - global.lvl().astroNode.get_global_position()
	
	var astro = global.lvl().astroNode
	var contactPoint = null
	var counts = state.get_contact_count()
	for i in state.get_contact_count():
		if state.get_contact_collider_object(i) == astro:
			contactPoint = i
			break
#
	if contactPoint == null: return
	# impulse in oposite direction
	apply_central_impulse(state.get_contact_local_normal(contactPoint).normalized()* 0.3)
	
	#############^^^^^^^^^^^^
	
	
	

func checkForAndMarkAsChanged():
	if transChange != null && !transJustChanged: return
	var lvlNode = global.lvl()
	if !global.lvl().processDone: return
	
	
	if csWrap == null:
		for csw in lvlNode.charSwitchWrappers.values():
			if !csw.checkIfInCharLvl(global.currCharRes.id): continue
			
			if lvlNode.get_node(csw.nodePath) == self:
				csWrap = csw
				break
		if csWrap == null: return
	
	for otherChar in csWrap.changesToApply.keys():
		if !changeDetected.has(otherChar):
			changeDetected[otherChar] = false
	
		if !changeDetected[otherChar]:
					
		#change can only be added to future shit if it ever gets a change
		#to be outside timeDiscrep areas (especially if it loaded a past lvl
		#in which it spawned in one)
		
			var thisShapeIsInTimeDiscrepAreasOtherThanOwn = false
			if lvlNode.timeDiscrepBodyPresentDict2.has(self.get_name()) && lvlNode.timeDiscrepBodyPresentDict2[self.get_name()].has(otherChar) && lvlNode.timeDiscrepBodyPresentDict2[self.get_name()][otherChar].size() > 0:
				thisShapeIsInTimeDiscrepAreasOtherThanOwn = true
				
				
			if !thisShapeIsInTimeDiscrepAreasOtherThanOwn:
				changeDetected[otherChar] = CSWrapDetectChange(csWrap)
				
				#if change was made, remove any time discrep area 2ds that might
				#be present from future because changes will now take place and
				#future spot will ref where ever this object is
				if changeDetected[otherChar]:
						
					#if astroChar == currChar: continue
					var thing = null
					var areaNode = null
					if lvlNode.timeDiscrepCSWCharDict[csWrap.nodePath][1].has(otherChar):
						#var areaParentNode = lvlNode.get_node(lvlNode.timeDiscrepCSWCharDict[csWrap.nodePath][0])
						areaNode = lvlNode.get_node(lvlNode.timeDiscrepCSWCharDict[csWrap.nodePath][1][otherChar])
						thing = [self, areaNode]
						lvlNode.timeDiscrepManuallyRemovingArea.append([self, areaNode])
						
						if lvlNode.removeCSWrapTimeDiscepArea2D(csWrap, otherChar, null):
							self.CSWrapSaveTimeDiscrepState(csWrap, otherChar, false)
						
						if thing != null:
							lvlNode.timeDiscrepManuallyRemovingArea.erase(thing)
							

func thisObjectCheckChange():
	if thisObjChangeDetected: return
	if csWrap != null:
		thisObjChangeDetected = CSWrapDetectChange(csWrap)

func setMode():
	set_mode(rigidBodyMode)


func objIsBelow(obj):
	var objRotPos = obj.get_global_position().rotated(-global.gravRadAngFromNorm)
	var selfRotPos = get_global_position().rotated(-global.gravRadAngFromNorm)
	
	return selfRotPos.y < objRotPos.y
		
func objIsAbove(obj):
	var objRotPos = obj.get_global_position().rotated(-global.gravRadAngFromNorm)
	var selfRotPos = get_global_position().rotated(-global.gravRadAngFromNorm)
		
	if obj.is_in_group("object"):
		return (selfRotPos.y - shapeDimensions.y/2) >= objRotPos.y + obj.shapeDimensions.y/2
	
	elif obj.is_in_group("astro"):
		#see if astro has at least half their body in the x dimension of object and astro center above object
		return (((selfRotPos.x + shapeDimensions.x/2) >= (objRotPos.x - obj.getWidth()/2) || (selfRotPos.x - shapeDimensions.x/2) <= (objRotPos.x + obj.getWidth()/2)) 
		&& ((selfRotPos.y - shapeDimensions.y/2) >= objRotPos.y))
		
	return (selfRotPos.y - shapeDimensions.y/2) >= objRotPos.y

#used by lvl() to get the relative node below for character switching
func getRelativeNodeBelow():
	if rectObjBelow != null:
		return rectObjBelow
	else:
		var lowestContPoint = get_global_position()
		for collPoint in contactPosDict.keys():
			if collPoint.y >= lowestContPoint.y:
				lowestContPoint = collPoint
		
		if lowestContPoint != get_global_position():
			return contactPosDict[lowestContPoint]
			
	return null
	
func getRelativeNodesAbove():
	if roll:
		return null
		
		
	var lowestContPoint = get_global_position()
	for collPoint in contactPosDict.keys():
		if collPoint.y < lowestContPoint.y:
			lowestContPoint = collPoint
	
	if lowestContPoint != get_global_position():
		return contactPosDict[lowestContPoint]


func getDimensions():
	for child in get_children():
		if child is CollisionShape2D:
			var shape = child.get_shape()
			if shape is CircleShape2D:
				return Vector2(shape.radius*2, shape.radius*2 ) * child.get_scale()
			if shape is RectangleShape2D:
				return Vector2(shape.extents.x*2, shape.extents.y*2 )* child.get_scale()

func _on_STACK_AREA_body_entered(body):
	if roll: return
	if body.is_in_group("object"):
		if objIsBelow(body):
			rectObjBelow = body
			#so if shit is stacked, make heavier
			rectObjBelow.setForceVelLim(OBJECT_WEIGHT.HEAVY)
		

func _on_STACK_AREA_body_exited(body):
	if body.is_in_group("object"):
		if rectObjBelow != null && body == rectObjBelow:
			#if shit is unstacked, set back to default forceVelLim
			rectObjBelow.setForceVelLim()
			rectObjBelow = null
			
			
	
func CSWrapSaveStartState(CSWrap):
	var currChar = global.currCharRes.id
	
	
	CSWrap.saveStartState[currChar].resize(2)
	
	
	CSWrap.saveStartState[currChar][0] = get_global_position()
	CSWrap.saveStartState[currChar][1] = get_global_rotation()
	
	
func CSWrapSaveTimeDiscrepState(CSWrap, astroChar, set : bool):
	CSWrap.savedTimeDiscrepencyState[astroChar] = []
	CSWrap.savedTimeDiscrepencyState[astroChar].resize(3)
	
	CSWrap.savedTimeDiscrepencyState[astroChar][0] = get_global_position() if set else null
	CSWrap.savedTimeDiscrepencyState[astroChar][1] = get_global_rotation() if set else null
	CSWrap.savedTimeDiscrepencyState[astroChar][2] = get_transform() if set else null	
	
func CSWrapAddChanges(CSWrap):
	var currChar = global.currCharRes.id
	var lvl = global.lvl()
	
	CSWrap.changesToApply[currChar].resize(3)
	
	CSWrap.changesToApply[currChar][0] = get_global_position()
	CSWrap.changesToApply[currChar][1] = get_global_rotation()
	CSWrap.changesToApply[currChar][2] = get_transform()

	if !thisObjChangeDetected: return
	
	
	
	for astroChar in CSWrap.changesToApply.keys():
		CSWrap.changesToApply[astroChar].resize(3)
		
		if global.charYearDict[astroChar] > global.charYearDict[currChar]:
			
			CSWrap.savedTimeDiscrepencyState[astroChar].resize(3)
			var pos = get_global_position() if CSWrap.savedTimeDiscrepencyState[astroChar][0] == null else CSWrap.savedTimeDiscrepencyState[astroChar][0]# - CSWrap.saveStartState[currChar][0]
			var rot = get_global_rotation() if CSWrap.savedTimeDiscrepencyState[astroChar][1] == null else CSWrap.savedTimeDiscrepencyState[astroChar][1]# - CSWrap.saveStartState[currChar][1]
			var tran = get_transform() if CSWrap.savedTimeDiscrepencyState[astroChar][2] == null else CSWrap.savedTimeDiscrepencyState[astroChar][2]
			
			CSWrap.changesToApply[astroChar][0] = pos 
			CSWrap.changesToApply[astroChar][1] = rot
			CSWrap.changesToApply[astroChar][2] = tran
	
							
	
	if astroIsOnTop:

		for csw in lvl.charSwitchWrappers.values():
			if lvl.get_node(csw.nodePath) == lvl.astroNode:
				CSWrap.dependantCSWrappers[currChar].append(csw)
				break
				
	
	
func CSWrapDetectChange(CSWrap ):
	var currChar = global.currCharRes.id
	if CSWrap.saveStartState[currChar] == null || CSWrap.saveStartState[currChar] == []: return false
	var posDiff = get_global_position() - CSWrap.saveStartState[currChar][0]
	var rotDiff = get_global_rotation() - CSWrap.saveStartState[currChar][1]
	
	#change needs to be bigger than 5 to take place
	if (posDiff.length() > 10 || rotDiff > deg2rad(10)): return true
	
	return false
	
func CSWrapApplyChanges(CSWrap):
	var currChar = global.currCharRes.id
	
	
	var physMat = get_physics_material_override()
	var savedFric = physMat.friction
	physMat.friction = 0
	
	if CSWrap.changesToApply[currChar][0] != null: translateOffset = CSWrap.changesToApply[currChar][0]
	if CSWrap.changesToApply[currChar][1] != null: translateOffsetDeg = CSWrap.changesToApply[currChar][1]
	if CSWrap.changesToApply[currChar][1] != null: transChange = CSWrap.changesToApply[currChar][2]
		
	delayedFricReset(savedFric)
		
func delayedFricReset(savedFric):
	var physMat = get_physics_material_override()
	physMat.friction = savedFric
	
func CSWrapApplyDependantChanges(CSWrap):
	CSWrap.dependantCSWrappers[global.currCharRes.id] = []
	
	
	
