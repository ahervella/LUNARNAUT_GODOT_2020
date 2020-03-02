extends Sprite

#ALEJANDRO (Feb-14-2020)
#don't know if this is finished yet, but idealy the
#script both deadAstros from the first level can extend
#and assign their own text, or possibly make it an editor
#field so that you type in the text via the node.
#Could maybe turn into a shared script by all things that
#Have basic text that shit could extend from?

#ALEJANDRO (Feb-25-2020)
#decided to switch this to a general sound and text interact node

export (String) var AUTO_TEXT = null
export (String) var TEXT_INTERACT = null
export (float) var T_I_DISPLAY_TIME = 0

export (Vector2) var CUSTOM_POSITION_OFFSET = null
export (bool) var FIXED_TEXT = false

export (String) var interactSoundNode = null
export (String) var interactSoundGroup = null

export (String) var showSoundNode = null
export (String) var showSoundGroup = null

export (String) var hideSoundNode = null
export (String) var hideSoundGroup = null

var can_interact : bool = true
var timer : Timer

func Interact():
	if (!can_interact):
		return
	if (T_I_DISPLAY_TIME != 0):
		
		timer = Timer.new()
		add_child(timer)
		timer.set_one_shot(true)
		timer.set_wait_time(T_I_DISPLAY_TIME)
		timer.connect("timeout", self, 'EndOfInteractTimer')
		timer.start()
		
		#global.newTimer(T_I_DISPLAY_TIME, funcref(self, 'AutoInteract'))
	global.interactNode.animateText(TEXT_INTERACT, InteractAudioNode(), CustomPos(), FIXED_TEXT)
	can_interact = false

func EndOfInteractTimer():
	timer.queue_free()
	AutoInteract()

func AutoInteract():
	print("auto interact" + self.name)
	can_interact = true
	TextInteract()

func AutoCloseInteract():
	if (is_instance_valid(timer) && timer.is_class("Timer")):
		timer.stop()
		timer.queue_free()
	
	can_interact = true
	global.interactNode.closeText(HideAudioNode())

	
func TextInteract():
	global.interactNode.animateText(AUTO_TEXT, ShowAudioNode(), CustomPos(), FIXED_TEXT)
	
func CustomPos() -> Vector2:
	return self.get_global_position() + CUSTOM_POSITION_OFFSET

func ShowAudioNode() -> AudioStream:
	if (showSoundNode  == null|| showSoundGroup == null):
		return null
	return audio.sound(showSoundNode, showSoundGroup)
	
func HideAudioNode() -> AudioStream:
	if (hideSoundNode == null || hideSoundGroup == null):
		return null
	return audio.sound(hideSoundNode, hideSoundGroup)
	
func InteractAudioNode() -> AudioStream:
	if (interactSoundNode == null || interactSoundGroup == null):
		return null
	return audio.sound(interactSoundNode, interactSoundGroup)
