extends Sprite

enum FAN_SPEED {LOW, MED, HIGH}

onready var area = get_node("FAN_AREA")
export var speed = FAN_SPEED.MED
var speedDict = {FAN_SPEED.LOW : 4.9, FAN_SPEED.MED : 9.8, FAN_SPEED.HIGH : 14.7}
#var airDuct = false


func _on_FAN_AREA_body_entered(body):
	if !body.is_in_group("astro") && !body.is_in_group("object"): return
	var fanVect = Vector2(0, -speedDict[speed])
	body.fanEnabled(true, fanVect.rotated(get_rotation()))

func _on_FAN_AREA_body_exited(body):
	if !body.is_in_group("astro") && !body.is_in_group("object"): return
	body.fanEnabled(false)
