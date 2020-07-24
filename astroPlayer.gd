tool
extends KinematicBody2D

#ALEJANDRO (Feb-14-2020)
#This is the main script that runs the logic of the game
#and controls our astronaut! Here our astronaut undergoes
#simulated physics (which are controlled in this script
#as a kinematicBody2D, used to be a rigidBody2D, but now
#we have more control)
#Interaction logics also begin here

#ALEJANDRO (Feb-24-2020)
#renamed from astrooo to astroPlayer.gd!

#used for testing
var CHARACTER_RES = null
export (CharacterRes.CHAR) var startingChar = CharacterRes.CHAR.USA
#var CHARACTER_RES : Resource = null
export (NodePath) var CAMERA_NODE_PATH = null
var CAMERA_NODE
const CAMERA_OFFSET = 200

var TOUCH_CONTROL_NODE

export (NodePath) var INTERACT_TEXT_NODE_PATH = null
var INTERACT_TEXT_NODE 


export (PackedScene) var MENU_SCENE
var MENU_NODE

var readyDone = false

export (bool) var showMoonBG =  true setget showMoonBGSetter
export (bool) var showBlackBG = true #setget showBlackBGSetter
export (bool) var enableShadows = true setget enableShadowsSetter
export (bool) var enableSpawnPoint = false
export (NodePath) var spawnPointPath = null
onready var spawnPoint = get_node(spawnPointPath) if spawnPointPath != null && spawnPointPath != "" else null

var vel = Vector2()
var velTest = Vector2()
var velFinal = Vector2()
var max_move_speed = 200
#var TERMINAL_VEL = 200
var directional_force = Vector2()
#const GRAVITY = 3
var gravity = 0
var fanForce = null
var groundedBubble = false
var ceilingBubble = false

#used for keeping track of what astro is standing on top of during
#character switching
var firstSolidBodyNode = null

var objectStandinOn = []

#used so that when multiple shapes enter or exit, can keep track
#on whether there is at least one solid (floor) shape touching
var solidsStandingOn = []

#needed so can't initiate jump mechanics in midair, after falling
var jumping = false
var holdDownCanJump = true
const SNAP_DEFAULT_VECT = 10

var airTime = 0
var currMaxAirTime = 0
const DEFAULT_MAX_AIR_TIME = 0.1
const MAX_AIR_TIME = 0.6
const DEFAULT_JUMP_FORCE = -150
# var jumpForce = currCharRes.baseJump
var jumpForce = 0

#used to restrict astro horizontal movement from cables
#restrictAndMove2PointJUMP is used so that it only pulls back once
#in mid air
var restrictAndMove2Point = null
var restrictAndMove2PointJUMP = false
var restrictMovingRight = null

#once on the ground and health depleted, goes true
var dead = false
#used just to know if astro was still on the ground
#after being killed (incase getting launched did not
#put them in the air). Set true when health is depleted in dec_health
var preDeath = false
var immune = false
const IMMUNE_TIME = 2.5
var touchingEnemies = []

const HAZARD_IMMUNE_TIME = 0.75
var onHazard = false
var onHazardKillAstro = false

#the current item astro is in
var currItems = []
var currItemsGlobalPosDict = {}

var movableObject = null
var grabbingMovableObj = false

var beepToggle

#touch controls
var vJoy = -5 # -5 has no specific functionality, but can't be null or shit breaks
var vButton = -5

#counter and time needed of holding down on a platform
#before astro drops through
var platformDropDownCounter = 0
var platformBodyExcep = null
const PLATFORM_DROP_TIME = 0.3

var inPlatformArray = []
var inPlatform = false

var onMovingPlatform = false

onready var light2DPosition = get_node("Light2D").get_position()
onready var light2DScale = get_node("Light2D").get_scale()

onready var get_shadows = get_tree().get_nodes_in_group("shadow")

var lvlNodeReady = false

const DIRECTION = {
	ZERO = Vector2(0,0),
	RIGHT = Vector2(1,0),
	LEFT = Vector2(-1,0),
	UP = Vector2(0,-1),
	DOWN = Vector2(0,1)
}



func _ready():
	set_physics_process(false)
		#need to do this for anything that is doing global.playTest
	#because children readys happen before parent ready (and lvl node
	#is always parent and setting playTest variable)
	call_deferred('readyDeferred')
	#readyDeferred()
	

	#only execute in game
	if Engine.editor_hint:
		return
	
	
	#(get_parent().get_children())
	
	var camNodePathString = ""
	
	for i in CAMERA_NODE_PATH.get_name_count():
		if CAMERA_NODE_PATH.get_name(i) == "..": continue
		if camNodePathString == "":
			camNodePathString = CAMERA_NODE_PATH.get_name(i)
		else:
			camNodePathString = camNodePathString + "/" + CAMERA_NODE_PATH.get_name(i)
	
	camNodePathString = "/root/" + global.lvl().get_name() + "/" + camNodePathString
	
	CAMERA_NODE = get_node(camNodePathString)
	TOUCH_CONTROL_NODE = CAMERA_NODE.get_node(CAMERA_NODE.TOUCH_CONTROL_PATH)
	
	
	
	
	var interactTextNodePathString = ""
	
	for i in INTERACT_TEXT_NODE_PATH.get_name_count():
		if INTERACT_TEXT_NODE_PATH.get_name(i) == "..": continue
		if interactTextNodePathString == "":
			interactTextNodePathString = INTERACT_TEXT_NODE_PATH.get_name(i)
		else:
			interactTextNodePathString = interactTextNodePathString + "/" + INTERACT_TEXT_NODE_PATH.get_name(i)
	interactTextNodePathString = "/root/" + global.lvl().get_name() + "/" + interactTextNodePathString
	
	for child in get_node(interactTextNodePathString).get_children():
		if child is Label:#RichTextLabel:
			INTERACT_TEXT_NODE = child
			break
	
	#INTERACT_TEXT_NODE = get_node(interactTextNodePathString)
	
	
	#need this so that anywhere an interact references the interactNode,
	#the location is based off only one place here in the astro node
	global.interactNode = INTERACT_TEXT_NODE
	#global.interactNodes.clear()
	#global.interactNodes.append(INTERACT_TEXT_NODE)
	
	
	
	if (global.currCharRes == null):
			if global.availableChar.has(startingChar):
				global.currCharRes = global.charResDict[startingChar]
			else:
				global.currCharRes = global.charResDict[global.CHAR.USA]
	CHARACTER_RES = global.currCharRes
		
	jumpForce = CHARACTER_RES.baseJump
	
		
