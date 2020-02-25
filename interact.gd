extends RichTextLabel

#ALEJANDRO (Feb-14-2020)
#This is the main script for displaying text for in game
#near astro for all interactable objects. A lot of this was copied from the
#old interact and modified to be much better. I beleieve this is basically done
#and just need to have interact architecture be impleneted on all object

#ALEJANDRO (Feb-24-2020)
#renaed from interacttt to interact.gd!
#bickering with an mem allocating bug so decided to just do it
#manually here :( (for animate text)
# reasons for that could be:
	#multiple instances of the astrooo.gd script being loaded within the astro scene and level 1
	#problem with godot source code and order of freeing shit? (in conjunction with returning pointers)
	#shit happening at same time on frame (like starting a timer 
		#and tween, or on the frame after being freed, etc.

var blink = true
var currentText
var timer
const TYPE_TEXT_TIME = 0.5
const REMOVE_TEXT_TIME = 0.2
var textTweeen : Tween
var breakTimerLoop = false

# vvvvvvvvvvvvv ALL FOR ANIMATING PROPER TEXT vvvvvvvvvvvvv

func timer_reset(text):
	if (breakTimerLoop):
		breakTimerLoop = false
		return
		
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
	
	#var ref = funcref(self, 'on_timeout_complete')
	#global.newTimer(1, ref)
	
#
func on_timeout_complete():
	blink = !blink
	timer.queue_free()
	#timer = null
	print("blinking timer working")
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

	timer_reset(currentText)
	
	set_text_pos(customPosOffset, topLevel)
	self.set_text(currentText)
	
	#had to do this manually due to memory allocating issue with ref
	#-ing the textTweeen
	textTweeen = Tween.new()
	add_child(textTweeen)
	#textTweeen.connect("tween_completed", self, "closeText", [textTweeen])
	textTweeen.interpolate_property(self, 'percent_visible', 0, 1, TYPE_TEXT_TIME , 0, Tween.EASE_OUT)#global.newTweenNoConnection(self, "percent_visible", 0, 1, TYPE_TEXT_TIME, 0)
	textTweeen.start()
	
	

	if (soundNode != null):
		soundNode.play(0)

	#if has provided textTime 
	#if (textTime != null):
	#	var ref = funcref(self, 'closeText')
	#	global.newTimer(3, ref)

#make text disapear
func closeText():
#
	var perVisibile = self.get_percent_visible()
	
	#if the tween hasn't been freed via the global newTweenNoConnection signal (as in, 
	#it is still tweening the text to show and we need to closeText() prematurely,
	#then this should not be null, and stop all!
	self.set_percent_visible(perVisibile)
	
	textTweeen.stop_all()
	textTweeen.queue_free()
	
	
	
	global.newTween(self, "percent_visible", perVisibile, 0, REMOVE_TEXT_TIME, 0, self, "setPerVisZero")
	
#seemed to be a bug where the whole text would flash for a single frame,
#little hack to tryyyy to get aorund that (or at least make it happen less often...)
func setPerVisZero(object, key):
	#don't know if this helps with the flicker problem
	self.set_percent_visible(0)
	self.set_text("")
	breakTimerLoop = true
	
	

#^^^^^^^^^^^^^^ ALL FOR ANIMATING PROPER TEXT ^^^^^^^^^^^^^^