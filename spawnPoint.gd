tool
extends Node2D

const DEFAULT_OFFSET = Vector2(-0.25, 23.25)
const DEFAULT_SCALE = Vector2(2.5, 2.5)

export (bool) var flip = false setget setFlip
export (int, 0, 8) var health = 8
export (bool) var flashLightOn = true
export (bool) var hideSpawnPointOnLoad = true

func setFlip(val):
	flip = val
	
	#if !Engine.editor_hint: return
	
	var astroSprite = get_child(0)
	var multiplyer = -1 if flip else 1
	astroSprite.set_global_scale(Vector2(DEFAULT_SCALE.x * multiplyer, DEFAULT_SCALE.y))
	astroSprite.set_position(Vector2(DEFAULT_OFFSET.x * multiplyer, DEFAULT_OFFSET.y))
	astroSprite.set_global_rotation(0)
	
	
func _ready():
	
	if Engine.editor_hint: return
	
	set("visible", !hideSpawnPointOnLoad)
	
func getGlobalPosition():
	return get_child(0).get_global_position()

func getStartingHealth():
	return health