#	if (global.currCharRes != null || is_instance_valid(global.currCharRes)):
		#CHARACTER_RES = global.currCharRes
#	else:
		#global.currCharRes = CHARACTER_RES
	
	#need to do this as well here because the interact text node needs
	#an astro node reference. Because asto is always below text in scene tree,
	#this ready should take place before the text ready and not cause problems
	INTERACT_TEXT_NODE.ASTRO_NODE_PATH = get_path()
	

	#suit sound:
	#audio.sound("suitBeep").play()

	$"ASTRO_ANIM2"._set_playing(true)
	
	
	

	
	
func readyDeferred():
	
	#These visible options are soley for the editor to be able to switch
	#these views on and off to make development easier. The backgrounds
	#and shadows will ALWAYS be on in game, and should be made invisible
	#by making their alpha values zero
	if (global.playTest):
		#showMoonBGSetter(true)
		enableShadowsSetter(true)
		#showBlackBGSetter(true)
		
		
	else:
		#set to what ever inspector bools are
		#showMoonBGSetter(showMoonBG)
		enableShadowsSetter(enableShadows)
		#showBlackBGSetter(showBlackBG)
	
	#showMoonBGSetter(showMoonBG)
	#showBlackBGSetter(showBlackBG)
	
	#flip movableObject bubble
	#checks after character switching applied in lvl ready
	#due to being call_deferred
	flipPushPullArea($"ASTRO_ANIM2".is_flipped_h())


	processSpawnPoint()


	CAMERA_NODE.set_enable_follow_smoothing(false)
	MoveCameraAndInteracText()
	
	yield(get_tree(), "idle_frame")
	CAMERA_NODE.set_deferred("smoothing_enabled", true)

	readyDone = true
	
	

func processSpawnPoint():
	if (spawnPoint != null && spawnPoint.is_in_group("spawnPoint")) && (enableSpawnPoint || global.playTest):
		set_global_position(spawnPoint.getGlobalPosition())
		set_health(spawnPoint.getStartingHealth())
		if !spawnPoint.flashLightOn:
			lightSwitchToggle()
		
		setAstroFlip(spawnPoint.flip)

func showMoonBGSetter(val):
	showMoonBG = val
	
	#prevent errors with trying to get_tree in early calls to setting value
	#when saving or just starting (don't understand why its called before scene tree loads)
	if (get_tree() == null):
		print("Error above from checking null tree^^ in astro moonBG setter, this is fine lol :/")
		return
		
	var bg_nodes = (get_tree().get_nodes_in_group("bg"))
	for i in bg_nodes:
		i.set_visible(showMoonBG) 
	property_list_changed_notify()


func showBlackBGSetter(val):
	showBlackBG = val
	get_node("para/para-stars/black").set_visible(val)
	property_list_changed_notify()
	
	
func enableShadowsSetter(val):
	#enable light and shadow effects
	enableShadows = val
	get_node("Light2D").set_enabled(val)
	get_node("Light2D/LightDarker").set_enabled(val)
	
	get_node("ShadowModulate").set("visible", val)
	get_node("LightsShadowMaskZNode").set("visible", val)
	
	
	property_list_changed_notify()



func hazardEnabled(enabled, hazType, hazAreaID, hazObject, killAstro):
	onHazard = enabled
	onHazardKillAstro = killAstro

func _physics_process(delta):
	
	#only execute in game
	if Engine.editor_hint:
		return
	
	
#	if !lvlNodeReady:
#		lvlNodeReady = global.lvl().readyDone
#		return
	
	
	gravity = global.gravFor1Frame * global.gravMag#GRAVITY * global.gravMag
		
	set_rotation(global.gravRadAng - deg2rad(90))
		
	#here may at somepoint choose to have landing ground bool by if_on_ground again so that
	#shit snaps and doesn't skip past platform?
	
	
	
