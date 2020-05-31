tool
extends RigidBody2D

enum OBJECT_WEIGHT{HEAVY, MEDIUM, LIGHT}

const LINEAR_DAMP = 0.01

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

var changeDetected = false

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
	physMat.friction = 0.7
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
	
	setVarsToDefault()
	
	setCustomSprite()
	
	setForceVelLim()
	
	setInteractVars()
	
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



func _physics_process(delta):
	#execute only in editor
	if Engine.editor_hint:
		setVarsToDefault()
		setCustomSprite()
		return
		
func _integrate_forces(state):
	
	#print("bbbb" + get_name())
	#print(get_global_position())
#	if !lvlNodeReady:
#		var currLvlPath = "res://SCENES/%s.tscn" % global.CharacterRes.level
#		lvlNodeReady = !global.levelWrapperDict.has(currLvlPath)
#		return
	
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
	
	state.set_linear_velocity(vel.rotated(global.gravRadAngFromNorm))
	
	#record contact positions with the contacting body as the key
	contactPosDict.clear()
	for i in state.get_contact_count():
		#local coll point to object plus global position of object
		var pos = state.get_contact_collider_position(i) + get_global_position()
		contactPosDict[pos] = state.get_contact_collider_object(i)

	checkForAndMarkAsChanged()



func checkForAndMarkAsChanged():
	if !changeDetected:
		if csWrap == null:
			var lvlNode = global.lvl()
			for csw in lvlNode.charSwitchWrappers:
				if lvlNode.get_node(csw.node) == self:
					csWrap = csw
					break
					
		#change can only be added to future shit if it ever gets a change
		#to be outside timeDiscrep areas (especially if it loaded a past lvl
		#in which it spawned in one)
		var lvlNode = global.lvl()
		if lvlNode.timeDiscrepBodyPresentDict.has(self):
			if lvlNode.timeDiscrepBodyPresentDict[self].size() <= 0:
				changeDetected = CSWrapDetectChange(csWrap)
				
				#if change was made, remove any time discrep area 2ds that might
				#be present from future because changes will now take place and
				#future spot will ref where ever this object is
				if changeDetected: lvlNode.removeCSWrapTimeDiscepArea2D(csWrap)

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
	#if body.is_in_group("object") || body.is_in_group("plug") || body.is_in_group("astro"):
	#	if objIsAbove(body):
	#		if rectObjsAbove.find(body) == -1:
	#			rectObjsAbove.append(body)
			
		

func _on_STACK_AREA_body_exited(body):
	if body.is_in_group("object"):
		if rectObjBelow != null && body == rectObjBelow:
			#if shit is unstacked, set back to default forceVelLim
			rectObjBelow.setForceVelLim()
			rectObjBelow = null
	#if body.is_in_group("object") || body.is_in_group("plug") || body.is_in_group("astro"):
	#	if rectObjsAbove.find(body) != -1:
	#		rectObjsAbove.erase(body)
			
			
	
