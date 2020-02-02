extends RichTextLabel

var draw_next_letter = true
var blink = true
var texttt
var timer
var e = global.get("pressing_e")
var reverse_one_shot = false

var bodies = []

var one_shot_door_access = true
var one_shot_door_try = true
var can_prompt_message = true
var cinematicBoomPlayed = false

func _ready():
	#set_as_toplevel(true)

	$"/root/Control/astro/Item_check".connect("area_entered", self, "_on_astro_area_entered")
	$"/root/Control/astro/Item_check".connect("area_exited", self, "_on_astro_area_exited")
	
	set_override_selected_font_color(true)



func _process(delta):
	#script var "bodies" is updated every time shit enters or exists astro"
	#using "has key" global variable for one shot, makes sense
	var pressing_e = global.get("pressing_e")
	var vInteract = $"/root/Control/Cam2D/CanvasLayer/joyOut/joyIn".interacting()
		
	var has_no_key = !global.get("has_key")
	var spawn_key = global.get("spawn_key")
	var current_has = global.get("current_interact")
	if ((pressing_e or vInteract) and current_has=="key" and has_no_key):# and spawn_key):
		global.set("has_key", true)
		playGotItemSound()
		_on_astro_area_entered(bodies)


	if (!global.get("doorOpened") && current_has == "door"):
		#can_prompt_message is used just for prompting to hit e
		#one_shot_door_try is for when hitting e and for timer reasons in RefreshType
		#print("yesy")
		#print(!(pressing_e or vInteract))
		#print (can_prompt_message)
		#print(one_shot_door_try)
		if (!(pressing_e or vInteract) && can_prompt_message && one_shot_door_try):
			can_prompt_message = false
			
			global.set("spawn_key", true)
			#prevents weird cursor blinking
			#remove_child(timer)
			
			animateText("**ENTER_ LAB_ ACCESS_ CODE")
			set("custom_colors/default_color", Color(255,140,0))
			#SOUND EFFECTS
			playTextSound()
				
		if ((pressing_e or vInteract) && one_shot_door_try):
			one_shot_door_try = false
			
			if (has_no_key):
				#prevents weird cursor blinking
				#remove_child(timer)
				
				global.set("spawn_key", true)
				animateText("**ACCESS_ DENIED")
				set("custom_colors/default_color", Color(255,0,0))
				#SOUND EFFECTS
				playTextSound()
			else:
				#prevents weird cursor blinking
				#remove_child(timer)
				
				global.set("doorOpened", true)
				animateText("**ACCESS_ GRANTED")
				set("custom_colors/default_color", Color(0,255,0))
				#SOUND EFFECTS
				playTextSound()
				playGotItemSound()
				$"/root/Control/lab_above/lab_above_1".show()
				$"/root/Control/astro/doorOpenSound".play(0)
				$"/root/Control/door_left".openDoor()
				$"/root/Control/door_left_shade".openDoor()
			
			global.newTimerOLD(self, 4, true, "RefreshPrompt")
			
			
	if ((pressing_e or vInteract) and current_has=="dead1"):
		#remove_child(timer)
		
		set_current_interact(null)
		playTextSound()
		$"/root/Control/deadAstro1".PlayMessage()
		animateText(">>' I REPEAT, SEAL THE MAIN DO-- '")
		
	if ((pressing_e or vInteract) and current_has=="dead2"):
		remove_child(timer)
		
		set_current_interact(null)
		#PLAY DIFFERENT SOUND
		playTextSound()
		$"/root/Control/deadAstro2".PlayMessage()
		animateText(">>' TOM I'M SORRY. I LOVE YOU'")
	
	if ((pressing_e or vInteract) and current_has == "report"):
		#remove_child(timer)
		set_current_interact(null)
		playTextSound()
		animateText(">>' SPECIMEN HAS POOR SENSE OF SURROUNDING '")

func RefreshPrompt():
	var bodyTrig = $"/root/Control/door_left"
	
	#doing this makes text tween out and resets current interact to null
	#making shit in process fail the if statements
	if (global.get("current_interact") == "door"):
		_on_astro_area_exited(bodyTrig)
		global.newTimerOLD(self, 0.5, true, "RefreshType")
	
func RefreshType():
	set_current_interact("door")
	
	#already done in area_exited but just in case
	can_prompt_message = true
	one_shot_door_try = true

#Sets the current interactive item or thing in the global variable
func set_current_interact(name):
	global.set("current_interact", name)


# vvvvvvvvvvvvv ALL FOR ANIMATING PROPER TEXT vvvvvvvvvvvvv

func timer_reset(text):
	if (blink):
		set_text(str(text, "_"))

	else: set_text(text)

	timer = Timer.new()
	add_child(timer)
	timer.set_one_shot(true)
	timer.set_wait_time(1)
	timer.connect("timeout", self, "on_timeout_complete")
	timer.start()
	if (global.get("pressing_e")):
		pass
#
func on_timeout_complete():
	blink = !blink
	timer_reset(texttt)




