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

var interactWidthHeight = 250
var interactCenter = Vector2(1060, 160)
var canInteract = false

var touchCSHeight = 100

var csButtonIsShowing = false
var ongoing_cs_drag = 0
var currAstroCharSelection = null



var touchStateDict = {"stick" : TOUCH_STATE.NO_TOUCH, 
"jump" : TOUCH_STATE.NO_TOUCH, 
"interact" : TOUCH_STATE.NO_TOUCH, 
"cs" : TOUCH_STATE.NO_TOUCH, 
"pause" : TOUCH_STATE.NO_TOUCH,
"inventory" : TOUCH_STATE.NO_TOUCH,
"light" : TOUCH_STATE.NO_TOUCH}


var movingUp = -1
onready var buttonTween = Tween.new()
export (NodePath) var touchtouchButton = null
onready var touchButton = get_node(touchtouchButton)

onready var stickTween = Tween.new()
export (NodePath) var touchStickPath = null
onready var touchStick = get_node(touchStickPath)
onready var touchStickInner = touchStick.get_children()[0]

onready var interactTween = Tween.new()
export (NodePath) var touchInteractPath = null
onready var touchInteract = get_node(touchInteractPath)
var touchInteractXBound = []
var touchInteractYBound = []

onready var lightTween = Tween.new()
export (NodePath) var touchLightPath = null
onready var touchLight = get_node(touchLightPath)
var touchLightXBound = [700, 965]
var touchLightYBound = [520, null]

onready var inventoryTween = Tween.new()
export (NodePath) var touchInventoryPath = null
onready var touchInventory = get_node(touchInventoryPath)
var touchInventoryXBound = [965, null]
var touchInventoryYBound = [520, null]

var inventoryToggle = false

onready var pauseTween = Tween.new()
export (NodePath) var touchPausePath = null
onready var touchPause = get_node(touchPausePath)
var pauseToggle = false
var touchPauseWidth = 250
var touchPauseHeight = 40
var touchPauseXBound = []
var touchPauseYBound = []

var disableCS = false

export (NodePath) var touchPause_scanBGPath = null
export (NodePath) var touchPause_settingsPath = null
export (NodePath) var touchPause_mainMenuPath = null
export (NodePath) var touchPause_reloadLvlPath = null
export (NodePath) var touchPause_loadCPPath = null


onready var touchPause_scanBG = get_node(touchPause_scanBGPath)
onready var touchPause_settings = get_node(touchPause_settingsPath)
onready var touchPause_loadCP = get_node(touchPause_loadCPPath)
onready var touchPause_reloadLvl = get_node(touchPause_reloadLvlPath)
onready var touchPause_mainMenu = get_node(touchPause_mainMenuPath)

onready var touchPause_options = [touchPause_settings,
 touchPause_loadCP,
 touchPause_reloadLvl,
 touchPause_mainMenu]

var touchPause_opt_height = 160
var touchPause_opt_width = 480
onready var touchPause_refPoint = touchPause_settings.get_global_position()

onready var csTween = Tween.new()
export (NodePath) var touchCSPath = null
onready var touchCS = get_node(touchCSPath)
var touchCSXBound = [0]
var touchCSYBound = [0]

export (NodePath) var touchCS1973Path = null
export (NodePath) var touchCS1984Path = null
export (NodePath) var touchCS1996Path = null
export (NodePath) var touchCS2021Path = null
export (NodePath) var touchCS2073Path = null

onready var cs1973Tween = Tween.new()
onready var cs1984Tween = Tween.new()
onready var cs1996Tween = Tween.new()
onready var cs2021Tween = Tween.new()
onready var cs2073Tween = Tween.new()

onready var touchCS1973 = get_node(touchCS1973Path)
onready var touchCS1984 = get_node(touchCS1984Path)
onready var touchCS1996 = get_node(touchCS1996Path)
onready var touchCS2021 = get_node(touchCS2021Path)
onready var touchCS2073 = get_node(touchCS2073Path)

onready var touchCSTweenDict = {CharacterRes.CHAR.USA : cs1984Tween, 
	CharacterRes.CHAR.RUS : cs1973Tween, 
	CharacterRes.CHAR.FRA : cs1996Tween, 
	CharacterRes.CHAR.CHN : cs2021Tween, 
	CharacterRes.CHAR.MAR : cs2073Tween}


onready var touchCSDict = {CharacterRes.CHAR.USA : touchCS1984, 
	CharacterRes.CHAR.RUS : touchCS1973, 
	CharacterRes.CHAR.FRA : touchCS1996, 
	CharacterRes.CHAR.CHN : touchCS2021, 
	CharacterRes.CHAR.MAR : touchCS2073}
	
