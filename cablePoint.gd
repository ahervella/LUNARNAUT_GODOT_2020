tool
extends KinematicBody2D

export (NodePath) var SPRITE_PATH = null
var SPRITE : Sprite

func setCableNodeSprite(CABLE_SPRITE_PK_SCENE):
	SPRITE = CABLE_SPRITE_PK_SCENE.instance()
	add_child(SPRITE)

