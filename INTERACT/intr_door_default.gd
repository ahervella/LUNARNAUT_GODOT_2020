tool
extends "res://SCRIPTS/INTERACT/intr_default.gd"
#extends Sprite
#
##ALEJANDRO (Feb-14-2020)
##dThis door script needs some work. Controls functins of the
##door, but don't think it's been working fully yet, almost there.
##Need to work on handling door script and logic and setup, specifically
##becuase there are multiple nodes inheriting this script per door
#

#ALEJANDRO (Mar-03-2020)
#Threw out all of old door shit, started door scene and script from scratch,
#feeling really good about using the default to extend functionality
const WHITELIST_GROUPS = ["cablePoint", "object"]

enum DOOR_ACCESS {BOTH_WAYS, LEFT_ONLY, RIGHT_ONLY}

export (Resource) var TC_LOCKED = null
export (Resource) var TC_UNLOCKED = null

export (DOOR_ACCESS) var doorAccess = DOOR_ACCESS.BOTH_WAYS setget setDoorAccess
var leftNode = null
var rightNode = null
export (float) var DOOR_TIME = 1
export (float) var DOOR_OPEN_RANGE = 19
#export (bool) var DOOR_AUTO_OPEN = true

#need this to keep door unlocked after unlocked
var DOOR_TEMP_LOCKED = true
export (bool) var DOOR_MANUAL_LOCK = false

var shitPresentArray = []

var doorIsOpen = false

#export (int) var DEPENDANT_LVL = null
#export (String) var DEPENDANT_LVL_BOOL = null
#export (bool) var OPPOSITE_IS_TRUE = false

var doorShadowWhole

var doorTimer

var doorShadowTop
var doorShadowTopClosePos : Vector2
var doorShadowTopOpenPos : Vector2
var doorShadowTopTween : Tween
var doorShadowTopTweenUniqueID : String

var doorShadowBottom
var doorShadowBottomClosePos : Vector2
var doorShadowBottomOpenPos : Vector2
var doorShadowBottomTween : Tween
var doorShadowBottomTweenUniqueID : String

var doorTop
var doorTopClosePos : Vector2
var doorTopOpenPos : Vector2
var doorTopTween : Tween
var doorTopTweenUniqueID : String

var doorBottom
var doorBottomClosePos : Vector2
var doorBottomOpenPos : Vector2
var doorBottomTween : Tween
var doorBottomTweenUniqueID : String

var doorBarrierShape : CollisionShape2D
var doorBarrierShapePar
var doorBarrierShapePos


func _ready():
	if Engine.editor_hint: return
	#add the shadow to the door
	doorShadowWhole = get_node("doorShadowWhole")
	
	doorTimer = Timer.new()
	add_child(timer)
	doorTimer.set_owner(self)
	doorTimer.set_wait_time(DOOR_TIME)
	doorTimer.connect("timeout", self, 'showWholeShadow')
	
	#add_child(doorShadowNode)
#	print(get_index())
#	print("doorindex")
	#move_child(doorShadowNode, get_index()+1)
	
	#doorShadowNode.set_global_position(get_global_position())
	
	doorShadowTop = get_node("doorShadowTop")
	doorShadowBottom = get_node("doorShadowBottom")
	doorTop = get_node("doorTop")
	doorBottom = get_node("doorBottom")
	doorBarrierShape = get_node("doorStaticBody/doorShape")
	
	doorBarrierShapePar = doorBarrierShape.get_parent()
	doorBarrierShapePos = doorBarrierShape.get_position()
	
	doorShadowTopClosePos = doorShadowTop.get_position()
	#adding 2 so that shadows move faster and don't bleed infront of door
	doorShadowTopOpenPos = doorShadowTopClosePos - Vector2(0, DOOR_OPEN_RANGE + 2)
	
	doorShadowBottomClosePos = doorShadowBottom.get_position()
	doorShadowBottomOpenPos = doorShadowBottomClosePos + Vector2(0, DOOR_OPEN_RANGE + 2)
	
	doorTopClosePos = doorTop.get_position()
	doorTopOpenPos = doorTopClosePos - Vector2(0, DOOR_OPEN_RANGE)
	
	doorBottomClosePos = doorBottom.get_position()
	doorBottomOpenPos = doorBottomClosePos + Vector2(0, DOOR_OPEN_RANGE)

	#setDoorAccess(doorAccess)
	rightEntranceEnable(true)
	leftEntranceEnable(true)
	
	if hasRequiredItems():
		DOOR_TEMP_LOCKED = false

