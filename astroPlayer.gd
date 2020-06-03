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
export (Resource) var CHARACTER_RES = null
#var CHARACTER_RES : Resource = null
export (NodePath) var CAMERA_NODE_PATH = null
onready var CAMERA_NODE = get_node(CAMERA_NODE_PATH)
const CAMERA_OFFSET = 200

onready var TOUCH_CONTROL_NODE = CAMERA_NODE.get_node(CAMERA_NODE.TOUCH_CONTROL_PATH)

export (NodePath) var INTERACT_TEXT_NODE_PATH = null
onready var INTERACT_TEXT_NODE = get_node(INTERACT_TEXT_NODE_PATH)


export (PackedScene) var MENU_SCENE
var MENU_NODE

export (bool) var showMoonBG =  true setget showMoonBGSetter
export (bool) var showBlackBG = true setget showBlackBGSetter
export (bool) var enableShadows = true setget enableShadowsSetter

var vel = Vector2()
var velFinal = Vector2()
var max_move_speed = 200
#var TERMINAL_VEL = 200
var directional_force = Vector2()
#const GRAVITY = 3
var gravity = 0
var groundedBubble = true

#used for keeping track of what astro is standing on top of during
#character switching
var firstSolidBodyNode = null

var objectStandinOn = []

#used so that when multiple shapes enter or exit, can keep track
#on whether there is at least one solid (floor) shape touching
var solidBodyCount = 0

#needed so can't initiate jump mechanics in midair, after falling
var jumping = false
var holdDownCanJump = true

var airTime = 0
var currMaxAirTime = 0
const DEFAULT_MAX_AIR_TIME = 0.1
const MAX_AIR_TIME = 0.6
const DEFAULT_JUMP_FORCE = -150
# var jumpForce = CharacterRes.baseJump
var jumpForce = 0

#used to restrict astro horizontal movement from cables
var restrictAndMove2Point = null
var restrictMovingRight = null

#once on the ground and health depleted, goes true
var dead = false
#used just to know if astro was still on the ground
#after being killed (incase getting launched did not
#put them in the air). Set true when health is depleted in dec_health
var preDeath = false
var immune = false
const IMMUNE_TIME = 2.5
var touchingNora = false

#the current item astro is in
var currItems = []
var currItemsGlobalPosDict = {}

var movableObject = null
var grabbingMovableObj = false

#touch controls
var vJoy = -5 # -5 has no specific functionality, but can't be null or shit breaks
var vButton = -5

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
	
	#only execute in game
	if Engine.editor_hint:
		return
		
	#need this so that anywhere an interact references the interactNode,
	#the location is based off only one place here in the astro node
	global.interactNode = INTERACT_TEXT_NODE
	#global.interactNodes.clear()
	#global.interactNodes.append(INTERACT_TEXT_NODE)
	
	if (CHARACTER_RES == null && global.CharacterRes != null):
		CHARACTER_RES = global.CharacterRes
	elif (global.CharacterRes == null):
		global.CharacterRes = CHARACTER_RES
		
#	if (global.CharacterRes != null || is_instance_valid(global.CharacterRes)):
		#CHARACTER_RES = global.CharacterRes
#	else:
		#global.CharacterRes = CHARACTER_RES
	
	#need to do this as well here because the interact text node needs
	#an astro node reference. Because asto is always below text in scene tree,
	#this ready should take place before the text ready and not cause problems
	INTERACT_TEXT_NODE.ASTRO_NODE_PATH = get_path()
	

	#suit sound:
	audio.sound("suitBeep").play()

	$"ASTRO_ANIM2"._set_playing(true)
	

		

	#need to do this for anything that is doing global.playTest
	#because children readys happen before parent ready (and lvl node
	#is always parent and setting playTest variable)
	call_deferred('readyDeferred')
	#readyDeferred()
	
	
	
