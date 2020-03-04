extends TouchScreenButton

#ALEJANDRO (Feb-14-2020)
#this is the script for controlling the on screen touch controls
#for when playing on an IOS device! I got this script from this dudes video
#online I believe during the summer of 2019. works pretty well, haven't
#cleaned up since that summer though (should do that at some point, not priority tho)

# Gonkee's joystick script for Godot 3 - full tutorial https://youtu.be/uGyEP2LUFPg
# If you use this script, I would prefer if you gave credit to me and my channel

# Change these based on the size of your button and outer sprite
var radius = Vector2(245, 245)
var boundary = 100

var ongoing_drag = 0

var return_accel = 30

var threshold = 40

var pos_difference = Vector2(0, 0)

var hideshit = false
var buttonIsShowing = false

var movingLeft = false
var movingRight = false
var pressingInteract = -1

#2 = just pressed, 1 = pressed, 0 = just released, -1 = released
var movingUp = -1
onready var buttonTween = Tween.new()
onready var buttonPath = get_node(global.lvl().astroNodePath).bue#$"/root/Control/Cam2D/CanvasLayer/joyButton"
var stickTween

#getters for astro script
func moving():
	if movingLeft:
		return -1
	if movingRight:
		return 1
	else:
		return 0
		
func jumping():
	#1 = press, 0 = just released, -1 = released
	return movingUp

func interacting():
	return pressingInteract > -1

func _ready():
	
	if(not visible):
		deactivate()
	
	
	#buttonTween = Tween.new()
	add_child(buttonTween)
	buttonTween.interpolate_property(buttonPath, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
	
	stickTween = Tween.new()
	add_child(stickTween)
	var stickPath = get_parent()
	stickTween.interpolate_property(stickPath, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
	
	
func deactivate():
	hide()
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)
	set_process_input(false)
	
func activate():
	show()
	set_process(true)
	set_physics_process(true)
	set_process_unhandled_input(true)
	set_process_input(true)

func _process(delta):
	#print (movingUp)
	if movingUp ==0:
		movingUp = -1
		showButton(false, false)
	if movingUp ==2:
		movingUp = 1
#	if ongoing_drag == -1:
	if pressingInteract == 2:
		pressingInteract = 1
	if pressingInteract == 0:
		pressingInteract = -1
		showButton(false, true)
		
#		#pos_difference = (Vector2(0, 0) - radius) - position
#		#position += pos_difference * return_accel * delta
#		pass
#	print(position)	
	
	

func get_button_pos():
	return position + radius

func showStick(visible):
	buttonIsShowing = visible
	if (visible):
		get_parent().show()
		stickTween.stop_all()
		get_parent().set_modulate(Color(1, 1, 1, 1))
	else:
		stickTween.interpolate_property(get_parent(), "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
		stickTween.start()
		
func showButton(visible, redColor):
	if (redColor):
		buttonPath.set_animation("red")
	else:
		buttonPath.set_animation("blue")
	
	if (visible):
		buttonPath.show()
		buttonTween.stop_all()
		buttonPath.set_modulate(Color(1, 1, 1, 1))
	else:
		buttonTween.interpolate_property(buttonPath, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
		buttonTween.start()

func joyStick(event):
	if position.distance_to(-radius) > threshold && ongoing_drag != -1:
		if position.x > -radius.x:
			#print("right")
			movingLeft = false
			movingRight = true
		else:
			#print("left")
			movingLeft = true
			movingRight = false
	else:
		movingLeft = false
		movingRight = false
		
	if (event is InputEventScreenTouch and event.is_pressed()):
		get_parent().global_position = event.position
		showStick(true)
	
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.is_pressed()):
		
		var event_dist_from_centre = (event.position - get_parent().global_position).length()

		if event_dist_from_centre <= boundary * global_scale.x or event.get_index() == ongoing_drag:
			set_global_position(event.position - radius * global_scale)
			

			if get_button_pos().length() > boundary:
				set_position( get_button_pos().normalized() * boundary - radius)
				

			ongoing_drag = event.get_index()

	if event is InputEventScreenTouch and !event.is_pressed() and event.get_index() == ongoing_drag:
		ongoing_drag = -1
		movingLeft = false
		movingRight = false
		showStick(false)


func joyButton(event):
	if (event is InputEventScreenTouch and event.is_pressed()):
		buttonPath.global_position = event.position
		showButton(true, false)
		movingUp = 2
	else:
		# first will be zero (just released), then -1, released
		movingUp = 0


func joyInteract(event):
	if (event is InputEventScreenTouch and event.is_pressed()):
		buttonPath.global_position = event.position
		showButton(true, true)
		pressingInteract = 2
	else:
		# first will be zero (just released), then -1, released
		pressingInteract = 0

func _input(event): 
	#print (event)
	if (!(event is InputEventKey or event is InputEventMouse)):
		#if event is touch onto screen and left half of screen, OR   if button is showing AND (drag event or meets condition to reset)
		if ((event.position.x < 500 and event is InputEventScreenTouch and event.is_pressed()) or (buttonIsShowing and (event is InputEventScreenDrag or (event is InputEventScreenTouch and !event.is_pressed() and ongoing_drag != -1)))):
			joyStick(event)
		
		if (event.position.x >= 500 and event.position.x < 780 and event is InputEventScreenTouch):
			joyInteract(event)

		if (event.position.x >= 780 and event is InputEventScreenTouch):
			joyButton(event)
			
func get_value():
	if get_button_pos().length() > threshold:
		return get_button_pos().normalized()
	
	return Vector2(0, 0)