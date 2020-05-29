tool
extends KinematicBody2D

export (NodePath) var SPRITE_PATH = null
var SPRITE : Sprite
var collidingBodies = []

func setCableNodeSprite(CABLE_SPRITE_PK_SCENE):
	SPRITE = CABLE_SPRITE_PK_SCENE.instance()
	add_child(SPRITE)

func getCollidingBodies():
	return collidingBodies


func _on_Area2D_body_entered(body):
	if body.is_in_group("cablePoint") or body.is_in_group("astro") or body.is_in_group("object"): return
#	this does not break point accurately, probably because so much shit
#	passing through here
	collidingBodies.append(body)
	#var blah = move_and_collide(Vector2(0,0))
	

func _on_Area2D_body_exited(body):
	if body.is_in_group("cablePoint") or body.is_in_group("astro") or body.is_in_group("object"): return
	collidingBodies.erase(body)
	collidingBodies.resize(collidingBodies.size()-1)