func readyDeferred():
	
	#These visible options are soley for the editor to be able to switch
	#these views on and off to make development easier. The backgrounds
	#and shadows will ALWAYS be on in game, and should be made invisible
	#by making their alpha values zero
	if (global.playTest):
		showMoonBGSetter(true)
		enableShadowsSetter(true)
		showBlackBGSetter(true)
		
	else:
		#set to what ever inspector bools are
		showMoonBGSetter(showMoonBG)
		enableShadowsSetter(enableShadows)
		showBlackBGSetter(showBlackBG)
	
	
	#flip movableObject bubble
	#checks after character switching applied in lvl ready
	#due to being call_deferred
	flipPushPullArea($"ASTRO_ANIM2".is_flipped_h())



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



func showBlackBGSetter(val):
	showBlackBG = val
	get_node("para/para-stars/black").set_visible(val)
	
	
func enableShadowsSetter(val):
	#enable light and shadow effects
	enableShadows = val
	get_node("Light2D").set_enabled(val)
	get_node("Light2D/LightDarker").set_enabled(val)



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
	if (groundedBubble):
		jumping = false
		holdDownCanJump = true
		if(get_anim()=="FALL" || get_anim()=="JUMP"):
			set_anim("LAND")
		airTime = 0
		jumpForce = CHARACTER_RES.baseJump
		currMaxAirTime = DEFAULT_MAX_AIR_TIME

	ApplyMovement(delta)


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
	
	if restrictAndMove2Point != null:
		velFinal =  restrictAndMove2Point - restrictAndMove2Point.normalized() * 20 - get_global_position()# + (restrictAndMove2Point.normalized() * 200) - get_global_position()
		restrictAndMove2Point = null
		if directional_force.x > 0:
			restrictMovingRight = true
		elif directional_force.x  < 0:
			restrictMovingRight = false
	
	if (restrictAndMove2Point == null):
		
		vel = move_and_slide(velFinal, global.gravVect() * -1, true, 4, deg2rad(30), false)#(vel, Vector2(0, 1), Vector2.UP, false, 4, deg2rad(120), false)
		#vel = move_and_slide(vel, Vector2.UP, 5, 4, deg2rad(30))#(vel, Vector2(0, 1), Vector2.UP, false, 4, deg2rad(120), false)
		
		velFinal = velFinal.rotated((global.gravRadAng - deg2rad(90))* -1)
		vel = velFinal
		
		
	#so that restrictAndMove2Point does not get transformed by change in gravity
	else:
		vel = move_and_slide(velFinal, global.gravVect() * -1, 5, 4, deg2rad(30), false)
		
		
	preventMovingObjPushBack(velFinal)
	
	

			
func ApplyMovement(delta):
	#governs direction of buttons being pressed. Mostly used for
	#horizontal movement. Resets to zero every frame
	
	ProcessMoveInput()
	Move()
	MoveJump(delta)
	
	ProcessInteractInput()
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

func ProcessMoveInput():
	
	directional_force = DIRECTION.ZERO
	
	if(!global.controls_enabled):
		return
	
	#print(restrictMovingRight)
	if(Input.is_action_pressed("ui_right") || TOUCH_CONTROL_NODE.stickDir.x > 0): #or vJoy == 1):
		directional_force += DIRECTION.RIGHT

	if(Input.is_action_pressed("ui_left") || TOUCH_CONTROL_NODE.stickDir.x < 0): #or vJoy == -1):
		directional_force += DIRECTION.LEFT

	#if directional_force.x == 0:
		#restrictMovingRight = null

	#For testing astro death
	if(Input.is_action_pressed("ui_down") && !global.playTest):
		InitDeath()
		
func Move():
	#direction multiplier (right = 1, left = -1)
	var dirMulti

	#if movement is going right 
	if (directional_force.x > 0):
		dirMulti = 1
		
	elif(directional_force.x < 0):
		dirMulti = -1

	#no movement? do nothing
	else:
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
		#flip astro sprite		
		get_node("ASTRO_ANIM2").set_flip_h(directional_force.x < 0)
		
		#flip movableObject bubble
		flipPushPullArea(get_node("ASTRO_ANIM2").is_flipped_h())
	
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
	get_node("Light2D").set_scale(Vector2 (dirMulti * light2DScale.x, light2DScale.x))
	get_node("Light2D").set_position(Vector2(dirMulti * light2DPosition.x, light2DPosition.y))
		
	#animation:
	if (groundedBubble && get_anim() != "RUN2"):
		set_anim("START2")