#	if (groundedBubble):
#		jumping = false
#		holdDownCanJump = true
##		if(get_anim()=="FALL" || get_anim()=="JUMP2"):
##			set_anim("LAND")
#		airTime = 0
#		#jumpForce = CHARACTER_RES.baseJump
#		currMaxAirTime = DEFAULT_MAX_AIR_TIME

	ProcessHazards()


	ApplyMovement(delta)
	
	#temporary fix for anim bug
	if (groundedBubble && (get_anim()=="FALL" || get_anim()=="JUMP2") && vel.y >= 0):
		if !inPlatform:
			set_anim("LAND")
			
	if !groundedBubble && get_anim()!="FALL" && get_anim()!="JUMP2" && vel.y < 0:
		set_anim("JUMP2")
		$"ASTRO_ANIM2".set_frame(14)
			
	
	#if !groundedBubble:
	vel.y += delta * gravity# * 60 * gravity

	#this method allows for proper physics feel when launched in air
	#and for different max speeds & accels on ground and in air
	var speed = CHARACTER_RES.baseGroundSpeed if groundedBubble else CHARACTER_RES.baseAirSpeed
	var accel = CHARACTER_RES.baseGroundAcceleration if groundedBubble else CHARACTER_RES.baseAirAcceleration
		
	var dirSign = directional_force.x * vel.x
	if(dirSign <= 0 || (dirSign > 0 && speed > vel.x)):
		vel.x = lerp(vel.x, (directional_force.x * speed), accel)
	
	max_move_speed = max(abs(vel.x), speed)
	
	#logic for pulling objects
	if grabbingMovableObj:
		#only change the x max if pulling and not pushing
		var get_flip = get_node("ASTRO_ANIM2").is_flipped_h()
		if (get_flip && directional_force.x > 0) || (!get_flip && directional_force.x < 0):
			max_move_speed = abs(movableObject.get_linear_velocity().rotated(-global.gravRadAngFromNorm).x)
		
		#only stop if was moving forward
		if directional_force.x == 0 && ((vel.x > 0 && !get_flip) || (vel.x < 0 && get_flip)) :
			#stop object from moving horizontally
			var objVel = movableObject.get_linear_velocity().rotated(-global.gravRadAngFromNorm)
			objVel.x = 0
			movableObject.set_linear_velocity(objVel.rotated(global.gravRadAngFromNorm))
			
			#hack for weird bug where circle obj keeps spinning if stoped
			if (movableObject.roll):
				movableObject.rigidBodyMode = RigidBody2D.MODE_CHARACTER
			
		elif movableObject.PUSH_PULL_VELOCITY_LIM == 0:
			movableObject.setForceVelLim()
	
	vel.x = clamp(vel.x, -max_move_speed, max_move_speed)
	vel.y = clamp(vel.y, -global.gravTermVel, global.gravTermVel)
	

		# why isn't snap working? opposite direction? look at demo

	#if (airTime > 0):
	#	vel = move_and_slide_with_snap(vel, Vector2(0, 0), Vector2.UP, false, 4, deg2rad(120), false)
	#else:
		#vel = move_and_slide_with_snap(vel, Vector2(0, 1), Vector2.UP, false, 4, deg2rad(120), false)
	velFinal = vel.rotated(global.gravRadAng - deg2rad(90))
	
	var snapMag = 0 if jumping else SNAP_DEFAULT_VECT
	
	if fanForce != null:
		velFinal += fanForce
		snapMag = 0
	
	if restrictAndMove2Point != null && !restrictAndMove2PointJUMP:
		velFinal =  restrictAndMove2Point  - get_global_position()#- restrictAndMove2Point.normalized() * 20                # + (restrictAndMove2Point.normalized() * 200) - get_global_position()
		restrictAndMove2Point = null
		if directional_force.x > 0:
			restrictMovingRight = true
		elif directional_force.x  < 0:
			restrictMovingRight = false
		restrictAndMove2PointJUMP = true
		
		
	if groundedBubble && !inPlatform:
		restrictAndMove2PointJUMP = false
	
	
	
	if (restrictAndMove2Point == null):
		
		
		#vel = move_and_slide(velFinal, global.gravVect() * -1, true, 4, deg2rad(30), false)#(vel, Vector2(0, 1), Vector2.UP, false, 4, deg2rad(120), false)
		
		vel = move_and_slide_with_snap(velFinal, global.gravVect() * snapMag, global.gravVect() * -1, !onMovingPlatform, 4, deg2rad(45), false)

		#vel = move_and_slide(vel, Vector2.UP, 5, 4, deg2rad(30))#(vel, Vector2(0, 1), Vector2.UP, false, 4, deg2rad(120), false)
		
		velFinal = velFinal.rotated((global.gravRadAng - deg2rad(90))* -1)
		vel = velFinal
		velTest = velFinal
		
		
	#so that restrictAndMove2Point does not get transformed by change in gravity
	else:
		#vel = move_and_slide(velFinal, global.gravVect() * -1, true, 4, deg2rad(30), false)
		vel = move_and_slide_with_snap(velFinal, global.gravVect() * snapMag, global.gravVect() * -1, !onMovingPlatform, 4, deg2rad(45), false)
		velTest = vel
	
	if get_slide_count() > 0:
		if groundedBubble:
			if vel.y > 0: vel.y = 0
			
		if ceilingBubble:
			if vel.y < 0: vel.y = 0
		
		
	preventMovingObjPushBack(velFinal)
	
	
func fanEnabled(enabled, fanAccel = null):

	fanForce = fanAccel if enabled else null


func ProcessHazards():
	if onHazardKillAstro && onHazard:
		set_health(2)
		TakeDamage(null, HAZARD_IMMUNE_TIME)
		return
	if !onHazard: return
	TakeDamage(null, HAZARD_IMMUNE_TIME)

func ApplyMovement(delta):
	#governs direction of buttons being pressed. Mostly used for
	#horizontal movement. Resets to zero every frame
	
	ProcessMoveInput(delta)
	Move()
	MoveJump(delta)
	
	ProcessInteractInput()
	ProcessFlashlightInput()
	MoveCameraAndInteracText()
	RestrictFromRope()
	MoveMovableObjects()
	
	ProcessMenuInput()


func preventMovingObjPushBack(velBeforeMoveSlide):
	if (movableObject != null && movableObject.movingDir != 0):
		for index in get_slide_count():
			var coll = get_slide_collision(index)
			if coll.collider != null && coll.collider.is_in_group("object"):
				vel = velBeforeMoveSlide

func ProcessMoveInput(delta):
	
	directional_force = DIRECTION.ZERO
	
	if(!global.controls_enabled):
		return
	
	#print(restrictMovingRight)
	if(Input.is_action_pressed("ui_right") || TOUCH_CONTROL_NODE.stickDir.x > 0): #or vJoy == 1):
		directional_force += DIRECTION.RIGHT

	if(Input.is_action_pressed("ui_left") || TOUCH_CONTROL_NODE.stickDir.x < 0): #or vJoy == -1):
		directional_force += DIRECTION.LEFT
	
	#if platformDropDownCounter > 0: print(platformDropDownCounter)
	#For testing astro death
	if(Input.is_action_pressed("ui_down") && !global.playTest):
		handleplatformDropDownCounter(true, delta)
	elif(Input.is_action_just_released("ui_down") && !global.playTest):
		handleplatformDropDownCounter(false, delta)
		
		
func handleplatformDropDownCounter(downPressed, delta):

#		platformDropDownCounter = Timer.new()
#		platformDropDownCounter.set_wait_time(3)
#		platformDropDownCounter.connect("timeout", self, "fallThroughPlatform")
	if !downPressed:
		platformDropDownCounter = 0
		return
		
	var body = getRelativeNodeBelow()
	if body == null:
		if !groundedBubble:
			platformDropDownCounter += PLATFORM_DROP_TIME
		return
		
	if body != null && !body.is_in_group("platform"): 
		platformDropDownCounter = 0
		return
	
	
	if downPressed:
		platformDropDownCounter += delta
		

		
	if platformDropDownCounter > PLATFORM_DROP_TIME:
		fallThroughPlatform()
		
func fallThroughPlatform():
	var body = getRelativeNodeBelow()
	if !body.is_in_group("platform"): return
	
	body.fallThrough()
		
		
func Move():
	#direction multiplier (right = 1, left = -1)
