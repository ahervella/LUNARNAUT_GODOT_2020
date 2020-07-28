extends "res://SCRIPTS/INTERACT/intr_default.gd"

export (NodePath) var elevatorPath = null
export (NodePath) var elevatorLightsPath = null
onready var elevator = get_node(elevatorPath)
onready var elevatorLights = get_node(elevatorLightsPath)

func _ready():
	for child in elevatorLights.get_children():
		child.set_enabled(false)

func Interact():
	
	if can_interact:
		elevator.movingPlatform = true
		interactNode.closeText()
	.Interact()
	
	for child in elevatorLights.get_children():
		child.set_enabled(true)
	