#flip movableObject bubble
func flipPushPullArea(faceLeft):
	var dir = -1 if faceLeft else 1
		
	var pushPullShape = get_node("push_pull_area/push_pull_area_shape")
	pushPullShape.set_position(Vector2(abs(pushPullShape.get_position().x) * dir, pushPullShape.get_position().y))

		
func MoveJump(delta):

	#60 here is acts as how fast before fall anim is activated 
	#TODO: 60 here is not taking into accoun gravity?
	if (vel.y >= 50.0 && get_anim() != "FALL" &&  !groundedBubble):
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
	
	
	if (jumpJustPressed && (groundedBubble) && holdDownCanJump):# and anim_jump
		set_anim("JUMP2")
		jumping = true
		groundedBubble = false;
		
		
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
			for item in currItems:
				item.Interact()
				
		else: movableObject.Interact()
			
			
		for item in currItems:
			item.processed = false
			
	#set grabable object if interact being held down
	var touchInteractPressed = TOUCH_CONTROL_NODE.touchStateDict["interact"] == TOUCH_CONTROL_NODE.TOUCH_STATE.TOUCHING
	grabbingMovableObj = (Input.is_action_pressed("ui_interact") || touchInteractPressed) && movableObject != null && groundedBubble
	


func MoveCameraAndInteracText():
	
	var astroPos = get_global_position() 
	#var textOffset = INTERACT_TEXT_NODE.totalOffset
	
	var rotatedDirForce = Vector2(directional_force.x, 0).rotated(global.gravRadAng - deg2rad(90))
	
	
	CAMERA_NODE.set_global_position(astroPos + CAMERA_OFFSET * rotatedDirForce)
	#CAMERA_NODE.set_global_position(Vector2(astroPos.x + (CAMERA_OFFSET * directional_force.x), astroPos.y))
	
	global.interactNode.set_global_position(astroPos + global.interactNode.totalOffset)
	
	for interNode in global.interactNodes:
		if interNode == null || !is_instance_valid(interNode): continue #|| !is_instance_valid(interNode)
		
		if (interNode.fixedOffset):
			interNode.set_global_position(currItemsGlobalPosDict[interNode] + interNode.totalOffset)
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
			
			CAMERA_NODE.add_child(MENU_NODE)
		else:
			CAMERA_NODE.remove_child(MENU_NODE)
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
	
	elif (hc == 7):
		anim_code1 = "GGG"
		anim_code2 = "GGR"
		timer_reset()
		blink_time = BLINK_SLOW
	
	elif (hc == 6):
		anim_code1 = "GGR"
		anim_code2 = "GGR"
		timer_reset()
		blink_time = BLINK_SLOW
	
	elif (hc == 5):
		anim_code1 = "GRR"
		anim_code2 = "GGR"
		timer_reset()
		blink_time = BLINK_SLOW
	
	elif (hc == 4):
		anim_code1 = "GRR"
		anim_code2 = "GRR"
		timer_reset()
		blink_time = BLINK_SLOW
		
	elif (hc == 3):
		anim_code1 = "GRR"
		anim_code2 = "RRR"
		timer_reset()
		blink_time = BLINK_SLOW
		
	elif (hc == 2):
		anim_code1 = "GRR"
		anim_code2 = "RRR"
		timer_reset()
		blink_time = BLINK_FAST
		
	elif (hc == 1):
		anim_code1 = "RRR"
		anim_code2 = "RRR"
		timer_reset()
		blink_time = BLINK_FAST
		



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

