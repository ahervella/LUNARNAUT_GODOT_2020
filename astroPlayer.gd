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

export (NodePath) var CAMERA_NODE_PATH = null
onready var CAMERA_NODE = get_node(CAMERA_NODE_PATH)
const CAMERA_OFFSET = 200

export (NodePath) var INTERACT_TEXT_NODE_PATH = null
onready var INTERACT_TEXT_NODE = get_node(INTERACT_TEXT_NODE_PATH)


const AIR_HORZ_SPEED = 160
const GROUND_HORZ_SPEED = 160
const AIR_HORZ_ACCEL = 0.025
const GROUND_HORZ_ACCEL = 0.1

var vel = Vector2()
var max_move_speed = 200
var TERMINAL_VEL = 200
var directional_force = Vector2()
const GRAVITY = 3

var groundedBubble = true

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
var jumpForce = DEFAULT_JUMP_FORCE

var dead = false
var preDeath = false
var immune = false
const IMMUNE_TIME = 2.5
var touchingNora = false

#the current item astro is in
var currItem = null
var currItemGlobalPos : Vector2


#touch controls
export (NodePath) var vControllerPath = null
var vJoy = -5 # -5 has no specific functionality, but can't be null or shit breaks
var vButton = -5

onready var light2DPosition = get_node("Light2D").get_position()
onready var light2DScale = get_node("Light2D").get_scale()

onready var get_shadows = get_tree().get_nodes_in_group("shadow")


const DIRECTION = {
	ZERO = Vector2(0,0),
	RIGHT = Vector2(1,0),
	LEFT = Vector2(-1,0),
	UP = Vector2(0,-1),
	DOWN = Vector2(0,1)

}

func _ready():
	#need this so that anywhere an interact references the interactNode,
	#the location is based off only one place here in the astro node
	global.interactNode = INTERACT_TEXT_NODE
	
	#need to do this as well here because the interact text node needs
	#an astro node reference. Because asto is always below text in scene tree,
	#this ready should take place before the text ready and not cause problems
	INTERACT_TEXT_NODE.ASTRO_NODE_PATH = get_path()
	
	if (vControllerPath != null):
		var vController = get_node(vControllerPath)
		if (vController != null && vController.is_visible()):
			vJoy = vController.moving()
			vButton = vController.jumping()

	#suit sound:
	audio.sound("suitBeep").play()

	$"ASTRO_ANIM2"._set_playing(true)




func _physics_process(delta):
	#here may at somepoint choose to have landing ground bool by if_on_ground again so that
	#shit snaps and doesn't skip past platform?
	if (groundedBubble):
		jumping = false
		holdDownCanJump = true
		if(get_anim()=="FALL" || get_anim()=="JUMP"):
			set_anim("LAND")
		airTime = 0
		jumpForce = DEFAULT_JUMP_FORCE
		currMaxAirTime = DEFAULT_MAX_AIR_TIME


	ApplyMovement(delta)
	
	vel.y += delta * 60 * GRAVITY


	#this method allows for proper physics feel when launched in air
	#and for different max speeds & accels on ground and in air
	var speed = AIR_HORZ_SPEED
	var accel = AIR_HORZ_ACCEL
	
	if(groundedBubble):
		speed = GROUND_HORZ_SPEED
		accel = GROUND_HORZ_ACCEL
		
	var dirSign = directional_force.x * vel.x
	if(dirSign <= 0 || (dirSign > 0 && speed > vel.x)):
		vel.x = lerp(vel.x, (directional_force.x * speed), accel)
	
	
	
	max_move_speed = max(abs(vel.x), speed)
	
	vel.x = clamp(vel.x, -max_move_speed, max_move_speed)
	vel.y = clamp(vel.y, -TERMINAL_VEL, TERMINAL_VEL)
	

		# why isn't snap working? opposite direction? look at demo

	#if (airTime > 0):
	#	vel = move_and_slide_with_snap(vel, Vector2(0, 0), Vector2.UP, false, 4, deg2rad(120), false)
	#else:
		#vel = move_and_slide_with_snap(vel, Vector2(0, 1), Vector2.UP, false, 4, deg2rad(120), false)
	vel = move_and_slide(vel, Vector2.UP, 5, 4, deg2rad(30))#(vel, Vector2(0, 1), Vector2.UP, false, 4, deg2rad(120), false)
	

