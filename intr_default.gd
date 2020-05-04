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

export (Resource) var TC_AUTO = null
export (Resource) var TC_INTERACT = null
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

export (Array, Resource) var itemsGained
export (Array, Resource) var itemsRequired
export (bool) var eatRequirements = false

var can_interact : bool = true
export (bool) var oneshot = false
var timer : Timer

#used in case multiple items that interact with eachother at once
#such as with plugs/cables
var processed = false

func Interact():
	# If we can't interact, bail
	if (!can_interact):
		return

	# Check to make sure we have all the items we need, otherwise bail
	if (itemsRequired != null && itemsRequired.size() > 0):
		if (!get_tree().get_current_scene().CheckHasInventoryItems(itemsRequired, false)):
			return

	# Do some timer stuff
	if (T_I_DISPLAY_TIME != 0):		
		timer = global.newTimer(T_I_DISPLAY_TIME, funcref(self, 'AutoInteract'))
	
	# Eat the items we need if we're supposed to
	if (itemsRequired != null && itemsRequired.size() > 0 && eatRequirements):
		get_tree().get_current_scene().CheckhasInventoryItems(itemsRequired, true)

	# Give us items if we're supposed to	
	get_tree().get_current_scene().AddInventoryItems(itemsGained)

	# Update text for items we got
	if (itemsGained != null && itemsGained.size() > 0):
		for iq in itemsGained:
			TC_INTERACT.text = "%s\nGained %d %s" % [TC_INTERACT.text,iq.quantity, iq.item.Name]

	# Display text
	global.interactNode.animateText(TC_INTERACT, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)

	# If oneshot, then we all done
	if (oneshot):
		can_interact = false


var addedItemsToAuto = false;

func AutoInteract():
	if (!oneshot):
		can_interact = true
	if (!can_interact):
		return
	if (TC_AUTO == null && (itemsRequired == null || itemsRequired.size() == 0)):
		return

	if (itemsRequired != null && itemsRequired.size() > 0 && !addedItemsToAuto):
		addedItemsToAuto = true;
		TC_AUTO.text = "%s\n%s Items:" % [TC_AUTO.text, "Consumed" if eatRequirements else "Required"]
		for iq in itemsRequired:
			TC_AUTO.text = "%s\n%d %s" % [TC_AUTO.text,iq.quantity, iq.item.Name]
	
	var missing = !get_tree().get_current_scene().CheckHasInventoryItems(itemsRequired, false);

	TC_AUTO.ColorType = TextConfig.colorType.alert if missing else TextConfig.colorType.info

	global.interactNode.animateText(TC_AUTO, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)

func TextInteract():
	if (TC_AUTO == null):
		return	
	global.interactNode.animateText(TC_AUTO, ShowAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)

func AutoCloseInteract():
	if (is_instance_valid(timer) && timer.is_class("Timer")):
		timer.stop()
		timer.call_deferred('free')
	
	if (!oneshot):
		can_interact = true
		
	global.interactNode.closeText(HideAudioNode())


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
