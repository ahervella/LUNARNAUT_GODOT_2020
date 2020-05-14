tool
extends RigidBody2D

enum OBJECT_WEIGHT{HEAVY, MEDIUM, LIGHT}

const LINEAR_DAMP = 0.01

export (OBJECT_WEIGHT) var objectWeight = OBJECT_WEIGHT.MEDIUM setget changeWeight
export (bool) var roll = false
export (Vector2) var shapeDimensions = Vector2(25, 25) setget setShapeDim
export (NodePath) var CUSTOM_SPRITE_PATH = null
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
	physMat.rough = false
	physMat.bounce = 0.1
	physMat.absorbent = false
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
	setVarsToDefault()
	
	setCustomSprite()
	
	setForceVelLim()
	
	
			
func setForceVelLim():
	match objectWeight:
		OBJECT_WEIGHT.HEAVY:
			APPLIED_FORCE = 100
			PUSH_PULL_VELOCITY_LIM = 50
			return
		OBJECT_WEIGHT.MEDIUM:
			APPLIED_FORCE = 200
			PUSH_PULL_VELOCITY_LIM = 80
			return
		OBJECT_WEIGHT.LIGHT:
			APPLIED_FORCE = 300
			PUSH_PULL_VELOCITY_LIM = 120
			return
			
func changeWeight(weight):
	objectWeight = weight
	_ready()



func _physics_process(delta):
	#execute only in editor
	if Engine.editor_hint:
		setVarsToDefault()
		setCustomSprite()
		return
		
func _integrate_forces(state):
	
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
	vel.x += APPLIED_FORCE * movingDir
	
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
	vel -= vel * LINEAR_DAMP
	
	state.set_linear_velocity(vel.rotated(global.gravRadAngFromNorm))


func setMode():
	set_mode(rigidBodyMode)
