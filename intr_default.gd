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
enum TEXT_SIDE {LEFT = -1, RIGHT = 1, DYNAMIC = 0}

export (String) var AUTO_TEXT = null
export (String) var TEXT_INTERACT = null
export (float) var T_I_DISPLAY_TIME = 0

export (Vector2) var CUSTOM_POSITION_OFFSET = Vector2(0, 0)
export (bool) var FIXED_TEXT = false

export (TEXT_SIDE) var TEXT_POSITION = TEXT_SIDE.DYNAMIC
var TEXT_POSITION_INT

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
		
		timer = global.newTimer(T_I_DISPLAY_TIME, funcref(self, 'AutoInteract'))
		
	global.interactNode.animateText(TEXT_INTERACT, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)
	can_interact = false

func AutoInteract():
	can_interact = true
	TextInteract()

func AutoCloseInteract():
	if (is_instance_valid(timer) && timer.is_class("Timer")):
		timer.stop()
		timer.call_deferred('free')
	
	can_interact = true
	global.interactNode.closeText(HideAudioNode())

	
func TextInteract():
	global.interactNode.animateText(AUTO_TEXT, ShowAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)
	

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