onready var touchCSTop = touchCS1973.get_global_position().y - touchCSHeight/2

func _ready():
	show()
	touchButton.set_modulate(Color(1, 1, 1, 0))
	touchStick.set_modulate(Color(1, 1, 1, 0))
	touchInteract.set_modulate(Color(1, 1, 1, 0))
	touchInventory.set_modulate(Color(1, 1, 1, 0.25))
	touchLight.set_modulate(Color(1, 1, 1, 0.25))
	touchPause.set_modulate(Color(1, 1, 1, 0.25))
	touchCS.set_modulate(Color(1, 1, 1, 0.25))
	touchPause_scanBG.hide()
	for touchPause_opt in touchPause_options:
		touchPause_opt.hide()
	
	for value in touchCSDict.values():
		value.set_modulate(Color(1, 1, 1, 0))
	#turn on for mobile exports
	deactivate()
	
	
	#buttonTween = Tween.new()
	add_child(buttonTween)
	#buttonTween.interpolate_property(touchButton, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
	
	add_child(stickTween)
	#stickTween.interpolate_property(touchStick, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
	
	add_child(pauseTween)
	
	add_child(interactTween)
	#interactTween.interpolate_property(touchInteract, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
	
	add_child(lightTween)
	add_child(inventoryTween)
	
	add_child(csTween)
	#csTween.interpolate_property(touchCS, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), 1 , 0, Tween.EASE_OUT, 0)
	
	for key in touchCSTweenDict.keys():
		add_child(touchCSTweenDict[key])
		#touchCSTweenDict[key].interpolate_property(touchCSDict[key], "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
		
	
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

func deactivateCS():
	disableCS = true
	touchCS.hide()
	
func activateCS():
	disableCS = false
	touchCS.show()

#General input
func _input(event): 
	#If input is not from mouse or key
	if (!(event is InputEventKey or event is InputEventMouse or event is InputEventJoypadMotion or event is InputEventJoypadButton)):
		
#		if !(event is InputEventScreenDrag) && !event.is_pressed() && ongoing_cs_drag != -1:
#			print("blah")
			
		
			
			
		if (event.position.x > touchPause.get_global_position().x - touchPauseWidth/2 
		&& event.position.x < touchPause.get_global_position().x + touchPauseWidth/2
		&& event.position.y < touchPause.get_global_position().y + touchPauseHeight/2
		&& (event is InputEventScreenTouch || event is InputEventScreenDrag)):
			joyPause(event)
			return
		
		
		
		elif !pauseToggle:
			#TODO: fix dragging over from jump button or anywhere else
			if (!disableCS && (event.position.x < 150 && event.position.y < 140 && !buttonIsShowing) #&& ongoing_cs_drag != event.get_index()) 
			|| csButtonIsShowing 
			&& (event is InputEventScreenDrag 
				|| (event is InputEventScreenTouch && !event.is_pressed() 
					&& ongoing_cs_drag == event.get_index())  )):
				joyCS(event)
				return
			
			elif (event.position.x > touchLightXBound[0] && event.position.x < touchLightXBound[1]
			&& event.position.y > touchLightYBound[0]):
				joyLight(event)
				return
				
			elif (event.position.x > touchInventoryXBound[0]
			&& event.position.y > touchInventoryYBound[0]):
				joyInventory(event)
				return
			
			#if event is touch onto screen and left half of screen, 
			#OR   if button is showing AND (drag event or meets condition to reset)
			elif ((event.position.x < 640 
				and event is InputEventScreenTouch 
				and event.is_pressed()) 
			or (buttonIsShowing 
				and (event is InputEventScreenDrag 
					or (event is InputEventScreenTouch 
						and !event.is_pressed() 
						and ongoing_drag != -1)))):
				joyStick(event)
				#return
			
			var pos = event.position
			
			#if in the middle, it is an interact signal
			if (canInteract
			and event.position.x >= interactCenter.x - interactWidthHeight/2 
				and event.position.x < interactCenter.x + interactWidthHeight/2
			and event.position.y >= interactCenter.y - interactWidthHeight/2 
				and event.position.y < interactCenter.y + interactWidthHeight/2
			 and event is InputEventScreenTouch):
				joyInteract(event)
				return
	
			#if on the right it is a jump signal
			elif (event.position.x >= 640 and (event is InputEventScreenTouch)): #|| event is InputEventScreenDrag)):
				joyJump(event)
				return
			
			
			
		if pauseToggle:
			joyPauseOptions(event)
			
			
