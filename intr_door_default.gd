extends "res://SCRIPTS/intr_default.gd"
#extends Sprite
#
##ALEJANDRO (Feb-14-2020)
##dThis door script needs some work. Controls functins of the
##door, but don't think it's been working fully yet, almost there.
##Need to work on handling door script and logic and setup, specifically
##becuase there are multiple nodes inheriting this script per door
#
export (String) var LOCKED_DOOR_TEXT = null
export (String) var UNLOCKED_DOOR_TEXT = null

export (float) var DOOR_TIME = 2
export (float) var DOOR_OPEN_RANGE = 19
export (bool) var DOOR_AUTO_OPEN = true
export (bool) var DOOR_LOCKED = false

export (int) var DEPENDANT_LVL = null
export (String) var DEPENDANT_LVL_BOOL = null
export (bool) var OPPOSITE_IS_TRUE = false

var doorShadowNode

var doorShadowTop
var doorShadowTopClosePos : Vector2
var doorShadowTopOpenPos : Vector2
var doorShadowTopTween : Tween

var doorShadowBottom
var doorShadowBottomClosePos : Vector2
var doorShadowBottomOpenPos : Vector2
var doorShadowBottomTween : Tween

var doorTop
var doorTopClosePos : Vector2
var doorTopOpenPos : Vector2
var doorTopTween : Tween

var doorBottom
var doorBottomClosePos : Vector2
var doorBottomOpenPos : Vector2
var doorBottomTween : Tween



func _ready():
	#add the shadow to the door
	doorShadowNode = get_tree().get_current_scene().doorShadowTscn.instance()
	add_child(doorShadowNode)
#	print(get_index())
#	print("doorindex")
	move_child(doorShadowNode, get_index()+1)
	
	doorShadowTop = doorShadowNode.get_node("doorShadowTop")
	doorShadowBottom = doorShadowNode.get_node("doorShadowBottom")
	doorTop = get_node("doorTop")
	doorBottom = get_node("doorBottom")
	
	doorShadowTopClosePos = doorShadowTop.get_position()
	doorShadowTopOpenPos = doorShadowTopClosePos - Vector2(0, DOOR_OPEN_RANGE)
	
	doorShadowBottomClosePos = doorShadowBottom.get_position()
	doorShadowBottomOpenPos = doorShadowBottomClosePos + Vector2(0, DOOR_OPEN_RANGE)
	
	doorTopClosePos = doorTop.get_position()
	doorTopOpenPos = doorTopClosePos - Vector2(0, DOOR_OPEN_RANGE)
	
	doorBottomClosePos = doorBottom.get_position()
	doorBottomOpenPos = doorTopClosePos + Vector2(0, DOOR_OPEN_RANGE)



#const DOOR_TIME = 1
#var canClose : bool = false;
#var autoClose : bool = false;
#var doorPromptText = "ENTER_ ACCESS_ CODE"
#var doorPromptDenied = "ACCESS_ DENIED"
#var doorPromptGranted = "ACCESS_ GRANTED"
#onready var soundNode = $"/root/Control/astro/doorCloseSound"
#onready var customLocation : Vector2 = Vector2(-20, -15)
#
#
#func Interact():
#	if (!canClose):
#		$"/root/Control".LevelLogic(self.get_path())
#

func moveDoorPart(doorNode, doorStartPos, doorEndPos, doorTweenNode):
	
	var currentPos = doorStartPos
	
	if (is_instance_valid(doorTweenNode) && doorTweenNode.is_class("Tween")):
		currentPos = doorNode.get_position()
		doorTweenNode.stop_all()
		doorTweenNode.call_deferred('free')
	doorTweenNode = null
	
	doorTweenNode = global.newTween(doorNode, 'position', currentPos, doorEndPos, DOOR_TIME, 0)
	
	
	
func openDoor():
	
	moveDoorPart(doorShadowTop, doorShadowTopClosePos, doorShadowTopOpenPos, doorShadowTopTween)
	moveDoorPart(doorShadowBottom, doorShadowBottomClosePos, doorShadowBottomOpenPos, doorShadowBottomTween)
	moveDoorPart(doorTop, doorTopClosePos, doorTopOpenPos, doorTopTween)
	moveDoorPart(doorBottom, doorBottomClosePos, doorBottomOpenPos, doorBottomTween)
	
func closeDoor():
	
	moveDoorPart(doorShadowTop, doorShadowTopOpenPos, doorShadowTopClosePos, doorShadowTopTween)
	moveDoorPart(doorShadowBottom, doorShadowBottomOpenPos, doorShadowBottomClosePos, doorShadowBottomTween)
	moveDoorPart(doorTop, doorTopOpenPos, doorTopClosePos, doorTopTween)
	moveDoorPart(doorBottom, doorBottomOpenPos, doorBottomClosePos, doorBottomTween)
	
	

	
func AutoInteract():
	
#	print("door auto interact")
	TextInteract()
	can_interact = true
	if (DOOR_AUTO_OPEN || !DOOR_LOCKED):
		openDoor()
#
func Interact():
	#if door is unlocked, then can't interact with door anymore
	if (!DOOR_LOCKED):
		return
	
	#if still locked and interact timer is up, can then interact
	if (!can_interact):
		return
		
	var dependantBool = global.lvl(DEPENDANT_LVL).get(DEPENDANT_LVL_BOOL)
	
	if (OPPOSITE_IS_TRUE):
		dependantBool = !dependantBool
	
	can_interact = false
	
	#unlock case
	if (dependantBool):
		DOOR_LOCKED = false
		global.interactNode.animateText(UNLOCKED_DOOR_TEXT, InteractAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT)
		return
		
		
	#still locked
	#if theres a message display time, then prompt the user to try again after delay
	#(or if no delay time, user needs to walk away, then come back to initiate AutoInteract)
	if (T_I_DISPLAY_TIME != 0):
		
		timer = global.newTimer(T_I_DISPLAY_TIME, funcref(self, 'AutoInteract'))	
	
	global.interactNode.animateText(LOCKED_DOOR_TEXT, ShowAudioNode(), CUSTOM_POSITION_OFFSET, FIXED_TEXT)
	
	
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