func setDoorAccess(val):
	doorAccess = val
	if doorAccess == DOOR_ACCESS.LEFT_ONLY:
		rightEntranceEnable(false)
		leftEntranceEnable(true)

	elif doorAccess == DOOR_ACCESS.RIGHT_ONLY:
		leftEntranceEnable(false)
		rightEntranceEnable(true)
		
	else:
		leftEntranceEnable(true)
		rightEntranceEnable(true)
		


func sideEntranceEnable(enabled, rightSide):
	var coreArea = get_node("doorCoreArea")
	var sideArea = coreArea.get_node("doorCoreRight") if rightSide else coreArea.get_node("doorCoreLeft")
	if sideArea != null:
		if enabled:
			sideArea.show()
		else:
			sideArea.hide()
	
	if !Engine.editor_hint:
		if enabled:
			if sideArea == null:
				if rightSide: 
					coreArea.add_child(rightNode)
					rightNode.set_owner(coreArea)
				else:
					coreArea.add_child(leftNode)
					leftNode.set_owner(coreArea)
		else:
			if sideArea != null:
				if rightSide:
					rightNode = sideArea
				else:
					leftNode = sideArea
					
				coreArea.remove_child(sideArea)
	
func rightEntranceEnable(enabled):
	sideEntranceEnable(enabled, true)
	
func leftEntranceEnable(enabled):
	sideEntranceEnable(enabled, false)


func moveDoorPart(doorNode, doorStartPos, doorEndPos, doorTweenNode, doorTweenNodeUniqueID, opening):
	if Engine.editor_hint: return
	var currentPos = doorStartPos
	
	if (is_instance_valid(doorTweenNode) && doorTweenNode.is_class("Tween") && doorTweenNodeUniqueID == doorTweenNode.to_string()):
		currentPos = doorNode.get_position()
		doorTweenNode.stop_all()
		doorTweenNode.call_deferred('free')
	else:
		doorTweenNode = null
	
	var fr = null if opening else funcref(self, "showWholeShadow")
	if opening:
		hideWholeShadow()
	return global.newTween(doorNode, 'position', currentPos, doorEndPos, DOOR_TIME, 0, fr, Tween.TRANS_CIRC, Tween.EASE_OUT)
	
	
func hideWholeShadow():
	#return
	if doorShadowWhole.is_visible():
		doorShadowWhole.hide()
		doorShadowBottom.show()
		doorShadowTop.show()
		
func showWholeShadow():
	#return
	if !doorShadowWhole.is_visible():
		doorShadowWhole.show()
		doorShadowBottom.hide()
		doorShadowTop.hide()
	
	
func openDoor():
	if Engine.editor_hint: return
	
	if doorIsOpen: return
	
	hideWholeShadow()
	doorTimer.stop()
	
	if doorBarrierShape.get_parent() != null:
		doorBarrierShape.get_parent().remove_child(doorBarrierShape)
	#had to do above instead beacuse for some damn reason disabling the shape
	#wasn't always working :////
	#doorBarrierShape.set_disabled(true)
	doorShadowTopTween = moveDoorPart(doorShadowTop, doorShadowTopClosePos, doorShadowTopOpenPos, doorShadowTopTween, doorShadowTopTweenUniqueID, true)
	doorShadowTopTweenUniqueID = doorShadowTopTween.to_string()
	doorShadowBottomTween = moveDoorPart(doorShadowBottom, doorShadowBottomClosePos, doorShadowBottomOpenPos, doorShadowBottomTween, doorShadowBottomTweenUniqueID, true)
	doorShadowBottomTweenUniqueID = doorShadowBottomTween.to_string()
	doorTopTween = moveDoorPart(doorTop, doorTopClosePos, doorTopOpenPos, doorTopTween, doorTopTweenUniqueID, true)
	doorTopTweenUniqueID = doorTopTween.to_string()
	doorBottomTween = moveDoorPart(doorBottom, doorBottomClosePos, doorBottomOpenPos, doorBottomTween, doorBottomTweenUniqueID, true)
	doorBottomTweenUniqueID = doorBottomTween.to_string()
	
	doorIsOpen = true
	
	audio.sound("doorOpen").play()
	
