extends "res://SCRIPTS/intr_default.gd"
#ALEJANDRO (Mar-01-2020)
#this script is for the cave key! It is overwriting methods
#found in the default interact script (intr_default.gd) to do specific
#things for the key logic

#need to override to not have can_interact to true again
func AutoInteract():
	if (can_interact):
		TextInteract()
		return
	PostTextInteract()

#need to override to not have can_interact set to true again
func AutoCloseInteract():
	if (is_instance_valid(timer) && timer.is_class("Timer")):
		timer.stop()
		timer.call_deferred('free')
	
	global.interactNode.closeText(HideAudioNode())

#function thats used here just to call the text after key has been gotten
func PostTextInteract():
	global.interactNode.animateText(TC_INTERACT, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT)

#override interact so that we set the lvl01 key to true
func Interact():
	if (!can_interact):
		return
	if (T_I_DISPLAY_TIME != 0):
		
		timer = global.newTimer(T_I_DISPLAY_TIME)
		
	PostTextInteract()
	can_interact = false
	get_tree().get_current_scene().has_key = true