func setInteractAvailable(set: bool):
	if set == null || !set is bool: return
	
	canInteract = set
	
	if !set:
		showInteract(false, false)
	else:
		showInteract(true, false)
		

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
		
		
func showButton(visible):
	
	if (visible):
		touchButton.show()
		#buttonTween.stop_all()
		touchButton.set_modulate(Color(1, 1, 1, 1))
	else:
		buttonTween.interpolate_property(touchButton, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1 , 0, Tween.EASE_OUT, 0)
		buttonTween.start()

func showInteract(visible, pressed):
	var currColor = touchInteract.get_modulate()
	
	
	#interactTween.stop_all()
	if (visible):
		touchInteract.show()
		var alpha = 1 if pressed else 0.25
		interactTween.interpolate_property(touchInteract, "modulate", Color(1, 1, 1, currColor.a), Color(1, 1, 1, alpha), 0.25 , 0, Tween.EASE_OUT, 0)
		#touchInteract.set_modulate(Color(1, 1, 1, 1))
	else:
		interactTween.interpolate_property(touchInteract, "modulate", Color(1, 1, 1, currColor.a), Color(1, 1, 1, 0), 0.5 , 0, Tween.EASE_OUT, 0)
	
	interactTween.start()
		
		
func showLight(pressed):
	var currColor = touchLight.get_modulate()
	
	if (pressed):
		lightTween.interpolate_property(touchLight, "modulate", currColor, Color(1, 1, 1, 1), 0.25 , 0, Tween.EASE_OUT, 0)
	else:
		lightTween.interpolate_property(touchLight, "modulate", currColor, Color(1, 1, 1, 0.25), 0.5 , 0, Tween.EASE_OUT, 0)
	lightTween.start()
	
func showInventory(pressed = null):
	var currColor = touchInventory.get_modulate()
	
	if pressed == null:
		inventoryToggle = !inventoryToggle
	
	pressed = inventoryToggle
	
	if (pressed):
		inventoryTween.interpolate_property(touchInventory, "modulate", currColor, Color(1, 1, 1, 1), 0.25 , 0, Tween.EASE_OUT, 0)
	else:
		inventoryTween.interpolate_property(touchInventory, "modulate", currColor, Color(1, 1, 1, 0.25), 0.5 , 0, Tween.EASE_OUT, 0)
	inventoryTween.start()
	
	
func showCS(visible, pressed):
	if disableCS: return
	csButtonIsShowing = false
	var currColor = touchCS.get_modulate()
	
	
	#csTween.stop_all()
	if (visible):
		print("visible showCS")
		touchCS.show()
		csButtonIsShowing = pressed
		var alpha = 1 if pressed else 0.25
		csTween.interpolate_property(touchCS, "modulate", Color(1, 1, 1, currColor.a), Color(1, 1, 1, alpha), 0.25 , 0, Tween.EASE_OUT, 0)
	else:
		print("NOT visible showCS")
		csTween.interpolate_property(touchCS, "modulate", Color(1, 1, 1, currColor.a), Color(1, 1, 1, 0), 0.5 , 0, Tween.EASE_OUT, 0)
	print(currColor.a)
	csTween.start()
		
func showCSChar(astroChar, visible, selected):
	var tween = touchCSTweenDict[astroChar]
	var node = touchCSDict[astroChar]
	
	var currColor = node.get_modulate()
	
	if (visible):
		node.show()
		#tween.stop(node, "modulate")
		var alpha = 1 if selected else 0.25
		if selected:
			print("blah")
		tween.interpolate_property(node, "modulate", Color(1, 1, 1, currColor.a), Color(1, 1, 1, alpha), 0.25 , 0, Tween.EASE_OUT, 0)
	else:
		tween.interpolate_property(node, "modulate", Color(1, 1, 1, currColor.a), Color(1, 1, 1, 0), 0.5 , 0, Tween.EASE_OUT, 0)
	
	tween.start()
	
