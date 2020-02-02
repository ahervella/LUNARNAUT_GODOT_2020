extends Sprite

const DOOR_TIME = 1
var canOpen : bool = false;
var autoOpen : bool = false;
var doorPromptText = "ENTER_ ACCESS_ CODE"
var doorPromptDenied = "ACCESS_ DENIED"
var doorPromptGranted = "ACCESS_ GRANTED"
onready var soundNode = $"/root/Control/astro/doorOpenSound"
onready var customLocation : Vector2 = Vector2(-20, -15)


func Interact():
	if (!canOpen):
		$"/root/Control".LevelLogic(self.get_path())

func AutoInteract():
	print("door auto interact")
	TextInteract()
	if (autoOpen):
		openDoor()

func AutoCloseInteract():
	print("auto_close")
	global.interactNode.closeText()

	
func TextInteract():
	if (!canOpen):
		global.interactNode.animateText("text", soundNode, customLocation, false)
	

func openDoor():
	
	print(get_name())
	print(get_child_count())
	#disableDoorBoxes("disable")
	var top_pos=get_node("door_top").get_position().y
	var bottom_pos = get_node("door_bottom").get_position().y
	
	get_node("door_top_tween").interpolate_property(get_node("door_top"), "position", Vector2(0, top_pos), Vector2(0,0), DOOR_TIME, Tween.TRANS_CIRC, Tween.EASE_OUT)
	get_node("door_top_tween").start()

	get_node("door_bottom_tween").interpolate_property(get_node("door_bottom"), "position", Vector2(0, bottom_pos), Vector2(0,0), DOOR_TIME, Tween.TRANS_CIRC, Tween.EASE_OUT)
	get_node("door_bottom_tween").start()
	
	
	var shadeFixTop = $"/root/Control/labShadeFixTop"
	var shadeFixBottom = $"/root/Control/labShadeFixBottom"
	
	var topDiff = abs(shadeFixTop.get_position().y - top_pos)
	var shadeFixTopNewPos = shadeFixTop.get_position() + Vector2(0, topDiff)
	
	var bottomDiff = abs(shadeFixBottom.get_position().y - bottom_pos)
	var shadeFixBottomNewPos = shadeFixBottom.get_position() + Vector2(0, bottomDiff)
	
	global.newTweenNoConnection(shadeFixTop, "position", shadeFixTop.get_position(), shadeFixTopNewPos, DOOR_TIME, 0)
	global.newTweenNoConnection(shadeFixBottom, "position", shadeFixBottom.get_position(), shadeFixBottomNewPos, DOOR_TIME, 0)




func _on_Area_body_exited(body):
	pass
	#disableDoorBoxes("enable")
#	var groups = body.get_groups()
#	if (groups.has("astro")):
#		var top_pos=get_node("door_top").get_position().y
#		var bottom_pos = get_node("door_bottom").get_position().y
#
#		get_node("door_top_tween").interpolate_property(get_node("door_top"), "position", Vector2(0, top_pos), Vector2(0,19), DOOR_TIME, Tween.TRANS_CIRC, Tween.EASE_OUT)
#		get_node("door_top_tween").start()
#
#		get_node("door_bottom_tween").interpolate_property(get_node("door_bottom"), "position", Vector2(0, bottom_pos), Vector2(0,-19), DOOR_TIME, Tween.TRANS_CIRC, Tween.EASE_OUT)
#		get_node("door_bottom_tween").start()

func _on_Area_area_entered(area):
	var groups = area.get_groups()
	var can_enter = global.get("doorOpened")
	if (groups.has("nora2Door") and can_enter):
			openDoor()