#keeeeep
func CSWrapSaveStartState(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	
	
	CSWrap.saveStartState[currChar].resize(2)
	
	
	CSWrap.saveStartState[currChar][0] = get_global_position()
	CSWrap.saveStartState[currChar][1] = get_global_rotation()
	
	
func CSWrapSaveTimeDiscrepState(CSWrap : CharacterSwitchingWrapper, set : bool):
	var currChar = global.CharacterRes.id
	CSWrap.savedTimeDiscrepencyState[currChar].resize(2)
	CSWrap.savedTimeDiscrepencyState[currChar][0] = get_global_position() if set else null
	CSWrap.savedTimeDiscrepencyState[currChar][1] = get_global_rotation() if set else null
	
#keeeeep
func CSWrapAddChanges(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	CSWrap.savedTimeDiscrepencyState[currChar].resize(2)
	var pos = get_global_position() if CSWrap.savedTimeDiscrepencyState[currChar][0] == null else CSWrap.savedTimeDiscrepencyState[currChar][0]# - CSWrap.saveStartState[currChar][0]
	var rot = get_global_rotation() if CSWrap.savedTimeDiscrepencyState[currChar][1] == null else CSWrap.savedTimeDiscrepencyState[currChar][1]# - CSWrap.saveStartState[currChar][1]
	
	CSWrap.changesToApply[currChar].resize(3)
	
	CSWrap.changesToApply[currChar][0] = get_global_position()
	CSWrap.changesToApply[currChar][1] = get_global_rotation()
	CSWrap.changesToApply[currChar][2] = get_global_position()

	
	var posDiff = pos - CSWrap.saveStartState[currChar][0]
	var rotDiff = rot - CSWrap.saveStartState[currChar][1]
	
	#change needs to be bigger than 5 to take place
	if !changeDetected: return
	
#	CSWrap.changesToApply[currChar].resize(2)
	
	
	for astroChar in global.CHAR:
		CSWrap.changesToApply[global.CHAR[astroChar]].resize(2)
		
		if global.charYearDict[global.CHAR[astroChar]] > global.charYearDict[currChar]:
			
			
			CSWrap.changesToApply[global.CHAR[astroChar]][0] = pos 
			CSWrap.changesToApply[global.CHAR[astroChar]][1] = rot
	
	
	
	
func CSWrapRecieveTransformChanges(CSWrap : CharacterSwitchingWrapper, currChar, posToAdd, rotToAdd):
	return
#	CSWrap.changesToApply[currChar].resize(2)
#
#	if CSWrap.changesToApply[currChar][0] == null:
#		CSWrap.changesToApply[currChar][0] = Vector2(0, 0)
#
#	if CSWrap.changesToApply[currChar][1] == null:
#		CSWrap.changesToApply[currChar][1] = 0
#
#	CSWrap.changesToApply[currChar][0] += posToAdd
#	CSWrap.changesToApply[currChar][1] += rotToAdd
	
				
func CSWrapDetectChange(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	var posDiff = get_global_position() - CSWrap.saveStartState[currChar][0]
	var rotDiff = get_global_rotation() - CSWrap.saveStartState[currChar][1]
	
	#change needs to be bigger than 5 to take place
	if (posDiff.length() > 5 || rotDiff > 5): 
		var areaNode = global.lvl().area
		
		#if areaNode.get_overlapping
		
		return true
	return false
	
func CSWrapApplyChanges(CSWrap : CharacterSwitchingWrapper, delta):
	#var initialLocation = get_global_position()
	#var initialRotation = get_global_rotation()
	var currChar = global.CharacterRes.id
	
	#var dependantGroup = CSWrap.getDependantGroup()
	
	if CSWrap.changesToApply[currChar][0] != null:# && CSWrap.changesToApply[currChar][0] != Vector2(0, 0):
		set_global_position(CSWrap.changesToApply[currChar][0])
	if CSWrap.changesToApply[currChar][1] != null:# && CSWrap.changesToApply[currChar][0] != Vector2(0, 0):
		set_global_rotation(CSWrap.changesToApply[currChar][1])
#
#		var collShape = null
#		var newPos = get_global_position() + CSWrap.changesToApply[currChar][0]
#		var kBody = null
#		for child in get_children():
#			if child is CollisionShape2D:
#				collShape = child 
#			if child is KinematicBody2D:
#				kBody = child
#
#		#kBody.add_collision_exception_with(self)
#		#kBody.add_collision_exception_with(collShape)
#		print("foaijsdfoaijsdfoajdsfoiajsdofijasodifjaosdifjaoisdjf")
#		CSWrap.getFinalPosAfterCollisions2(self, CSWrap.changesToApply[currChar][0], kBody, dependantGroup)
#		#var finalPos = CSWrap.getFinalPosAfterCollisions(self, getDimensions(), get_global_position(), newPos, collShape)
#		#set_global_position(finalPos)#get_global_position() + CSWrap.changesToApply[currChar][0])
		
#	if CSWrap.changesToApply[currChar][1] != null:
#		set_global_rotation(get_global_rotation() + CSWrap.changesToApply[currChar][1])
	
	#CSWrap.changesToApply[currChar][0] = get_global_position() - initialLocation
	#CSWrap.changesToApply[currChar][1] = get_global_rotation() - initialRotation
	
	
func CSWrapApplyDependantChanges(CSWrap : CharacterSwitchingWrapper, delta):
	CSWrap.dependantCSWrappers[global.CharacterRes.id] = []
	
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
	
	
	
	
	
	
	
	