func set_text_pos(setting):
	var offSetFlipX
	var get_flip = get_node("/root/Control/astro/ASTRO_ANIM2").is_flipped_h()
	
	if (get_flip):
		offSetFlipX = 44
	else:
		offSetFlipX = -120
	
		
	if (setting == "default"):
		set_as_toplevel(false)
		

		self.set_position(Vector2 (offSetFlipX, -15))

		#set_as_toplevel(true)
	if (setting == "key_needed"):
		set_as_toplevel(false)
		self.set_position(Vector2 (-140, -30))
		
	if (setting == "download_key" or setting == "deadAstro1" or setting == "deadAstro2"):
		
		var node_pos = get_node("/root/Control/caveKey").get_global_position()
		set_as_toplevel(true)
		
		match (setting):
			"deadAstro1":
				node_pos = get_node("/root/Control/deadAstro1").get_global_position()
				
			"deadAstro2":
				node_pos = get_node("/root/Control/deadAstro2").get_global_position()
		
		#set_position(Vector2 (astro_pos.x + 140, astro_pos.y -15))
		set_position(Vector2 (node_pos.x , node_pos.y + 40))
		
	if (setting == "report"):
		set_as_toplevel(true)
		
		var node_pos = $"//root/Control/labReportArea".get_global_position()
		set_position(node_pos)
		
		#makes it so that in process, the position of the text is constant
		#set_position($"astro".get_global_position())



func animateText(text):
	remove_child(timer)

	self.set_text(text)
	texttt = text
	var text_time = 0.5
	get_node("Text").interpolate_property(self, "percent_visible", 0, 1, text_time , 0, Tween.EASE_OUT)
	get_node("Text").start()
	timer_reset(text)

#^^^^^^^^^^^^^^ ALL FOR ANIMATING PROPER TEXT ^^^^^^^^^^^^^^



#setting proper text depending on when shit enters astro
func _on_astro_area_entered(body):
	bodies = body
	var groups = body.get_groups()
	var o2 = groups.has("o2")

	#For oxygen tank items:
	if (o2):
		if(body.get_parent().get_animation() == "GREEN"):
			playTextSound()
			set_text_pos("default")
			animateText("OXYGEN")
			set("custom_colors/default_color", Color(0,255,255))
			
			#sets global for current item as o2
			set_current_interact("o2")

#CODE FOR DOOR AND SHIP 
#**NOTE** : These functions act as one shots when astro enters something
#except when called in process. Need one shot with hitting "e"
#vvvvvvvv

	var door = groups.has("door")
	var key = groups.has("key")
	var has_key = global.get("has_key")
	var spawn_key = global.get("spawn_key")
	var deadAstro1 = groups.has("dead1")
	var deadAstro2 = groups.has("dead2")
	var report = groups.has("report")
	#For the first lab door:
	if (door):
		set_current_interact("door")
			
		
		set_text_pos("key_needed")

	
#removed spawn key
	if (key ):
		set_current_interact("key")
		bodies = body
		
		set_text_pos("download_key")
		
		if (!has_key):
			playTextSound()
			animateText(">>DOWNLOAD_ LAB_ ACCESS_ CODE")
			set("custom_colors/default_color", Color(0,255,255))
			#only affected by physics proccess above and if hit e
		elif (has_key):
			if (reverse_one_shot):
				playTextSound()
			animateText("<<LAB_CODE_ DOWNLOADED")
			set("custom_colors/default_color", Color(0,255, 0))
			$"/root/Control/caveKey".set_animation("RED")
			reverse_one_shot = true
		
		
	if (deadAstro1 ):
		set_text_pos("deadAstro1")
		playTextSound()
		animateText(">>REPLAY_ LAST_  MESSAGE")
		set("custom_colors/default_color", Color(255, 140, 0))
		set_current_interact("dead1")
		
	if (deadAstro2 ):
		set_text_pos("deadAstro2")
		playTextSound()
		animateText(">>REPLAY_ LAST_  MESSAGE")
		set("custom_colors/default_color", Color(255, 140, 0))
		set_current_interact("dead2")
	
	if ((deadAstro1 or deadAstro2) and !cinematicBoomPlayed):
		$"/root/Control/astro/cinematicBoom2".play(0)
		
	if (report):
		set_text_pos("report")
		playTextSound()
		animateText(">>VIEW_ LAST_ EXPERIMENT_ REPORT")
		set("custom_colors/default_color", Color(255, 140, 0))
		set_current_interact("report")
	
func playTextSound():
	$"/root/Control/astro/doorTextSound".play(0)

func playGotItemSound():
	$"/root/Control/astro/gotKeySound".play(0)

#if there's an item that exited astro
func _on_astro_area_exited(body):
	var groups = body.get_groups()
	var door = groups.has("door")
	var key = groups.has("key")
	var o2 = groups.has("o2")
	var has_key = global.get("has_key")
	var deadAstro1 = groups.has("dead1")
	var deadAstro2= groups.has("dead2")
	var report= groups.has("report")
	
	print(groups)
	
	if (deadAstro1 or deadAstro2 or o2 or key or report or (door and one_shot_door_access)):
		
		if (o2):
			if(body.get_parent().get_animation() == "RED"):
				body.remove_from_group("o2")
		
		if (door and one_shot_door_access and has_key):
			one_shot_door_access = false
		
		if (door && !global.get("doorOpened")):
			one_shot_door_try = true
			can_prompt_message = true
			
		#astro can now not interact with anything
		set_current_interact(null)
		
		
		#make text disapear
		var perVisibile = self.get_percent_visible()
		get_node("Text").stop_all()
		get_node("Text").interpolate_property(self, "percent_visible", perVisibile, 0, 0.2 , 0, Tween.EASE_OUT)
		get_node("Text").start()
		remove_child(timer)
		set_current_interact(null)
	

