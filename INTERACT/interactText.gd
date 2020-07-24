extends Label

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
var currentText = ""
var timer
var timerUniqueID

#default time for text to type
const TYPE_TEXT_TIME = 0.5
const REMOVE_TEXT_TIME = 0.2

#default offset and textbox size for interactive text
const POS_OFFSET = Vector2(44, -15)
const LOCAL_SIZE = Vector2(125, 116)

#horizontal offset used if there are multiple interactNodes
#being used
var multiInterNodeOffset = 0

#is overriden if multiple interactNodes in use so that
#all are aligned on one side
var overrideFlip = null

#is stored so that other interactNodes can access and set theirs accordingly
#inorder to line up properly
var textLength = 0

#used to be able to re animate self if textLength changes
var animateTextArgs 

#store flip state to override other interactNodes in global
#if multiple interactNodes are being used
var flip = null

#these are pulled in the astro script to know how to place text
var totalOffset : Vector2 = Vector2(0,0)
var fixedOffset : bool = false

var textTween : Object
var textTweenUniqueID : String
var breakTimerLoop = false


var ASTRO_NODE_PATH = null
var ASTRO_NODE# = get_node(ASTRO_NODE_PATH)

var parentInteractObject = null

# vvvvvvvvvvvvv ALL FOR ANIMATING PROPER TEXT vvvvvvvvvvvvv

func _ready():
	if ASTRO_NODE_PATH != null:
		ASTRO_NODE = get_node(ASTRO_NODE_PATH)
	call_deferred("ready_deferred")

func ready_deferred():
	if ASTRO_NODE_PATH != null:
		ASTRO_NODE = get_node(ASTRO_NODE_PATH)

func timer_reset(text):
	
	#need to to do this or else timers stack up on eachother for somereason, despite being
	#called to self destroy when they are done running
	#been needing to check class due to mem reassigning bug, then make it null anyways
	#in case it is pointing to something bogus
	if (is_instance_valid(timer) && timer.is_class("Timer") && timerUniqueID == timer.to_string()):
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
	timerUniqueID = timer.to_string()
#
func on_timeout_complete():
	blink = !blink
	timer_reset(currentText)




func set_text_pos(customOffset, fixedText, textSidePosition):
	#print("multiInterNodeOffset")
	#print(multiInterNodeOffset)
	fixedOffset = fixedText
	if (fixedText):
		totalOffset = customOffset + Vector2(0, multiInterNodeOffset)
		return
	
	
	#logic for deciding on which side to of astro to draw text
	#can be set manually via animateText
	var get_flip

	print(textSidePosition)
	if (textSidePosition == 1):
		get_flip = false
	elif (textSidePosition == -1):
		get_flip = true
	elif (textSidePosition == 1):
		get_flip = ASTRO_NODE.get_node("ASTRO_ANIM2").is_flipped_h()
	else:
		get_flip = !ASTRO_NODE.get_node("ASTRO_ANIM2").is_flipped_h()

	textLength = min (get("custom_fonts/font").get_wordwrap_string_size(text, get_size().x).x, get("custom_fonts/font").get_string_size(text).x)
	
	var longestTextLength = textLength
	
	var reAnimateInteractNodes = []
	
	for interNode in global.interactNodes:
		if interNode == null || interNode == self: continue
		flip = interNode.flip
		if interNode.overrideFlip != null:
			overrideFlip = interNode.overrideFlip
		longestTextLength = max(longestTextLength, interNode.textLength)
		
		if longestTextLength > interNode.textLength:
			interNode.textLength = longestTextLength
			reAnimateInteractNodes.append(interNode)
			
				
	textLength = longestTextLength
			
	flip = overrideFlip if overrideFlip != null else get_flip

	if (flip):
		
		
		for interNode in reAnimateInteractNodes:
			var args = interNode.animateTextArgs
			if args != null:
				interNode.call("animateText", args[0], args[1], args[2], args[3], args[4], args[5])
		#little hack that adjusts the facing left offset if the text typed doesn't
		#take up the whole width of the text box
		#get_text().length()
		
		#var pixelOffSet = 12
		#if (textLength < 12):
		#	pixelOffSet = fmod(textLength, 12)
		#pixelOffSet *= (LOCAL_SIZE.x / 13.0)
		
		totalOffset = Vector2(-POS_OFFSET.x - max(longestTextLength, textLength) -customOffset.x, POS_OFFSET.y + customOffset.y + multiInterNodeOffset) 
		
		return
	
	totalOffset = POS_OFFSET + customOffset + Vector2(0, multiInterNodeOffset)
	