func showPause(visible, toggled):
	
	var currColor = touchPause.get_modulate()
	
	if (visible):
		touchPause.show()
		#tween.stop(node, "modulate")
		var alpha = 1 if toggled else 0.25
		
		pauseTween.interpolate_property(touchPause, "modulate", Color(1, 1, 1, currColor.a), Color(1, 1, 1, alpha), 0.25 , 0, Tween.EASE_OUT, 0)
	
		if toggled:
			touchPause_scanBG.show()
			for touchPause_opt in touchPause_options:
				touchPause_opt.show()
		else:
			touchPause_scanBG.hide()
			for touchPause_opt in touchPause_options:
				touchPause_opt.hide()
			
	else:

		pauseTween.interpolate_property(touchPause, "modulate", Color(1, 1, 1, currColor.a), Color(1, 1, 1, 0), 0.5 , 0, Tween.EASE_OUT, 0)
	
	pauseTween.start()

func joyStick(event):
	#if past deadzone radius (threshold), change direction of stick
	if touchStickInner.position.distance_to(-radius) > threshold && ongoing_drag != -1:
		if touchStickInner.position.x > -200:#-radius.x:
			stickDir = Vector2(1, 0)
		elif touchStickInner.position.x < -300:#radius.x:
			stickDir = Vector2(-1, 0)
			
		if touchStickInner.position.y > -200:#radius.y:
			stickDir = stickDir + Vector2(0, 1)
		else:
			stickDir = stickDir + Vector2(0, -1)
			
		print (touchStickInner.position)
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


func joyLight(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			setTouchState("light", TOUCH_STATE.JUST_TOUCHED)
			showLight(true)
		else:
			setTouchState("light", TOUCH_STATE.JUST_RELEASED)
			showLight(false)
	
func joyInventory(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			setTouchState("inventory", TOUCH_STATE.JUST_TOUCHED)
			showInventory()
		else:
			setTouchState("inventory", TOUCH_STATE.JUST_RELEASED)
		#showInventory()

func joyCS(event):
	#if screen touched (and event is "pressed")
	if (event is InputEventScreenTouch and event.is_pressed()):
		setTouchState("cs", TOUCH_STATE.JUST_TOUCHED)
		showCS(true, true)
		for astroChar in global.availableChar:
			showCSChar(astroChar, true, false)
		
	#if dragging or pressed
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.is_pressed()):
		currAstroCharSelection = null
		for astroChar in global.availableChar:
			var i = global.getAstroCharOrderIndex(astroChar)
			if (event.position.y > touchCSTop + (i * touchCSHeight) 
			&&  event.position.y < touchCSTop + ((i+1) * touchCSHeight)):
				showCSChar(astroChar, true, true)
				currAstroCharSelection = astroChar
			else:
				showCSChar(astroChar, true, false)
			
		
		
		#set touch index incase this is first loop
		ongoing_cs_drag = event.get_index()
		
		
	#if no longer touching
	if event is InputEventScreenTouch and !event.is_pressed() and event.get_index() == ongoing_cs_drag:
		ongoing_cs_drag = -1
		setTouchState("cs", TOUCH_STATE.JUST_RELEASED)
		showCS(true, false)
		for astroChar in global.availableChar:
			showCSChar(astroChar, false, false)
		if currAstroCharSelection != null:
			global.initCharSwitch(currAstroCharSelection)

func joyPause(event):
	if (event is InputEventScreenTouch and event.is_pressed()):
		setTouchState("pause", TOUCH_STATE.JUST_TOUCHED)
		pauseToggle = !pauseToggle
		showPause(true, pauseToggle)


func joyPauseOptions(event):
	if (event is InputEventScreenTouch and event.is_pressed()):
		if (event.position.x > touchPause_refPoint.x - touchPause_opt_width/2
		&& event.position.x < touchPause_refPoint.x + touchPause_opt_width/2):
			
			var selectedOpt = null
			var refY = touchPause_refPoint.y - touchPause_opt_height/2
			for i in touchPause_options.size():
				print(refY + (touchPause_opt_height * i))
				if (event.position.y > refY + (touchPause_opt_height * i) 
				&& event.position.y < refY + (touchPause_opt_height * (i+1))):
				
					
					selectedOpt = i
					break
			
			match(selectedOpt):
				2:
					audio.unloadLevelSounds()
		
					
					global.goto_scene(global.lvl().filename, true)
					continue
				3:
					audio.unloadLevelSounds()

					global.replay(true)
					continue
	

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
		
		showButton(true)
	else:
		
		setTouchState("jump", TOUCH_STATE.JUST_RELEASED)
		showButton(false)



func joyInteract(event):
	if !canInteract: return
	if (event is InputEventScreenTouch and event.is_pressed()):
		setTouchState("interact", TOUCH_STATE.JUST_TOUCHED)
		showInteract(true, true)
	else:
		setTouchState("interact", TOUCH_STATE.JUST_RELEASED)
		showInteract(true, false)