#	var dirMulti
#
#	#if movement is going right 
#	if (directional_force.x > 0):
#		dirMulti = 1
#
#	elif(directional_force.x < 0):
#		dirMulti = -1

	#no movement? do nothing
	if directional_force.x == 0:#else:
		if (get_anim() == "RUN2"):
			
			
			if ( (get_node("ASTRO_ANIM2").get_frame() >=41)):
				set_anim("END")
		
			if ( (get_node("ASTRO_ANIM2").get_frame() >=20)):
				set_anim("END2")
		
			if ( (get_node("ASTRO_ANIM2").get_frame() >=1)):
				set_anim("END")
		
		if( get_anim() == "START2" ):
			set_anim("END")

		return
	
	#if not pulling an object
	if !grabbingMovableObj:
		setAstroFlip(directional_force.x < 0)
	
	#place holder for push and pull anims:
	else:
		var get_flip = get_node("ASTRO_ANIM2").is_flipped_h()
		if directional_force.x > 0:
			
			if get_flip: pass#set_anim("PULL")
			else: pass#set_anim("PUSH")
		
		elif directional_force.x < 0:
			if get_flip: pass#set_anim("PUSH")
			else: pass#set_anim("PULL")
		
		
	astro_o2_change(curr_anim_code)
		
		

	#set light and camera face right
	
	#get_node("Light2D").set_scale(Vector2 (dirMulti * light2DScale.x, light2DScale.x))
	#get_node("Light2D").set_position(Vector2(dirMulti * light2DPosition.x, light2DPosition.y))
		
	#animation:
	if (groundedBubble && get_anim() != "RUN2" && vel.y >= 0):
		if !inPlatform:
			set_anim("START2")


func setAstroFlip(flip):
	#flip astro sprite		
	get_node("ASTRO_ANIM2").set_flip_h(flip)
	
	#flip movableObject bubble
	flipPushPullArea(flip)
	
	flipLights(flip)
#flip movableObject bubble
func flipPushPullArea(faceLeft):
	var dir = -1 if faceLeft else 1
		
	var pushPullShape = get_node("push_pull_area/push_pull_area_shape")
	pushPullShape.set_position(Vector2(abs(pushPullShape.get_position().x) * dir, pushPullShape.get_position().y))

func flipLights(faceLeft):
	var dir = -1 if faceLeft else 1
		
	get_node("Light2D").set_scale(Vector2 (dir * light2DScale.x, light2DScale.x))
	get_node("Light2D").set_position(Vector2(dir * light2DPosition.x, light2DPosition.y))
	
		
func MoveJump(delta):

	#60 here is acts as how fast before fall anim is activated 
	#TODO: 60 here is not taking into accoun gravity?
	if ((vel.y >= 50.0 || platformDropDownCounter > PLATFORM_DROP_TIME)
	 && get_anim() != "FALL" &&  !groundedBubble):
		set_anim("FALL")
		return

	if (!global.controls_enabled):
		return

	
	var touchJumpJustPressed = TOUCH_CONTROL_NODE.touchStateDict["jump"] == TOUCH_CONTROL_NODE.TOUCH_STATE.JUST_TOUCHED
	var touchJumpPressed = TOUCH_CONTROL_NODE.touchStateDict["jump"] == TOUCH_CONTROL_NODE.TOUCH_STATE.TOUCHING
	var touchJumpJustReleased = TOUCH_CONTROL_NODE.touchStateDict["jump"] == TOUCH_CONTROL_NODE.TOUCH_STATE.JUST_RELEASED
	
	var jumpJustPressed = Input.is_action_just_pressed("ui_accept") || Input.is_action_just_pressed("ui_up") || touchJumpJustPressed
	var jumpPressed = Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up") or touchJumpPressed
	var jumpJustReleased = Input.is_action_just_released("ui_accept") or Input.is_action_just_released("ui_up") or touchJumpJustReleased
		#is just pressed or released
	
	
	if (jumpJustPressed && (groundedBubble) && holdDownCanJump && !inPlatform):# and anim_jump
		set_anim("JUMP2")
		#if already jumping anim, frame won't reset to 0 by itself
		$"ASTRO_ANIM2".set_frame(0)
		jumping = true
		
		
	if (!jumping):
		return
	
		
			
	if ((jumpJustPressed || jumpPressed) && airTime <= currMaxAirTime && holdDownCanJump ):
		vel.y = jumpForce * delta * 60
		airTime += delta
		if(jumpForce <= -400):
			jumpForce -= 10 * delta * 60
		#jumpForce += delta * 60 * JUMP_ACCELERATION
	
		# decrease jump force (by adding) if button still held down
		if (currMaxAirTime <= MAX_AIR_TIME):
			currMaxAirTime += delta
			#print(currMaxAirTime)
	
	
	#to prevent from double jumping
	if(jumpJustReleased):
		holdDownCanJump = false
	
func ProcessInteractInput():
	
	if(!global.controls_enabled):
		return
		
		
	var touchInteractJustPressed = TOUCH_CONTROL_NODE.touchStateDict["interact"] == TOUCH_CONTROL_NODE.TOUCH_STATE.JUST_TOUCHED
	if (Input.is_action_just_pressed("ui_interact") || touchInteractJustPressed) && movableObject == null:
		
		# only be able to interact with shit if not currently able to move an object
		if movableObject == null:
			#for item in currItems:
			
			
			#setting so that items can be prioritized if holding cables or some shit
			var priorityItem = null
			for item in currItems:
				if item.cancelOverlappingInteractables:
					priorityItem = item
				
			if priorityItem == null:
				for item in currItems:
					item.Interact()
			else:
				priorityItem.Interact()
				
		else: movableObject.Interact()
			
			
		for item in currItems:
			item.processed = false
			
	#set grabable object if interact being held down
	var touchInteractPressed = TOUCH_CONTROL_NODE.touchStateDict["interact"] == TOUCH_CONTROL_NODE.TOUCH_STATE.TOUCHING
	grabbingMovableObj = (Input.is_action_pressed("ui_interact") || touchInteractPressed) && movableObject != null && groundedBubble
	

func ProcessFlashlightInput():
	if(!global.controls_enabled):
		return
	
	if Input.is_action_just_pressed("ui_light") || TOUCH_CONTROL_NODE.touchStateDict["light"] == TOUCH_CONTROL_NODE.TOUCH_STATE.JUST_TOUCHED:
		lightSwitchToggle()

func lightSwitchToggle():
	var lightOn = !get_node("Light2D").is_enabled()
	get_node("Light2D").set_enabled(lightOn)
	get_node("Light2D/LightDarker").set_enabled(lightOn)
	#get_node("SuitLight").set_enabled(!lightOn)

