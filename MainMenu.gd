extends Node

#ALEJANDRO (Feb-14-2020)
#This is the scrpt for controlling the main menu. It was kind of bitch deciding
#how to go back and forth on all the menus and having preloaded all the videos and shit.
#Part of the difficulty was that upon switching videos and hiding layers and what not,
#there still seems to be a black flicker between switching which = bad. Though I had fixed
#it with my transition methods that would pause for a bit before switching but still seems to be
#there a bit, but not too much that its noticible. Might be nice to leave it as an actual effect
#for screen flickering!
#Getting certain key presses at certain timings was also a bitch with key up and down and pressed
#logic.

var first_one_shot = false
var second_one_shot = false
var play_toggle = false
var pressTracker = 0
var videoIntro
var introPlayer
var videoMenu
var menuPlayer
var videoCred
var videoCredTrans
var credPlayer
var credTransPlayer
var menuTransPlayer
var menuTrans
var videoMenuTrans
var prevVideo
var nextVideo
var startPlayer
var videoStart
var videoMission
var missionPlayer
var credOneShot = true
var canTrans = true

func _ready():
	
	videoIntro = preload("res://VIDEOS/Astro_Menu_Art_INTRO-C.ogv")
	videoMenu = preload("res://VIDEOS/Astro_Menu_Art_MENU-C.ogv")
	videoCred = preload("res://VIDEOS/Astro_Menu_Art_CRED-C.ogv")
	videoCredTrans = preload("res://VIDEOS/Astro_Menu_Art_MTC-C2.ogv")
	videoMenuTrans = preload("res://VIDEOS/Astro_Menu_Art_CTM-C.ogv")
	videoStart = preload("res://VIDEOS/Astro_Menu_Art_START.ogv")
	videoMission = preload("res://VIDEOS/Astro_Menu_Art_MISSION.ogv")
	
	introPlayer = $"Intro"
	menuPlayer = $"MenuLOOP"
	credPlayer = $"Cred"
	credTransPlayer = $"CredTrans"
	menuTransPlayer = $"MenuTrans"
	startPlayer = $"Start"
	missionPlayer = $"Mission"
	
	introPlayer.set_stream(videoIntro)
	menuPlayer.set_stream(videoMenu)
	credPlayer.set_stream(videoCred)
	credTransPlayer.set_stream(videoCredTrans)
	menuTransPlayer.set_stream(videoMenuTrans)
	startPlayer.set_stream(videoStart)
	missionPlayer.set_stream(videoMission)
	
	get_node("Blackness").hide()
	introPlayer.show()
	introPlayer.set_stream_position(13.5)
	menuPlayer.hide()
	introPlayer.play()
	credPlayer.hide()
	credTransPlayer.hide()
	menuTransPlayer.hide()
	startPlayer.hide()
	missionPlayer.hide()
	
	print(introPlayer.get_stream_position())
	introPlayer.set_stream_position(13)
	print(introPlayer.get_stream_position())
	
func _input(event):
	if ((event is InputEventKey  && !event.is_echo()) or (InputEventScreenTouch && event.is_pressed())) && !(event is InputEventMouse):
		#first press, becomes true
		#print(event)
		#first release, becomes false
		#second press becomes true
		if event is InputEventKey :
			play_toggle = !play_toggle
		
		if menuPlayer.is_playing() and first_one_shot && ((event is InputEventKey && play_toggle) or event is InputEventScreenTouch):
			if (event is InputEventKey && (!event.scancode == KEY_C)) or (event is InputEventScreenTouch && event.position.x < 800) && !(event is InputEventMouseButton):
				credOneShot = true
				first_one_shot = false
				#print("step0")
				missionTimeOut()
				#TransitionMenu(menuPlayer, missionPlayer)
				#global.newTimer(self, 30, true, "missionTimeOut")
			elif (!(event is InputEventMouseButton)):
				#print("step99")
				TransitionMenu(menuPlayer, credTransPlayer)
			
		if get_node("Intro").is_playing() && first_one_shot == false:
			first_one_shot = true
			#print("step1")
			TransitionMenu(introPlayer, menuPlayer)
			
		if credPlayer.is_playing() and ((event is InputEventKey && play_toggle) or (event is InputEventScreenTouch)) && !(event is InputEventMouseButton):
			credOneShot = false
			first_one_shot = false
			second_one_shot = false
			play_toggle = false
			#print("step3")
			TransitionMenu(credPlayer, menuTransPlayer)
		
			
			
		
		
		
func on_tween_finished(object, key):
	var ref = funcref(self, 'onDelayTimeout')
	global.newTimer(1, ref)
	
	#global.goto_scene("res://main_scene.tscn")

func onDelayTimeout():
	TransitionMenu(menuPlayer, missionPlayer)


func _on_Intro_finished():
	first_one_shot = true
	TransitionMenu(introPlayer, menuPlayer)


func _on_MenuLOOP_finished():
	menuPlayer.play()


func _on_CredTrans_finished():
	TransitionMenu(credTransPlayer, credPlayer)


func _on_Cred_finished():
	credPlayer.play()


func _on_MenuTrans_finished():
	TransitionMenu(menuTransPlayer, menuPlayer)
	play_toggle = true
	first_one_shot = true


func TransitionMenu(preV, nextV):
	if(canTrans):
		canTrans = false
		prevVideo = preV
		nextVideo = nextV
		
		nextVideo.show()
		nextVideo.play()
		#nextVideo.show()
		#func newTimer(object, time, oneshot, timeoutConnection):
		var ref = funcref(self, 'TransFin')
		global.newTimer(0.2, ref)
	
func FirstTransFin():
	nextVideo.show()
	var ref = funcref(self, 'TransFin')
	global.newTimer(0.1, ref)

func TransFin():
	#nextVideo.show()
	prevVideo.stop()
	prevVideo.hide()
	
	prevVideo = null
	nextVideo = null
	canTrans = true
	
	

func _on_Start_finished():
	global.goto_scene("res://SCENES/CharSelect.tscn")
	#global.loadLevel(1)


func missionTimeOut():
	get_node("Blackness").show()
	var cur_color = $"Blackness".get_modulate()
	var cur_g = cur_color.g
	var cur_r = cur_color.r
	var cur_b = cur_color.b
	var tweenyy = Tween.new()
	add_child(tweenyy)
	$"Blackness".set_modulate( Color(cur_r, cur_g, cur_b, 0))
	#last numbre is delay for starting tween
	tweenyy.interpolate_property($"Blackness", "modulate", Color(cur_r, cur_g, cur_b,0), Color(cur_r, cur_g, cur_b, 1), 2 , 0, Tween.EASE_OUT, 0)
	tweenyy.connect("tween_completed", self, "on_tween_finished")
	tweenyy.start()


func _on_Mission_finished():
	TransitionMenu(missionPlayer, startPlayer)