func TakeDamage():
	
	if(immune || dead || preDeath):
		return
		
	#so astro can go through nora
	global.lvl(01).noraNode.set_collision_layer_bit( 0, false )
	
	audio.sound("breathingHurt").play()
	
	immune = true
	
	#this is where death logic happens too (and sets preDeath)
	dec_health()
	
	var astroPos = self.get_global_position()
	var noraPos = global.lvl(01).noraNode.get_global_position()

	if (astroPos.x < noraPos.x):
		#launch right
		TakeDamageImpactLaunch(-1)
	else:
		#launch left
		TakeDamageImpactLaunch(1)
		
	
	set_anim("JUMP2")
	
	$"ASTRO_ANIM2".set_frame(14)
	
	#if now dead after dec_health, trigger proper red effects
	if (preDeath || dead):
		CAMERA_NODE.deathRedness()
	else:
		CAMERA_NODE.TakeDamageFlash()
		
		
	#TODO: make timer take in object and method of object so don't
	#need to remember
	global.newTimer(IMMUNE_TIME, funcref(self, 'ImmuneToFalse'))
	#immune = false
		
func ImmuneToFalse():
	immune = false
	if (touchingNora):
		TakeDamage()

func TakeDamageImpactLaunch(direction):
	vel = Vector2(500 * direction, -500)



func _on_groundBubble_body_entered(body):
	if (body.get_groups().has("solid")):
		solidBodyCount += 1
		
		if solidBodyCount == 1:
			firstSolidBodyNode = body
		
		if body.is_in_group("object"):
			for objs in objectStandinOn:
				objs.astroIsOnTop = false
			body.astroIsOnTop = true
			objectStandinOn.append(body)
		#save object standing on and relative position to object
		#if object in other character does not exist, just get astro global position
		
		groundedBubble = true
		
		restrictMovingRight = null
		
		if (preDeath):
			InitDeath()

func _on_groundBubble_body_exited(body):
	if (body.get_groups().has("solid")):
		solidBodyCount -= 1
		if body == firstSolidBodyNode:
			firstSolidBodyNode = null
			
			
		if body.is_in_group("object"):
			objectStandinOn.erase(body)
			for i in objectStandinOn.size():
				if i == objectStandinOn.size()-1:
					objectStandinOn[i].astroIsOnTop = true
					break
				objectStandinOn[i].astroIsOnTop = false

			#if there are still other solid shapes, that astro is touching,
			#set the next one
			if solidBodyCount != 0:
				var groundedBubbleObjs = get_node("groundBubble").get_overlapping_bodies()
				for bod in groundedBubbleObjs:
					if bod.is_in_group("solid"):
						firstSolidBodyNode = bod
	
	if (solidBodyCount == 0):
		
		groundedBubble = false
		
	

func _on_Item_check_area_entered(area):
	print("astoooo: shit entered")
	#print(area.get_groups())
	if (area.get_groups().has("interact")):
		var newItem = area.get_parent()
		
		processItemEntered(newItem)
	
	if (area.get_groups().has("nora")):
		touchingNora = true
		TakeDamage()


func processItemEntered(newItem):
	print("processedItemEntered")
		#do virtual interface check
	global.InteractInterfaceCheck(newItem)
		
	currItems.append(newItem)
	
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
	print("_on_Item_check_area_exited")
	if(area.get_groups().has("interact")):
		
		var exitingItem = area.get_parent()
		
		processItemExited(exitingItem)

		#currItem = null
		
	if (area.get_groups().has("nora")):
		touchingNora = false
		
		
func processItemExited(exitingItem):
	print("processedItemEXITED")
	#do virtual interface check
	global.InteractInterfaceCheck(exitingItem)
	
	#this order of destroying the item from the list first before closing
	#text is important because AutoCloseInteract() triggers the
	#global.enableMultiInteractNodes(true), which checks currItems
	#for any other nodes that have useNextInterNodeIfNeeded set to false
	currItems.erase(exitingItem)
	
	exitingItem.AutoCloseInteract()
	