func animateTutorialText(textConfig):#, textTime = null):
	currentText = textConfig.text
	timer_reset(currentText)
	
	var vpSize = get_viewport().get_size()
	var textXSpacePercent = 0.8
	
	self.set("custom_colors/font_color", textConfig._getColor())
	self.set_text(currentText)
	get("custom_fonts/font").set("size", 80)
	set("rect_size", Vector2(vpSize.x * textXSpacePercent, get_size().y))
	
	
	var wordWrapSize = get("custom_fonts/font").get_wordwrap_string_size(currentText, get_size().x).x
	var strSize = get("custom_fonts/font").get_string_size(text).x
	textLength = min (wordWrapSize, strSize)
	
	var width = min(textLength, vpSize.x * textXSpacePercent)
	var textVect = global.getRealTextVector2(currentText, width, get("custom_fonts/font"))
	
	textTween = global.newTween(self, "percent_visible", 0, 1, TYPE_TEXT_TIME, 0)
	textTweenUniqueID = textTween.to_string()
	
	audio.sound("textShow").play(0)
	
	
	var xPos = (vpSize.x - textVect.x) / 2
	var yPos = vpSize.y - textVect.y
	set_global_position(Vector2(xPos, yPos))#global.lvl().astroNode.get_global_position())
	


func animateText(text, soundNode = null, customPosOffset = Vector2(0,0),
				fixedText = false, textSide : int = 0, textTime = null):
	animateTextArgs = []
	animateTextArgs.resize(6)
	animateTextArgs = [text, soundNode, customPosOffset, fixedText, textSide, textTime]
	#optional time for tween
	#need to store locally to add blinking underscore affect in timers above
	
	currentText = text.text
	
	for interNodeIndex in global.interactNodes.size():
		global.setInterNodeVerticalOffset(interNodeIndex)

	#reset the blinking timer
	timer_reset(currentText)
	
	#assign text to text box
	self.set("custom_colors/font_color", text._getColor())
	self.set_text(currentText)
	
	#set the text position
	set_text_pos(customPosOffset, fixedText, textSide)
	
	
	#if no specific typing time given, set to default
	if (textTime == null || textTime == 0):
		textTime = TYPE_TEXT_TIME
		
	
	textTween = global.newTween(self, "percent_visible", 0, 1, textTime, 0)
	textTweenUniqueID = textTween.to_string()
	

	if soundNode == null:
		soundNode = audio.sound("textShow")
	soundNode.play(0)


func closeText(soundNode = null):
	print("closetext")
	var perVisibile = self.get_percent_visible()
	
	#if the tween hasn't been freed via the global newTween signal (as in, 
	#it is still tweening the text to show and we need to closeText() prematurely,
	#then stop the tween and clean up
	#added to check the unique id so it doesn't delete something random in memery
	if (is_instance_valid(textTween) && textTween.is_class("Tween") && textTweenUniqueID == textTween.to_string()):
		#seems to be running into a bug where it points to some random thing in mem occasionally after I queue free it,
		#so here I check to make sure its a tween before calling stuff
		textTween.stop_all()
		textTween.call_deferred('free')
			
	#make our var not point to a random thing in memory (from weird bug)
	else:
		textTween = null
	global.newTween(self, "percent_visible", perVisibile, 0, REMOVE_TEXT_TIME, 0, funcref(self, 'selfDestruct'))
	
	if soundNode == null:
		soundNode = audio.sound("textHide")
	soundNode.play(0)
	
	breakTimerLoop = true
	
func selfDestruct():
	print("selfDestructed")
	global.destroyInteractNode(self)

#^^^^^^^^^^^^^^ ALL FOR ANIMATING PROPER TEXT ^^^^^^^^^^^^^^