func MoveCameraAndInteracText():
	
	var astroPos = get_global_position() 
	#var textOffset = INTERACT_TEXT_NODE.totalOffset
	
	var rotatedDirForce = Vector2(directional_force.x, 0).rotated(global.gravRadAng - deg2rad(90))
	
	
	CAMERA_NODE.set_global_position(astroPos + CAMERA_OFFSET * rotatedDirForce)
	#CAMERA_NODE.set_global_position(Vector2(astroPos.x + (CAMERA_OFFSET * directional_force.x), astroPos.y))
	
	global.interactNode.set_global_position(astroPos + global.interactNode.totalOffset)
	
	for interNode in global.interactNodes:
		if interNode == null || !is_instance_valid(interNode): continue #|| !is_instance_valid(interNode)
		
		var itemNode = interNode.parentInteractObject
		
		if (interNode.fixedOffset && itemNode != null && currItemsGlobalPosDict.has(itemNode)):
			interNode.set_global_position(currItemsGlobalPosDict[itemNode] + interNode.totalOffset)
			continue
			
		interNode.set_position(astroPos + interNode.totalOffset)
	
	
	
func RestrictFromRope():
	if restrictMovingRight == null: return
	
	
	var dirForceTempX = directional_force.x
	
	if directional_force.x == 0:
		restrictMovingRight = null
		
	if (directional_force.x < 0 && restrictMovingRight) || (directional_force.x > 0 && !restrictMovingRight):
		restrictMovingRight = null
			
	
	if restrictMovingRight:
		directional_force.x = clamp(directional_force.x, -1, 0)
	elif !restrictMovingRight:
		directional_force.x = clamp(directional_force.x, 0, 1)
	


func MoveMovableObjects():
	if movableObject != null && grabbingMovableObj:
		if movableObject.has_method("astroTouchBug"):
			movableObject.astroTouchBugOn = true
			
		movableObject.movingDir = 0
		if directional_force.x > 0:
			movableObject.movingDir = 1
		elif directional_force.x < 0:
			movableObject.movingDir = -1
			
	if movableObject != null && !grabbingMovableObj:
		
		movableObject.movingDir = 0
		
		
		
		
		
func ProcessMenuInput():
	if(!global.controls_enabled):
		return
		
	if (Input.is_action_just_pressed("ui_start")):
		
		if MENU_NODE == null:
			MENU_NODE = MENU_SCENE.instance()
			
			CAMERA_NODE.get_node("CanvasLayer").add_child(MENU_NODE)
		else:
			CAMERA_NODE.get_node("CanvasLayer").remove_child(MENU_NODE)
			MENU_NODE = null
		
	
#****************SUIT LIGHT / HEALTH CONTROLLER***************:
	
#color codes used for astro suit
var curr_anim_code = "GGG"
var anim_code1 = "GGG"
var anim_code2 = "GGG"

#goes from 8 to 1, 0 = dead!
var health_code = 8

#blink time for astro suit health
var BLINK_SLOW = 1
var BLINK_FAST  = 0.5
var blink_time = BLINK_SLOW

var timer
var timerUniqueID
var timer_seq = true


#first give o2_health number state, then feeds into timer, timer feeds into o2_change
#o2_change does flip check (orientation of astro), and anim sets the animation based on type (STAND, LAND, etc)


#get_anim(): returns animation set w/o light code (STAND, LAND, etc)
func get_anim():
	return $"ASTRO_ANIM2".get_animation().right(4)


#set_anim(anim_code_post): takes in animation word (no light code) and
#sets the animation with the current anim light code
func set_anim(anim_code_post):
	if (dead):
		return
	
	if (anim_code_post == "JUMP"):
		return
	
	$"ASTRO_ANIM2".set_animation(curr_anim_code + "_" + anim_code_post)



#astro_o2_change(new_code): three letter anim_code -> new animation

#Is called while holding down left or right,
#this is the ONLY place where flipCheck is called
func astro_o2_change(new_code):
	
	new_code = flipCheck(new_code)
	var curr_anim = get_anim()
	
	if( get_anim() != curr_anim || curr_anim_code != new_code):
		
		
		var curr_frame = $"ASTRO_ANIM2".get_frame()
		
		curr_anim_code = new_code
		set_anim((curr_anim))
		
		$"ASTRO_ANIM2".set_frame(curr_frame)




#astro_o2_health: INT -> sets anim_code1 & 2, blink speed, and resets timer

#ThisSSSsss is what is the top of the health bar hiearchy
#This is where the code can set the health of astro
func astro_o2_health(hc):
	
		
	if (hc == 8):
		anim_code1 = "GGG"
		anim_code2 = "GGG"
		timer_reset()
		blink_time = BLINK_SLOW
		var suitLight = get_node("SuitLight")
		suitLight.setSuitLight(suitLight.LIGHT.THREE_GREEN)
	
	elif (hc == 7):
		anim_code1 = "GGG"
		anim_code2 = "GGR"
		timer_reset()
		blink_time = BLINK_SLOW
		var suitLight = get_node("SuitLight")
		suitLight.setSuitLight(suitLight.LIGHT.THREE_GREEN)
	
	elif (hc == 6):
		anim_code1 = "GGR"
		anim_code2 = "GGR"
		timer_reset()
		blink_time = BLINK_SLOW
		var suitLight = get_node("SuitLight")
		suitLight.setSuitLight(suitLight.LIGHT.TWO_GREEN)
	
	elif (hc == 5):
		anim_code1 = "GRR"
		anim_code2 = "GGR"
		timer_reset()
		blink_time = BLINK_SLOW
		var suitLight = get_node("SuitLight")
		suitLight.setSuitLight(suitLight.LIGHT.TWO_GREEN)
	
	elif (hc == 4):
		anim_code1 = "GRR"
		anim_code2 = "GRR"
		timer_reset()
		blink_time = BLINK_SLOW
		var suitLight = get_node("SuitLight")
		suitLight.setSuitLight(suitLight.LIGHT.ONE_GREEN)
		
	elif (hc == 3):
		anim_code1 = "GRR"
		anim_code2 = "RRR"
		timer_reset()
		blink_time = BLINK_SLOW
		var suitLight = get_node("SuitLight")
		suitLight.setSuitLight(suitLight.LIGHT.ONE_GREEN)
		
	elif (hc == 2):
		anim_code1 = "GRR"
		anim_code2 = "RRR"
		timer_reset()
		blink_time = BLINK_FAST
		var suitLight = get_node("SuitLight")
		suitLight.setSuitLight(suitLight.LIGHT.ZERO_GREEN)
		
	elif (hc == 1):
		anim_code1 = "RRR"
		anim_code2 = "RRR"
		timer_reset()
		blink_time = BLINK_FAST
		var suitLight = get_node("SuitLight")
		suitLight.setSuitLight(suitLight.LIGHT.ZERO_GREEN)



