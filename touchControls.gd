extends Node2D#TouchScreenButton

#ALEJANDRO (Feb-14-2020)
#this is the script for controlling the on screen touch controls
#for when playing on an IOS device! I got this script from this dudes video
#online I believe during the summer of 2019. works pretty well, haven't
#cleaned up since that summer though (should do that at some point, not priority tho)

# Gonkee's joystick script for Godot 3 - full tutorial https://youtu.be/uGyEP2LUFPg
# If you use this script, I would prefer if you gave credit to me and my channel

# Change these based on the size of your button and outer sprite
#active radius
enum TOUCH_STATE{JUST_TOUCHED, TOUCHING, JUST_RELEASED, NO_TOUCH}

var radius = Vector2(250, 250)
#boundary radius
var boundary = 80

var ongoing_drag = 0

var return_accel = 30

#dead zone radius
var threshold = 50

var pos_difference = Vector2(0, 0)

var hideshit = false
var buttonIsShowing = false

var stickDir = Vector2(0, 0)

#var touchState_Stick = TOUCH_STATE.NO_TOUCH
#var touchState_Jump = TOUCH_STATE.NO_TOUCH
#var touchState_Interact = TOUCH_STATE.NO_TOUCH

var touchStateDict = {"stick" : TOUCH_STATE.NO_TOUCH, "jump" : TOUCH_STATE.NO_TOUCH, "interact" : TOUCH_STATE.NO_TOUCH}

#2 = just pressed, 1 = pressed, 0 = just released, -1 = released
var movingUp = -1
onready var buttonTween = Tween.new()
export (NodePath) var touchtouchButton = null
onready var touchButton = get_node(touchtouchButton)

onready var stickTween = Tween.new()
export (NodePath) var touchStickPath = null
onready var touchStick = get_node(touchStickPath)
onready var touchStickInner = touchStick.get_children()[0]


func _ready():
	touchButton.set_modulate(Color(1, 1, 1, 0))
	touchStick.set_modulate(Color(1, 1, 1, 0))
	#turn on for mobile exports
	deactivate()
	
	
	#buttonTween = Tween.new()
	add_child(buttonTween)
	buttonTween.interpolate_property(touchButton, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
	
	add_child(stickTween)
	stickTween.interpolate_property(touchStick, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
	
	
func deactivate():
	hide()
	
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)
	set_process_input(false)
	
func activate():
	show()
	
	set_process_unhandled_input(true)
	set_process_input(true)


#General input
func _input(event): 
	#If input is not from mouse or key
	if (!(event is InputEventKey or event is InputEventMouse)):
		
		#if event is touch onto screen and left half of screen, OR   if button is showing AND (drag event or meets condition to reset)
		if ((event.position.x < 500 and event is InputEventScreenTouch and event.is_pressed()) or (buttonIsShowing and (event is InputEventScreenDrag or (event is InputEventScreenTouch and !event.is_pressed() and ongoing_drag != -1)))):
			joyStick(event)
		
		#if in the middle, it is an interact signal
		if (event.position.x >= 500 and event.position.x < 780 and event is InputEventScreenTouch):
			joyInteract(event)

		#if on the right it is a jump signal
		if (event.position.x >= 780 and event is InputEventScreenTouch):
			joyJump(event)
			

func get_button_pos():
	#this assumes the local position origin of the inner circle
	#is the bottom right corner of the outer circle parent
	#because parent sprite cirlce is "centered".
	#This will always make the (local) position negative when within the circle.
	return touchStickInner.position + radius

func showStick(visible):
	buttonIsShowing = visible
	if (visible):
		touchStick.show()
		stickTween.stop_all()
		touchStick.set_modulate(Color(1, 1, 1, 1))
	else:
		stickTween.interpolate_property(touchStick, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
		stickTween.start()
		
		
func showButton(visible, redColor):
	if (redColor):
		touchButton.set_animation("red")
	else:
		touchButton.set_animation("blue")
	
	if (visible):
		touchButton.show()
		buttonTween.stop_all()
		touchButton.set_modulate(Color(1, 1, 1, 1))
	else:
		buttonTween.interpolate_property(touchButton, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
		buttonTween.start()


func joyStick(event):
	#if past deadzone radius (threshold), change direction of stick
	if touchStickInner.position.distance_to(-radius) > threshold && ongoing_drag != -1:
		if touchStickInner.position.x > -radius.x:
			stickDir = Vector2(1, 0)
		else:
			stickDir = Vector2(-1, 0)
	else:
		stickDir = Vector2(0, 0)
		
		
	#if screen touched (and event is "pressed")
	if (event is InputEventScreenTouch and event.is_pressed()):
		touchStick.global_position = event.position
		setTouchState("stick", TOUCH_STATE.JUST_TOUCHED)
		showStick(true)
	
	#if dragging or pressed
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.is_pressed()):
		
		#position of event = basically global position b/c global position from camera...?
		var event_dist_from_centre = (event.position - touchStick.global_position).length()
		
		
		#get_index() refers to touch index (in case of multitouch)
		
		#if less than boundary radius change position to touch locatoin (global_scale -> accomodate 
		#meaning how much touchControls is scaled to)
		#OR if this is not first time looping, just check we still refering to same touch index
		if event_dist_from_centre <= boundary * global_scale.x or event.get_index() == ongoing_drag:
			touchStickInner.set_global_position(event.position - radius*global_scale)
		
			#if past boundary, halt movement
			if get_button_pos().length() > boundary:
				touchStickInner.set_position( get_button_pos().normalized() * boundary - radius)
				
			#set touch index incase this is first loop
			ongoing_drag = event.get_index()


	#if no longer touching
	if event is InputEventScreenTouch and !event.is_pressed() and event.get_index() == ongoing_drag:
		ongoing_drag = -1
		stickDir = Vector2(0, 0)
		setTouchState("stick", TOUCH_STATE.JUST_RELEASED)
		showStick(false)

#set the touch state for the touch input
func setTouchState(touchStateInput, touchState):
	
	touchStateDict[touchStateInput] = touchState
	#do this to emulate key strokes of just pressed, pressing, and just released
	#in case we want to do logic with that somewhere else
	call_deferred("touchStrokeLogic", touchStateInput)

func touchStrokeLogic(touchStateInput):
	
	if touchStateDict[touchStateInput] == TOUCH_STATE.JUST_TOUCHED:
		touchStateDict[touchStateInput] = TOUCH_STATE.TOUCHING
		return
		
	if touchStateDict[touchStateInput] == TOUCH_STATE.JUST_RELEASED:
		touchStateDict[touchStateInput] = TOUCH_STATE.NO_TOUCH
		return

func joyJump(event):
	if (event is InputEventScreenTouch and event.is_pressed()):
		
		touchButton.global_position = event.position
		setTouchState("jump", TOUCH_STATE.JUST_TOUCHED)
		
		showButton(true, false)
	else:
		
		setTouchState("jump", TOUCH_STATE.JUST_RELEASED)
		showButton(false, false)



func joyInteract(event):
	if (event is InputEventScreenTouch and event.is_pressed()):
		touchButton.global_position = event.position
		setTouchState("interact", TOUCH_STATE.JUST_TOUCHED)
		showButton(true, true)
	else:
		setTouchState("interact", TOUCH_STATE.JUST_RELEASED)
		showButton(false, true)



