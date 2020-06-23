extends Sprite

export (float) var elevatorEndYPos = 0
export (float) var elevatorSpeed = 20.0
export (float) var elevatorTime = 20
export (bool) var useTime = false

func lowerElevator():
	var newPos = Vector2(get_global_position().x, elevatorEndYPos)
	elevatorTime = elevatorTime if useTime else (elevatorEndYPos - get_global_position().y)/elevatorSpeed
	global.newTween(self, "global_position", get_global_position(), newPos, elevatorTime, 2)