#flipCheck(ac): three letter light code -> three letter light code

#responsible for returning the proper anim set
#based on which side and anim code currently
func flipCheck(ac):
	
	var get_flip = get_node("ASTRO_ANIM2").is_flipped_h()
	
	
	#facing right
	if (!get_flip):
		if (ac=="RGG" || ac== "GGR"):
			return "GGR"
			
		elif (ac=="RRG" || ac== "GRR"):
			return "GRR"
			
		else:
			return ac
		
	#facing left
	elif (get_flip):
		if (ac=="GGR" || ac== "RGG"):
			return "RGG"
			
		elif (ac=="GRR" || ac== "RRG"):
			return "RRG"
			
		else:
			return ac





#TODO: switch to base class timer
func timer_reset():
	
	if(is_instance_valid(timer) && timer.is_class("Timer") && timerUniqueID == timer.to_string()):
		timer.stop()
		timer.call_deferred('free')
	else:
		timer = null
	
	#anim_code1 and anim_code2 are the anim codes that are blinking
#	timer = Timer.new()
#	add_child(timer)
#	timer.set_one_shot(true)
#	timer.set_wait_time(blink_time)
#	timer.connect("timeout", self, "on_timeout_complete")
#	timer.start()

	timer = global.newTimer(blink_time, funcref(self, "on_timeout_complete"))
	timerUniqueID = timer.to_string()
	#global.newTimer(blink_time)
	#on_timeout_complete()

#switches between anim_code1 & 2
func on_timeout_complete():
	
	
	timer_seq = !timer_seq
	
	if (timer_seq):
		astro_o2_change(anim_code1)
		
		beepToggle = !beepToggle
		if beepToggle|| health_code < 4:
			audio.sound("suitBeep").play()
			

	else:
		astro_o2_change(anim_code2)
	
	
		
	
	
	#remove_child(timer)
	timer_reset()
	
	
#
#***********END OF SUIT SHIT**********
#***********HEALTH SHIT***************

func set_health(num):
		health_code = num
		astro_o2_health(health_code)

func inc_health():
	if (health_code < 8):
		health_code = health_code+1
		astro_o2_health(health_code)

func dec_health():
	if (health_code > 0):
		health_code = health_code-1
		astro_o2_health(health_code)

	#trigger death animation and turn off controls
	if (health_code <= 1):
		triggerDeath()
	
func triggerDeath():
	global.controls_enabled = false
	
	if(dead):
		return
	
		#used incase falling after getting hit by nora, triggered in set_anim function
		#deadFalling = true

		#triggers var that prevents other anims in set_anim function
	preDeath = true
		
		
	global.newTimer(0.5, funcref(self, "checkIfDeathGrounded"))
		
		
func checkIfDeathGrounded():
	if (groundedBubble):
			InitDeath()
			preDeath = false
		
func InitDeath():
	
	$"ASTRO_ANIM2".set_animation("DEATH")
	
	#used to control and stop all other anims in set_anim
	dead = true
	
	
	set_collision_layer_bit( 0, false )
	global.astroDead = true
	
	global.newTimer(2, funcref(global.lvl(), "gameLost"))
	#get_node("/root/lvl01/Cam2D/EndOfDemo/Blackness").startEndDemoBlacknessTween(false)
	
	

func fadeOutSound():
	var breathingScared = audio.sound("breathingScared")
	var breathingCalm = audio.sound("breathingCalm")
	var suitBeep = audio.sound("suitBeep")
	
	global.newTween(breathingScared, "volume_db", breathingScared.get_volume_db(), -80, 4, 0)
	global.newTween(breathingCalm, "volume_db", breathingCalm.get_volume_db(), -80, 4, 0)
	global.newTween(suitBeep, "volume_db", suitBeep.get_volume_db(), -80, 4, 0)

#***********END OF HEALTH SHIT***************

func _on_ASTRO_ANIM_animation_finished():

	#trigger run after starting
	if (get_anim() == "START2"):
		set_anim("RUN2")

	# triggers standing animation after completing either of the run end animation
	if ((get_anim() == "END") || (get_anim() =="END2") ):
		set_anim("STAND")

	# triggers the run end animatino after completing the landing animation
	if get_anim() == "LAND":
		if groundedBubble:
			set_anim("END")
			get_node("ASTRO_ANIM2").set_frame(10)

	
	$"ASTRO_ANIM2"._set_playing(true)

func TakeDamage(enemyPos = null, customImmuneTime = null):
	
	if(immune || dead || preDeath):
		return
		
	#so astro can go through nora
	#global.lvl(01).noraNode.set_collision_layer_bit( 0, false )
	
	audio.sound("breathingHurt").play()
	
	immune = true
	
	#this is where death logic happens too (and sets preDeath)
	dec_health()
	
	
	
	
		#if now dead after dec_health, trigger proper red effects
	if (preDeath || dead):
		CAMERA_NODE.deathRedness()
	else:
		CAMERA_NODE.TakeDamageFlash()
		
		
	#TODO: make timer take in object and method of object so don't
	#need to remember
	var immuneTime = IMMUNE_TIME if customImmuneTime == null else customImmuneTime
	global.newTimer(immuneTime, funcref(self, 'ImmuneToFalse'))
	
	
	if enemyPos == null: return
	
	if (get_global_position().x < enemyPos.x):
		#launch right
		TakeDamageImpactLaunch(-1)
	else:
		#launch left
		TakeDamageImpactLaunch(1)
		
	
	set_anim("JUMP2")
	
	$"ASTRO_ANIM2".set_frame(14)
	

	#immune = false
		
func ImmuneToFalse():
	immune = false
	if (touchingEnemies.size() > 0):
		TakeDamage()