func ApplyMovement(delta):
	#governs direction of buttons being pressed. Mostly used for
	#horizontal movement. Resets to zero every frame
	
	ApplyInput()
	
	Move()

	MoveJump(delta)
	InteractCheck()
	MoveCameraAndInteracText()

func ApplyInput():
	
	directional_force = DIRECTION.ZERO
	
	if(!global.controls_enabled):
		return
	

	if(Input.is_action_pressed("ui_right")): #or vJoy == 1):
		directional_force += DIRECTION.RIGHT

	if(Input.is_action_pressed("ui_left")): #or vJoy == -1):
		directional_force += DIRECTION.LEFT

func Move():
	var cullMode
	var dirMulti

	#if movement is going right 
	if (directional_force.x > 0):
		#directional_force += DIRECTION.RIGHT
		cullMode = 2
		dirMulti = 1
	elif(directional_force.x < 0):
		#directional_force += DIRECTION.LEFT
		cullMode = 1
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
			
	get_node("ASTRO_ANIM2").set_flip_h(directional_force.x < 0)
		
	astro_o2_change(curr_anim_code)
		
	#changes direction of all shadows to right or left
	
	for p in range (get_shadows.size()):
		
		get_shadows[p].get_occluder_polygon().set_cull_mode(cullMode)
	


	#get_node("RayCast2D").set_cast_to(Vector2(dirMulti * ray_dis,0))
	
	#set light and camera face right
	get_node("Light2D").set_scale(Vector2 (dirMulti * light2DScale.x, light2DScale.x))
	get_node("Light2D").set_position(Vector2(dirMulti * light2DPosition.x, light2DPosition.y))
		
	#animation:
	if (groundedBubble && get_anim() != "RUN2"):
		set_anim("START2")


		
func MoveJump(delta):

	#60 here is acts as how fast before fall anim is activated 
	#TODO: 60 here is not taking into accoun gravity?
	if (vel.y >= 50.0 && get_anim() != "FALL" &&  !groundedBubble):
		set_anim("FALL")
		return

	if (!global.controls_enabled):
		return

	var jumpJustPressed = Input.is_action_just_pressed("ui_accept") || Input.is_action_just_pressed("ui_up") || vButton == 2
	var jumpPressed = Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up") or vButton >= 1
	var jumpJustReleased = Input.is_action_just_released("ui_accept") or Input.is_action_just_released("ui_up") or vButton == 0
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
	
func InteractCheck():
	if (currItem == null):
		return
	if (Input.is_action_just_pressed("ui_interact")):
			currItem.Interact()

	
	#currItem.TextInteract()

func MoveCameraAndInteracText():
	
	var astroPos = get_global_position() 
	var textOffset = INTERACT_TEXT_NODE.totalOffset
	
	CAMERA_NODE.set_global_position(Vector2(astroPos.x + (CAMERA_OFFSET * directional_force.x), astroPos.y))
	
	if (INTERACT_TEXT_NODE.fixedOffset):
		INTERACT_TEXT_NODE.set_global_position(currItemGlobalPos + textOffset)
		return
		
	INTERACT_TEXT_NODE.set_global_position(astroPos + textOffset)
	
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
	
	if(is_instance_valid(timer) && timer.is_class("Timer")):
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
	
	var hurtTintNode = CAMERA_NODE.get_node("hurtTint")
	var cur_color = hurtTintNode.get_modulate()#$"/root/Control/Cam2D/hurtTint".get_modulate()
	var g = cur_color.g
	var r = cur_color.r
	var b = cur_color.b
	var a = cur_color.a
	
	global.newTween(hurtTintNode, "modulate", Color(r, g, b, a), Color(r, g, b, 1), 3, 0)
	
	set_collision_layer_bit( 0, false )
	global.astroDead = true
	
	
	
	#activate blackscreen ending for death (false indicated did not win)
	get_node("/root/lvl01/EndOfDemo/Blackness").startEndDemoBlacknessTween(false)
	
	FadeOutSound()