func closeDoor():
	if Engine.editor_hint: return
	
	if !doorIsOpen: return
	
	
	yield(get_tree(), "idle_frame")
	if shitPresentArray.size() > 0: return
	
	doorTimer.start(0)
	if doorBarrierShape.get_parent() == null:
		doorBarrierShapePar.add_child(doorBarrierShape)
		doorBarrierShape.set_owner(doorBarrierShapePar)
	#doorBarrierShape.set_disabled(false)
	doorShadowTopTween = moveDoorPart(doorShadowTop, doorShadowTopOpenPos, doorShadowTopClosePos, doorShadowTopTween, doorShadowTopTweenUniqueID, false)
	doorShadowTopTweenUniqueID = doorShadowTopTween.to_string()
	doorShadowBottomTween = moveDoorPart(doorShadowBottom, doorShadowBottomOpenPos, doorShadowBottomClosePos, doorShadowBottomTween, doorShadowBottomTweenUniqueID, false)
	doorShadowBottomTweenUniqueID = doorShadowBottomTween.to_string()
	doorTopTween = moveDoorPart(doorTop, doorTopOpenPos, doorTopClosePos, doorTopTween, doorTopTweenUniqueID, false)
	doorTopTweenUniqueID = doorTopTween.to_string()
	doorBottomTween = moveDoorPart(doorBottom, doorBottomOpenPos, doorBottomClosePos, doorBottomTween, doorBottomTweenUniqueID, false)
	doorBottomTweenUniqueID = doorBottomTween.to_string()
	
	doorIsOpen = false

	
func AutoInteract():
	if Engine.editor_hint: return
#	print("working autodoor?")
##	print("door auto interact")
	leftEntranceEnable(true)
	rightEntranceEnable(true)

	#if (DOOR_LOCKED):
	#	TextInteract()
	#can_interact = true
	
	if (!DOOR_MANUAL_LOCK && !DOOR_TEMP_LOCKED):#(DOOR_AUTO_OPEN || !DOOR_LOCKED):
		openDoor()
		interactNode = global.getNextInteractNodeIndex()#interactNodeIndex = global.getNextInteractNodeIndex()
		if interactNode != null:
			interactNode.parentInteractObject = self
			
			if TC_UNLOCKED != null:
				interactNode.animateText(TC_UNLOCKED, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)
		return
	else:
		.AutoInteract()

		



func Interact():
	if Engine.editor_hint: return
	#if door is unlocked, then can't interact with door anymore
	if (!DOOR_TEMP_LOCKED):
		return

	#if still locked and interact timer is up, can then interact
	if (!can_interact):
		return

	#var dependantBool = global.lvl(DEPENDANT_LVL).get(DEPENDANT_LVL_BOOL)

#	if (OPPOSITE_IS_TRUE):
#		dependantBool = !dependantBool

	can_interact = false

	#unlock case
	if (hasRequiredItems() && !DOOR_MANUAL_LOCK):
		DOOR_TEMP_LOCKED = false
		openDoor()
		#global.interactNode.animateText(TC_UNLOCKED, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)
		if TC_UNLOCKED != null:
			interactNode.animateText(TC_UNLOCKED, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)
		return


	#still locked
	#if theres a message display time, then prompt the user to try again after delay
	#(or if no delay time, user needs to walk away, then come back to initiate AutoInteract)
	if (T_I_DISPLAY_TIME != 0):

		timer = global.newTimer(T_I_DISPLAY_TIME, funcref(self, 'AutoInteract'))	
		timerUniqueID = timer.to_string()
	#global.interactNode.animateText(TC_LOCKED, ShowAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)
	if TC_LOCKED != null:
		interactNode.animateText(TC_LOCKED, ShowAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT, TEXT_POSITION)