func TakeDamageImpactLaunch(direction):
	vel = Vector2(200 * direction, -200)



func _on_groundBubble_body_entered(body):
	#(body.get_groups())
	if body.is_in_group("platform") && platformDropDownCounter > PLATFORM_DROP_TIME:	
		
		body.fallThrough()
		_on_groundBubble_body_exited(body)
		platformBodyExcep = body
		return
	
	if (body.get_groups().has("solid")):
		if !body.is_in_group("platform"):
			platformDropDownCounter = 0
		solidsStandingOn.append(body)
		
		if body.is_in_group("object"):
			#setRayCollObjs(false)
			for objs in objectStandinOn:
				objs.astroIsOnTop = false
			body.astroIsOnTop = true
			objectStandinOn.append(body)
		#else:
		#	setRayCollObjs(true)
		#save object standing on and relative position to object
		#if object in other character does not exist, just get astro global position
		
		checkOnMovingPlatform()
		
		
		groundedBubble = true
		
		#	if (groundedBubble):
		jumping = false
		holdDownCanJump = true
##		if(get_anim()=="FALL" || get_anim()=="JUMP2"):
##			set_anim("LAND")
		airTime = 0
#		#jumpForce = CHARACTER_RES.baseJump
		currMaxAirTime = DEFAULT_MAX_AIR_TIME
		
		restrictMovingRight = null
		
		if (preDeath):
			InitDeath()
			

	#	return

func checkOnMovingPlatform():
	onMovingPlatform = false
	for solid in solidsStandingOn:
		if solid.is_in_group("movingPlatform"):
			onMovingPlatform = true
			break

func setRayCollObjs(enable):
	$"StayingGrounded".set_disabled(!enable)
	$"StayingGrounded2".set_disabled(!enable)
	$"StayingGrounded3".set_disabled(!enable)

func _on_groundBubble_body_exited(body):
	if body == platformBodyExcep:
		platformBodyExcep = null
		return

	if (body.get_groups().has("solid")):
		if solidsStandingOn.has(body):
			solidsStandingOn.erase(body)
			
			
		if body.is_in_group("object"):
			objectStandinOn.erase(body)
			for i in objectStandinOn.size():
				if i == objectStandinOn.size()-1:
					objectStandinOn[i].astroIsOnTop = true
					break
				objectStandinOn[i].astroIsOnTop = false
				
			#if objectStandinOn.size() == 0:
			#	setRayCollObjs(true)

#			#if there are still other solid shapes, that astro is touching,
#			#set the next one
#			if solidsStandingOn.size() != 0:
#				var groundedBubbleObjs = get_node("groundBubble").get_overlapping_bodies()
#				for bod in groundedBubbleObjs:
#					if bod.is_in_group("solid"):
#						firstSolidBodyNode = bod
	
		checkOnMovingPlatform()
	
		if (solidsStandingOn.size() == 0):
			
			groundedBubble = false
		
		
	
	
func _on_inPlatformCheck_body_entered(body):
	if body.is_in_group("platform"):
		inPlatformArray.append(body)
		inPlatform = true


func _on_inPlatformCheck_body_exited(body):
	if body.is_in_group("platform"):
		if inPlatformArray.has(body):
			inPlatformArray.erase(body)
		inPlatform = inPlatformArray.size() != 0
	
	
	
	
	
func _on_ceilingBubble_body_entered(body):
	if body.is_in_group("solid"):
		ceilingBubble = true
		
func _on_ceilingBubble_body_exited(body):
	if body.is_in_group("solid"):
		ceilingBubble = false

func _on_Item_check_area_entered(area):
	if dead || preDeath: return
	if (area.get_groups().has("interact")):
		var newItem = area.get_parent()
		
		processItemEntered(newItem)
	
	if (area.get_groups().has("nora") || area.is_in_group("enemy")):
		touchingEnemies.append(area.get_parent())
		var enemyPos = area.get_parent()#global.lvl(01).noraNode.get_global_position()
		TakeDamage(enemyPos)


func processItemEntered(newItem):
	print("processedItemEntered")
		#do virtual interface check
	global.InteractInterfaceCheck(newItem)
		
	currItems.append(newItem)
	
	if currItems.size() > 0:
		TOUCH_CONTROL_NODE.setInteractAvailable(true)
	#need to store global pos for when it leaves astro
	#in case it is fixed text
	currItemsGlobalPosDict[newItem] = newItem.get_global_position()
	
	#only if a movable object is not currently in bound
	if movableObject == null || !isTouchingMovableObj():
		#Execute autoInteract just once, upon entering
		newItem.AutoInteract()




func isTouchingMovableObj():
	
	for item in currItems:
		if item.is_in_group("object"):
			return true
	return false

func _on_Item_check_area_exited(area):
	if !readyDone || global.changingScene: return
	print("_on_Item_check_area_exited")
	if(area.get_groups().has("interact")):
		
		var exitingItem = area.get_parent()
		
		processItemExited(exitingItem)

		#currItem = null
		
	if (area.get_groups().has("nora") || area.is_in_group("enemy")):
		touchingEnemies.remove(area.get_parent())
		
		
func processItemExited(exitingItem):
	if !readyDone || global.changingScene: return
	print("processedItemEXITED")
	#do virtual interface check
	global.InteractInterfaceCheck(exitingItem)
	
	#this order of destroying the item from the list first before closing
	#text is important because AutoCloseInteract() triggers the
	#global.enableMultiInteractNodes(true), which checks currItems
	#for any other nodes that have useNextInterNodeIfNeeded set to false
	currItems.erase(exitingItem)
	
	if currItems.size() == 0:
		TOUCH_CONTROL_NODE.setInteractAvailable(false)
	
	exitingItem.AutoCloseInteract()
	





func _on_push_pull_area_body_entered(body):
	if !readyDone || global.changingScene: return
	if body.is_in_group("object"):
		print("object entered")
		print(body.get_global_position())
		
		#make sure we grab the lowest object if they are stacked
		#so we always drag the entire stack
		
		if movableObject != null:
			if body.objIsBelow(movableObject):
				return
			
			global.destroyInteractNode(movableObject.getSpriteNode().interactNode)
		
		movableObject = body
		processItemEntered (movableObject.getSpriteNode())
		
		
		
		
		
		

