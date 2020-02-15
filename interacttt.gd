extends RichTextLabel

#ALEJANDRO (Feb-14-2020)
#This is the main script for displaying text for in game
#near astro for all interactable objects. A lot of this was copied from the
#old interact and modified to be much better. I beleieve this is basically done
#and just need to have interact architecture be impleneted on all object

var blink = true
var currentText
var timer
const TYPE_TEXT_TIME = 0.5

# vvvvvvvvvvvvv ALL FOR ANIMATING PROPER TEXT vvvvvvvvvvvvv

func timer_reset(text):
	if (blink):
		set_text(str(text, "_"))

	else:
		set_text(text)
		
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
	timer_reset(currentText)




func set_text_pos(offsetLocation, topLevel):
	var offSetFlipX
	var get_flip = get_node("/root/Control/astro/ASTRO_ANIM2").is_flipped_h()
	
	if (get_flip):
		offSetFlipX = -120
	else:
		offSetFlipX = 44
	
		
	#if (setting == "default"):
	set_as_toplevel(topLevel)
		
	print("text pos x:")
	print(offsetLocation.x)

	print("text pos y:")
	print(offsetLocation.y)

	self.set_position(Vector2 (offSetFlipX + offsetLocation.x, -15 + offsetLocation.y))
	#self.set_position(Vector2 (offSetFlipX , -15 ))

		#set_as_toplevel(true)
#	if (setting == "key_needed"):
#		set_as_toplevel(false)
#		self.set_position(Vector2 (-140, -30))
#		
#	if (setting == "download_key" or setting == "deadAstro1" or setting == "deadAstro2"):
#		
#		var node_pos = get_node("/root/Control/caveKey").get_global_position()
#		set_as_toplevel(true)
#		
#		match (setting):
#			"deadAstro1":
#				node_pos = get_node("/root/Control/deadAstro1").get_global_position()
#				
#			"deadAstro2":
#				node_pos = get_node("/root/Control/deadAstro2").get_global_position()
#		
#		#set_position(Vector2 (astro_pos.x + 140, astro_pos.y -15))
#		set_position(Vector2 (node_pos.x , node_pos.y + 40))
#		
#	if (setting == "report"):
#		set_as_toplevel(true)
#		
#		var node_pos = $"//root/Control/labReportArea".get_global_position()
#		set_position(node_pos)
		
		#makes it so that in process, the position of the text is constant
		#set_position($"astro".get_global_position())



func animateText(text, soundNode = null, customPosOffset = Vector2(0,0), topLevel = false, textTime = null): #optional time for tween
	currentText = text
	remove_child(timer)
	set_text_pos(customPosOffset, topLevel)
	self.set_text(currentText)
	
	get_node("Text").interpolate_property(self, "percent_visible", 0, 1, TYPE_TEXT_TIME , 0, Tween.EASE_OUT)
	get_node("Text").start()
	timer_reset(currentText)

	if (soundNode != null):
		soundNode.play(0)

	#if has provided textTime 
	if (textTime != null):
		var ref = funcref(self, 'closeText')
		global.newTimer(3, ref)

#make text disapear
func closeText():
	#get current percent visible
	var perVisibile = self.get_percent_visible()
	get_node("Text").stop_all() # stop all tweens
	#make tween to close
	get_node("Text").interpolate_property(self, "percent_visible", perVisibile, 0, 0.2 , 0, Tween.EASE_OUT)
	get_node("Text").start()
	remove_child(timer)
	#set_current_interact(null)

#^^^^^^^^^^^^^^ ALL FOR ANIMATING PROPER TEXT ^^^^^^^^^^^^^^