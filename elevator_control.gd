extends "res://SCRIPTS/INTERACT/intr_default.gd"

export (NodePath) var elevatorPath = null
onready var elevator = get_node(elevatorPath)

func Interact():
	
	if can_interact:
		elevator.lowerElevator()
	.Interact()
	