func FadeOutSound():
	var breathingScared = audio.sound("breathingScared")
	var breathingCalm = audio.sound("breathingCalm")
	var suitBeep = audio.sound("suitBeep")
	
	global.newTween(breathingScared, "volume_db", breathingScared.get_volume_db(), -80, 2, 0)
	global.newTween(breathingCalm, "volume_db", breathingCalm.get_volume_db(), -80, 2, 0)
	global.newTween(suitBeep, "volume_db", suitBeep.get_volume_db(), -80, 2, 0)

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
			#if (directional_force==DIRECTION.ZERO):
			set_anim("END")
			get_node("ASTRO_ANIM2").set_frame(10)
			#else:
				#set_anim("START")
			
	#see previous .gd bug fix for skimming ground
	#if needed for timmer for setting fall anim

	
	$"ASTRO_ANIM2"._set_playing(true)

func TakeDamage():
	
	if(!immune && !dead):
		#so astro can go through nora
		global.lvl(01).noraNode.set_collision_layer_bit( 0, false )
		audio.sound("breathingHurt").play()
		immune = true

		dec_health()
		var astroPos = self.get_global_position()
		var noraPos = global.lvl(01).noraNode.get_global_position()

		if (astroPos.x < noraPos.x):
			#launch right
			TakeDamageImpactLaunch(-1)
		else:
			#launch left
			TakeDamageImpactLaunch(1)

		#flyCount = 0
		set_anim("JUMP2")
		$"ASTRO_ANIM2".set_frame(14)
		
		TakeDamageFlash()
		
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
func TakeDamageFlash():

	var hurtTintNode = CAMERA_NODE.get_node("hurtTint")
	var cur_color = hurtTintNode.get_modulate()
	var g = cur_color.g
	var r = cur_color.r
	var b = cur_color.b
	var a = cur_color.a
	
	global.newTween(hurtTintNode, "modulate", Color(r, g, b, a), Color(r, g, b, 0.7), 0.5, 0)
	#last numbre is delay for starting tween
	global.newTween(self, "modulate", Color(r, g, b), Color(r, 0, 0), 0.5, 0, funcref(self, "TakeDamageFlashReverse"))

func TakeDamageFlashReverse():
	
	var hurtTintNode = CAMERA_NODE.get_node("hurtTint")
	var cur_color = hurtTintNode.get_modulate()
	var g = cur_color.g
	var r = cur_color.r
	var b = cur_color.b
	var a = cur_color.a
	
	global.newTween(hurtTintNode, "modulate", Color(r, g, b, a), Color(r, g, b, 0), 0.5, 0)
	
	global.newTween(self, "modulate", Color(r, 0, 0), Color(r, g, b), 0.5, 0.5)



func _on_groundBubble_body_entered(body):
	if (body.get_groups().has("solid")):
		solidBodyCount += 1
		
		groundedBubble = true
		
		if (preDeath):
			InitDeath()

func _on_groundBubble_body_exited(body):
	if (body.get_groups().has("solid")):
		solidBodyCount -= 1
	
	if (solidBodyCount == 0):
		groundedBubble = false
		
	

func _on_Item_check_area_entered(area):
	#print("astoooo: shit entered")
	#print(get_groups())
	if (area.get_groups().has("interact")):
		currItem = area.get_parent()
		#do virtual interface check
		global.InteractInterfaceCheck(currItem)
		
		#need to store global pos for when it leaves astro
		#in case it is fixed text
		currItemGlobalPos = currItem.get_global_position()
		
		#Execute autoInteract just once, upon entering
		currItem.AutoInteract()
	
	if (area.get_groups().has("nora")):
		touchingNora = true
		TakeDamage()


func _on_Item_check_area_exited(area):
	if(area.get_groups().has("interact")):
		#do virtual interface check
		global.InteractInterfaceCheck(currItem)
		currItem.AutoCloseInteract()
		currItem = null
		
	if (area.get_groups().has("nora")):
		touchingNora = false
