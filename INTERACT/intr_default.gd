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
enum TEXT_SIDE {LEFT = -1, RIGHT = 1, DYNAMIC_FRONT = 0, DYNAMIC_BEHIND = 2}

export (Resource) var TC_AUTO = null
export (Resource) var TC_INTERACT = null
export (float) var T_I_DISPLAY_TIME = 0

export (Vector2) var CUSTOM_POSITION_OFFSET = Vector2(0, 0)
export (bool) var FIXED_TEXT = false

export (TEXT_SIDE) var TEXT_POSITION = TEXT_SIDE.DYNAMIC_FRONT
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

#if true, will assume that there should not be multiple interactNodes
#being used, and will wipe everything clean and only use the first one of
#interactNodes
export (bool) var useNextInterNodeIfNeeded = false

#make this the only interactable the happens if multiple interactables present
export (bool) var cancelOverlappingInteractables = true

var interactNode = null

var can_interact : bool = true
export (bool) var oneshot = false
var timer : Timer
var timerUniqueID

#used in case multiple items that interact with eachother at once
#such as with plugs/cables
var processed = false


func Interact():
	# If we can't interact, bail
	if (!can_interact):
		return

	# Check to make sure we have all the items we need, otherwise bail
	if !hasRequiredItems(): return
#	if (itemsRequired != null && itemsRequired.size() > 0):
#		if (!get_tree().get_current_scene().CheckHasInventoryItems(itemsRequired, false)):
#			return

	# Do some timer stuff
	if (T_I_DISPLAY_TIME != 0):		
		timer = global.newTimer(T_I_DISPLAY_TIME, funcref(self, 'AutoInteract'))
		timerUniqueID = timer.to_string()
	# Eat the items we need if we're supposed to
	if (itemsRequired != null && itemsRequired.size() > 0 && eatRequirements):
		get_tree().get_current_scene().CheckhasInventoryItems(itemsRequired, true)

	# Give us items if we're supposed to	
	get_tree().get_current_scene().AddInventoryItems(itemsGained)

	if TC_INTERACT != null:
		# Update text for items we got
		if (itemsGained != null && itemsGained.size() > 0):
			for iq in itemsGained:
				TC_INTERACT.text = "%s\nGained %d %s" % [TC_INTERACT.text,iq.quantity, iq.item.ScreenName]
	
		# Display text
		if (interactNode != null && is_instance_valid(interactNode)):
			interactNode.animateText(TC_INTERACT, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)

	# If oneshot, then we all done
	if (oneshot):
		can_interact = false


var addedItemsToAuto = false;

func hasRequiredItems():
	if (itemsRequired != null && itemsRequired.size() > 0):
		return get_tree().get_current_scene().CheckHasInventoryItems(itemsRequired, false)
	return true

func AutoInteract():
	#print("interactNodeIndex")
	
	if !useNextInterNodeIfNeeded:
		#print("should worK??")
#		for item in global.lvl().astroNode.currItems:
#			if !item.is_in_group("object"):
#					item.interactNode = null
		
		global.enableMultiInteractNodes(false)#.closeText(HideAudioNode()) #because will not finish closing text before requesting on next line
			

				
		#interactNode = global.getNextInteractNodeIndex()
		
	interactNode = global.getNextInteractNodeIndex()#interactNodeIndex = global.getNextInteractNodeIndex()
	if interactNode != null:
		interactNode.parentInteractObject = self
	
	if (!oneshot):
		can_interact = true
	if (!can_interact):
		return
	if (TC_AUTO == null || (itemsRequired == null || itemsRequired.size() == 0)):
		return

	if (itemsRequired != null && itemsRequired.size() > 0 && !addedItemsToAuto):
		addedItemsToAuto = true;
		TC_AUTO.text = "%s\n%s Items:" % [TC_AUTO.text, "Consumed" if eatRequirements else "Required"]
		for iq in itemsRequired:
			TC_AUTO.text = "%s\n%d %s" % [TC_AUTO.text,iq.quantity, iq.item.ScreenName]
	
	var missing = !get_tree().get_current_scene().CheckHasInventoryItems(itemsRequired, false);

	#only changes TC_AUTO color from what was set if it is an item that requires shit
	if missing:
		TC_AUTO.ColorType = TextConfig.colorType.alert
	elif(itemsRequired != null && itemsRequired.size() > 0):
		TC_AUTO.ColorType = TextConfig.colorType.info

	
				
	if (interactNode != null && is_instance_valid(interactNode)):
		interactNode.animateText(TC_AUTO, ShowAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)

#I think you can call AutoInteract again with out hick ups,
#but I guess helpful if you had changed AutoInteract shit in an extended script
func TextInteract():
	if (TC_AUTO == null):
		return	
	global.interactNode.animateText(TC_AUTO, ShowAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)

func AutoCloseInteract():
	if (is_instance_valid(timer) && timer.is_class("Timer") && timerUniqueID == timer.to_string()):
		timer.stop()
		timer.call_deferred('free')
	
	if (!oneshot):
		can_interact = true
		
		
	#because this originally deleted the interNodes of all items, but them back
	if !useNextInterNodeIfNeeded:
		global.enableMultiInteractNodes(true)
		
	if (interactNode != null && is_instance_valid(interactNode)):
		if interactNode.currentText != null && interactNode.currentText != "":
			interactNode.closeText(HideAudioNode())
		
	


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