func _on_push_pull_area_body_exited(body):
	if !readyDone || global.changingScene: return
	if body.is_in_group("object"):
		print("object exiteddddd")
		body.movingDir = 0
		if movableObject == body:
			movableObject.movingDir = 0
			
			if global.interactNode != null:
				processItemExited(movableObject.getSpriteNode())
			
			movableObject = null
			
			#should only be executing text prompts again
#			for item in currItems:
#				if !item.is_in_group("object"):
#					item.AutoInteract()

func getRelativeNodeBelow():
	return solidsStandingOn[0] if solidsStandingOn.size() > 0 else null
	
	
func getWidth():
	for child in get_children():
		if child is CollisionShape2D:
			var shape = child.get_shape()
			return shape.get_radius() * 2 + shape.get_height()
	return null
	
func getHeight():
	for child in get_children():
		if child is CollisionShape2D:
			var shape = child.get_shape()
			return shape.get_radius() * 2
	return null
	
	
func CSWrapSaveStartState(CSWrap):
	var currChar = global.currCharRes.id
	
	if CSWrap.saveStartState[currChar] == null:
			CSWrap.saveStartState[currChar] = []
			
			
	CSWrap.saveStartState[currChar].resize(3)
	
	CSWrap.saveStartState[currChar][0] = get_global_position()
	CSWrap.saveStartState[currChar][1] = get_global_rotation()
	CSWrap.saveStartState[currChar][2] = objectStandinOn.size() > 0
	
	
	
	
	
	
	
func CSWrapAddChanges(CSWrap):
	var currChar = global.currCharRes.id
	var lvl = global.lvl()
	
	CSWrap.changesToApply[currChar].resize(4)
	
	CSWrap.changesToApply[currChar][0] = get_global_position()# + Vector2(20,-20)
	CSWrap.changesToApply[currChar][1] = get_global_rotation()
	CSWrap.changesToApply[currChar][2] = $"ASTRO_ANIM2".is_flipped_h()
	CSWrap.changesToApply[currChar][3] = objectStandinOn.size() > 0
	
	for otherChar in CSWrap.changesToApply.keys():
		if otherChar == currChar: continue
		if global.charYearDict[otherChar] < global.charYearDict[currChar]: continue
		
		
		#first check if has a savedTimeDiscrep area
		if CSWrap.savedTimeDiscrepencyState[otherChar] != null && CSWrap.savedTimeDiscrepencyState[otherChar] != []:
			
			CSWrap.changesToApply[otherChar].resize(4)
			
			for i in CSWrap.savedTimeDiscrepencyState[otherChar].size():
				CSWrap.changesToApply[otherChar][i] = CSWrap.savedTimeDiscrepencyState[otherChar][i]
		
		#then check if has a savedTimeDiscrep area
		elif lvl.timeDiscrepAstroShapes.has(otherChar):
			
			CSWrap.changesToApply[otherChar].resize(4)
			
			var astroTimeDiscrepArea = lvl.timeDiscrepAstroShapes[otherChar]
			CSWrap.changesToApply[otherChar][0] = astroTimeDiscrepArea.get_global_position()
			CSWrap.changesToApply[otherChar][1] = astroTimeDiscrepArea.get_global_rotation()
			if CSWrap.changesToApply[otherChar][2] == null: $"ASTRO_ANIM2".is_flipped_h()
			if astroTimeDiscrepArea.refNode is Area2D:
				CSWrap.changesToApply[otherChar][3] = false
			else:
				CSWrap.changesToApply[otherChar][3] = true
				
			#astroTimeDiscrepArea.disableActivity()
				
		#else:
		#	CSWrap.changesToApply[otherChar] = CSWrap.changesToApply[currChar].duplicate(true)
				
			
	for csw in lvl.charSwitchWrappers.values():
		var cswNode = lvl.get_node(csw.nodePath)
		
		if objectStandinOn.size() > 0 && cswNode == objectStandinOn[objectStandinOn.size()-1]:
			if !CSWrap.dependantCSWrappers.has(currChar):
				CSWrap.dependantCSWrappers[currChar] = []
			if !CSWrap.dependantCSWrappers[currChar].has(csw):
				CSWrap.dependantCSWrappers[currChar].append(csw)
		
	
func CSWrapApplyChanges(CSWrap):
	var currChar = global.currCharRes.id
	
	if CSWrap.changesToApply[currChar] == []: return
	
	var astroPosChange = null
	var astroRotChange = null
	var astroAnim2Flip = null
	
	astroPosChange = CSWrap.changesToApply[currChar][0]
		
	astroRotChange = CSWrap.changesToApply[currChar][1]
		

	astroAnim2Flip = CSWrap.changesToApply[currChar][2]
	
	
	$"ASTRO_ANIM2".set_flip_h(astroAnim2Flip)
	flipPushPullArea(astroAnim2Flip)
	
	set_global_position(astroPosChange)
	
	
	set_global_rotation(astroRotChange)
		
	
func CSWrapSaveTimeDiscrepState(CSWrap, astroChar, set : bool):
	if !set:
		CSWrap.savedTimeDiscrepencyState[astroChar] = null
		return
		
	CSWrap.savedTimeDiscrepencyState[astroChar] = []
	CSWrap.savedTimeDiscrepencyState[astroChar].resize(4)
	
	CSWrap.savedTimeDiscrepencyState[astroChar][0] = get_global_position()
	CSWrap.savedTimeDiscrepencyState[astroChar][1] = get_global_rotation()
	CSWrap.savedTimeDiscrepencyState[astroChar][2] = $"ASTRO_ANIM2".is_flipped_h()
	CSWrap.savedTimeDiscrepencyState[astroChar][3] = objectStandinOn.size() > 0

func CSWrapApplyDependantChanges(CSWrap):
	pass
#	var currChar = global.currCharRes.id
#
#	var posChange = CSWrap.changesToApply[currChar][0]
#	var rotChange = CSWrap.changesToApply[currChar][1]
	
#
#	if CSWrap.dependantCSWrappers[global.currCharRes.id] != null && CSWrap.dependantCSWrappers[global.currCharRes.id].size() > 0:
#				for dependantCSWrap in CSWrap.dependantCSWrappers[global.currCharRes.id]:
#
#					global.lvl().get_node(dependantCSWrap.nodePath).CSWrapRecieveTransformChanges(dependantCSWrap, global.currCharRes.id, posChange, rotChange)