func _on_push_pull_area_body_entered(body):
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
	if body.is_in_group("object"):
		print("object exiteddddd")
		body.movingDir = 0
		if movableObject == body:
			movableObject.movingDir = 0
			
			processItemExited(movableObject.getSpriteNode())
			
			movableObject = null
			
			#should only be executing text prompts again
#			for item in currItems:
#				if !item.is_in_group("object"):
#					item.AutoInteract()

func getRelativeNodeBelow():
	return firstSolidBodyNode
	
	
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
	
	
func CSWrapSaveStartState(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	
	if CSWrap.saveStartState[currChar] == null:
			CSWrap.saveStartState[currChar] = []
			
			
	CSWrap.saveStartState[currChar].resize(3)
	
	CSWrap.saveStartState[currChar][0] = get_global_position()
	CSWrap.saveStartState[currChar][1] = get_global_rotation()
	CSWrap.saveStartState[currChar][2] = objectStandinOn.size() > 0
	
	
	
	
	
	
	
func CSWrapAddChanges(CSWrap : CharacterSwitchingWrapper):
	var currChar = global.CharacterRes.id
	
	CSWrap.changesToApply[currChar].resize(4)
	
	CSWrap.changesToApply[currChar][0] = get_global_position()
	CSWrap.changesToApply[currChar][1] = get_global_rotation()
	CSWrap.changesToApply[currChar][2] = $"ASTRO_ANIM2".is_flipped_h()
	CSWrap.changesToApply[currChar][3] = objectStandinOn.size() > 0
	

	
	#add camera node as dependant of astro pos
	for csw in global.lvl().charSwitchWrappers:
		if csw.nodePath == "Cam2D" || CAMERA_NODE == global.lvl().get_node(csw.nodePath):
			
			if !CSWrap.dependantCSWrappers.has(currChar):
				CSWrap.dependantCSWrappers[currChar] = []
			if !CSWrap.dependantCSWrappers[currChar].has(csw):
				CSWrap.dependantCSWrappers[currChar].append(csw)
	
#	for astroChar in global.CHAR:
#
#		if global.charYearDict[global.CHAR[astroChar]] > global.charYearDict[currChar]:
#			CSWrapSendTransformChanges(CSWrap, global.CHAR[astroChar], posChange, rotChange)
#			if CSWrap.changesToApply[global.CHAR[astroChar]][0] == null:
#				CSWrap.changesToApply[global.CHAR[astroChar]][0] = Vector2(0, 0)
#
#			if CSWrap.changesToApply[global.CHAR[astroChar]][1] == null:
#				CSWrap.changesToApply[global.CHAR[astroChar]][1] = 0.0
#
#			CSWrap.changesToApply[global.CHAR[astroChar]][0] += posChange
#			CSWrap.changesToApply[global.CHAR[astroChar]][1] += rotChange
	
func CSWrapApplyChanges(CSWrap : CharacterSwitchingWrapper, delta):
	var currChar = global.CharacterRes.id
	
	if CSWrap.changesToApply[currChar] == []: return
	
	var astroPosChange = null
	var astroRotChange = null
	var astroAnim2Flip = null
	
	#if CSWrap.changesToApply[currChar].has(0):
	astroPosChange = CSWrap.changesToApply[currChar][0]
		
	#if CSWrap.changesToApply[currChar].has(1):
	astroRotChange = CSWrap.changesToApply[currChar][1]
		

	astroAnim2Flip = CSWrap.changesToApply[currChar][2]
	
	#var camPos = CSWrap.changesToApply[currChar][3]
	
	$"ASTRO_ANIM2".set_flip_h(astroAnim2Flip)
	flipPushPullArea(astroAnim2Flip)
	
	#var finalPos = get_global_position()
	#if astroPosChange != null && astroPosChange != Vector2(0, 0):
		#finalPos = CSWrap.getFinalPosAfterCollisions(self, get_global_position(), get_global_position() + astroPosChange, $"astroShape")
	#CSWrap.getFinalPosAfterCollisions()
	
	set_global_position(astroPosChange)
	
	
	#if astroRotChange != null && astroRotChange != 0:
	set_global_rotation(astroRotChange)
		
	#CAMERA_NODE.set_global_position(camPos)
	
func CSWrapSaveTimeDiscrepState(CSWrap : CharacterSwitchingWrapper, set : bool):
	pass

func CSWrapApplyDependantChanges(CSWrap : CharacterSwitchingWrapper, delta):
	var currChar = global.CharacterRes.id
	
	var posChange = CSWrap.changesToApply[currChar][0]
	var rotChange = CSWrap.changesToApply[currChar][1]
	
	
	if CSWrap.dependantCSWrappers[global.CharacterRes.id] != null && CSWrap.dependantCSWrappers[global.CharacterRes.id].size() > 0:
				for dependantCSWrap in CSWrap.dependantCSWrappers[global.CharacterRes.id]:
					
					global.lvl().get_node(dependantCSWrap.nodePath).CSWrapRecieveTransformChanges(dependantCSWrap, global.CharacterRes.id, posChange, rotChange)

func CSWrapRecieveTransformChanges(CSWrap : CharacterSwitchingWrapper, currChar, posToAdd, rotToAdd):
	pass
#	#if posToAdd == null || 
#
#	if CSWrap.changesToApply[currChar][0] == null:
#		CSWrap.changesToApply[currChar][0] = Vector2(0, 0)
#
#	if CSWrap.changesToApply[currChar][1] == null:
#		CSWrap.changesToApply[currChar][1] = 0
#
#	CSWrap.changesToApply[currChar][0] += posToAdd
#	CSWrap.changesToApply[currChar][1] += rotToAdd
	
	
	
#
#
#
#func funchandleCharSwitchRestore(charSwitchWrapper):
#
#	pass
#
#
#
#func handleCharSwitchSave(charSwitchWrapper):
#
#	var astroAnimName
#	for child in get_children():
#		if child is AnimatedSprite:
#			astroAnimName = child.get_name()
#			print("got animatedSprite")
#			break
#
#
#	var astroAnimCSWrapNodePath = get_name() + "/" + astroAnimName
#
#	var astroAnimCSWrapExists = false
#	var astroCSWrap
#
#	for csWrap in global.lvl().charSwitchWrappers:
#		if csWrap.nodePath == astroAnimCSWrapNodePath || get_node(csWrap.nodePath) == get_node(astroAnimName):
#			astroAnimCSWrapExists = true
#			print("got animatedSprite 2")
#			print(astroAnimCSWrapNodePath)
#			print(csWrap.nodePath)
#			break
#
##		if csWrap.nodePath == get_name() || get_node(csWrap.nodePath) == self:
##			astroCSWrap = csWrap
#
#
#
#	if !astroAnimCSWrapExists:
#		print("got animatedSprite 3")
#		var astroAnimCSWrap = CharacterSwitchingWrapper.new()
#		astroAnimCSWrap.nodePath = get_name() + "/" + astroAnimName
#
#		var ogAstroPos = charSwitchWrapper.charNodeFormerPosDict[global.CharacterRes.id]
#
#		astroAnimCSWrap.charNodeFormerPosDict[global.CharacterRes.id] = ogAstroPos + get_position()
#		astroAnimCSWrap.defaultSave(global.CharacterRes.id, get_node(astroAnimName), null)
#		astroAnimCSWrap.processed = true
#		astroAnimCSWrap.neverAffectFuture = true
#			#hope the processed variable will take care of any issues of adding to a list while
#		#is it being iterated/walked
#		print(global.lvl().charSwitchWrappers.size())
#		global.lvl().charSwitchWrappers.append(astroAnimCSWrap)
#		print(global.lvl().charSwitchWrappers.size())
#
#
#	charSwitchWrapper.defaultSave(global.CharacterRes.id, self, getRelativeNodeBelow())
#
#
	
	
	