func AutoCloseInteract():
	if Engine.editor_hint: return
	.AutoCloseInteract()
	
	if (!DOOR_TEMP_LOCKED):
		closeDoor()
		
	setDoorAccess(doorAccess)
#func AutoOpenInteract():
#	print("auto_close")
#	global.interactNode.closeText()
#
#
#func TextInteract():
#	if (!canClose):
#		global.interactNode.animateText("text", soundNode, customLocation, false)
#
#
#func openDoor():
#
#	print(get_name())
#	print(get_child_count())
#	#disableDoorBoxes("disable")
#	var top_pos=get_node("door_top").get_position().y
#	var bottom_pos = get_node("door_bottom").get_position().y
#
#	get_node("door_top_tween").interpolate_property(get_node("door_top"), "position", Vector2(0, top_pos), Vector2(0,0), DOOR_TIME, Tween.TRANS_CIRC, Tween.EASE_OUT)
#	get_node("door_top_tween").start()
#
#	get_node("door_bottom_tween").interpolate_property(get_node("door_bottom"), "position", Vector2(0, bottom_pos), Vector2(0,0), DOOR_TIME, Tween.TRANS_CIRC, Tween.EASE_OUT)
#	get_node("door_bottom_tween").start()
#
#
#	var shadeFixTop = $"/root/Control/labShadeFixTop"
#	var shadeFixBottom = $"/root/Control/labShadeFixBottom"
#
#	var topDiff = abs(shadeFixTop.get_position().y - top_pos)
#	var shadeFixTopNewPos = shadeFixTop.get_position() + Vector2(0, topDiff)
#
#	var bottomDiff = abs(shadeFixBottom.get_position().y - bottom_pos)
#	var shadeFixBottomNewPos = shadeFixBottom.get_position() + Vector2(0, bottomDiff)
#
#	global.newTween(shadeFixTop, "position", shadeFixTop.get_position(), shadeFixTopNewPos, DOOR_TIME, 0)
#	global.newTween(shadeFixBottom, "position", shadeFixBottom.get_position(), shadeFixBottomNewPos, DOOR_TIME, 0)
#
#
#
#
#func _on_Area_body_exited(body):
#	pass
#	#disableDoorBoxes("enable")
##	var groups = body.get_groups()
##	if (groups.has("astro")):
##		var top_pos=get_node("door_top").get_position().y
##		var bottom_pos = get_node("door_bottom").get_position().y
##
##		get_node("door_top_tween").interpolate_property(get_node("door_top"), "position", Vector2(0, top_pos), Vector2(0,19), DOOR_TIME, Tween.TRANS_CIRC, Tween.EASE_OUT)
##		get_node("door_top_tween").start()
##
##		get_node("door_bottom_tween").interpolate_property(get_node("door_bottom"), "position", Vector2(0, bottom_pos), Vector2(0,-19), DOOR_TIME, Tween.TRANS_CIRC, Tween.EASE_OUT)
##		get_node("door_bottom_tween").start()
#
#func _on_Area_area_entered(area):
#	var groups = area.get_groups()
#	var can_enter = global.get("doorCloseed")
#	if (groups.has("nora2Door") and can_enter):
#			openDoor()


func _on_doorCoreArea_body_entered(body):
	if Engine.editor_hint: return
	if inWhiteListGroup(body):
		if shitPresentArray.size() == 0: openDoor()
		shitPresentArray.append(body)


func _on_doorCoreArea_body_exited(body):
	if Engine.editor_hint: return
	if inWhiteListGroup(body):
		if shitPresentArray.has(body):
			shitPresentArray.erase(body)
		if shitPresentArray.size() == 0: closeDoor()
		
		
func inWhiteListGroup(body):
	if Engine.editor_hint: return
	for group in WHITELIST_GROUPS:
		if body.is_in_group(group):
			return true
	return false
