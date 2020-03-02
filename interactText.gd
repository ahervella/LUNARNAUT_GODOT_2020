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


#ALEJANDRO (Mar-01-2020)
#after trying a bunch of shit, I've gotten around mem re pointing bogus bugs by checking to make sure
#the variable in question is of the type of class I want (while also using the is_instance_valid()) to properly
#clean things up here. The global tweens and timers now also return a copy of them to used if desired, and just
#have to be careful about cleaning up

var blink = true
var currentText
var timer

#default time for text to type
const TYPE_TEXT_TIME = 0.5
const REMOVE_TEXT_TIME = 0.2

#default offset and textbox size for interactive text
const POS_OFFSET = Vector2(44, -15)
const LOCAL_SIZE = Vector2(125, 116)

#these are pulled in the astro script to know how to place text
var totalOffset : Vector2 = Vector2(0,0)
var fixedOffset : bool = false


var textTweeen : Tween
var breakTimerLoop = false

var ASTRO_NODE_PATH = null
onready var ASTRO_NODE = get_node(ASTRO_NODE_PATH)


# vvvvvvvvvvvvv ALL FOR ANIMATING PROPER TEXT vvvvvvvvvvvvv

func timer_reset(text):
	
	#need to to do this or else timers stack up on eachother for somereason, despite being
	#called to self destroy when they are done running
	#been needing to check class due to mem reassigning bug, then make it null anyways
	#in case it is pointing to something bogus
	if (is_instance_valid(timer) && timer.is_class("Timer")):
		timer.call_deferred('free')
	timer = null
	
	if (breakTimerLoop):
		breakTimerLoop = false
		return
		
	if (blink):
		set_text(str(text, "_"))

	else:
		set_text(text)
		
		
	
	timer = global.newTimer(1, funcref(self, 'on_timeout_complete'))
	
#
func on_timeout_complete():
	blink = !blink
	timer_reset(currentText)




func set_text_pos(customOffset, fixedText):
	
	fixedOffset = fixedText

	if (fixedText):
		totalOffset = customOffset
		return
	
	var get_flip = ASTRO_NODE.get_node("ASTRO_ANIM2").is_flipped_h()

	if (get_flip):
		totalOffset = Vector2(-POS_OFFSET.x - LOCAL_SIZE.x -customOffset.x, POS_OFFSET.y + customOffset.y)
		return
	
	totalOffset = POS_OFFSET + customOffset
	



func animateText(text, soundNode = null, customPosOffset = Vector2(0,0), fixedText = false, textTime = null): #optional time for tween
	#need to store locally to add blinking underscore affect in timers above
	currentText = text
	#used for checking things are properly cleaning up
#	print("animating")
#	print(get_child_count())
#	print(get_child(0))
	print(global.get_child_count())
	print(global.get_children())

	#reset the blinking timer
	timer_reset(currentText)
	
	#set the text position
	set_text_pos(customPosOffset, fixedText)
	#assign text to text box
	self.set_text(currentText)
	
	#if no specific typing time given, set to default
	if textTime == null:
		textTime = TYPE_TEXT_TIME
		
	
	textTweeen = global.newTweenNoConnection(self, "percent_visible", 0, 1, textTime, 0)
	
	

	if soundNode == null:
		soundNode = audio.sound("textShow")
	soundNode.play(0)


func closeText(soundNode = null):
#
	var perVisibile = self.get_percent_visible()
	
	#if the tween hasn't been freed via the global newTweenNoConnection signal (as in, 
	#it is still tweening the text to show and we need to closeText() prematurely,
	#then stop the tween and clean up
	if (is_instance_valid(textTweeen)):
		#seems to be running into a bug where it points to some random thing in mem occasionally after I queue free it,
		#so here I check to make sure its a tween before calling stuff
		if (textTweeen.is_class("Tween")):
			textTweeen.stop_all()
			textTweeen.call_deferred('free')
			
	#make our var not point to a random thing in memory (from weird bug)
	textTweeen = null
	
	
	global.newTweenNoConnection(self, "percent_visible", perVisibile, 0, REMOVE_TEXT_TIME, 0)
	
	if soundNode == null:
		soundNode = audio.sound("textHide")
	soundNode.play(0)
	
	breakTimerLoop = true
	

#^^^^^^^^^^^^^^ ALL FOR ANIMATING PROPER TEXT ^^^^^^^^^^^^^^