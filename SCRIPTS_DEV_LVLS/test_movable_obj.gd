extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var vel = Vector2(0, 0)
#var GRAVITY = 3
var TERMINAL_VELOCITY = 200
var gravity
var directional_force = Vector2(0, 0)
var accel = 0.1
var speed = 160

var collidingBodies = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	return
	gravity = global.gravFor1Frame * global.gravMag
	
	
	directional_force = Vector2(0, 0)
	
	if(Input.is_action_pressed("ui_right")): #|| TOUCH_CONTROL_NODE.stickDir.x > 0): #or vJoy == 1):
		directional_force += Vector2.RIGHT

	if(Input.is_action_pressed("ui_left")): #|| TOUCH_CONTROL_NODE.stickDir.x < 0): #or vJoy == -1):
		directional_force += Vector2.LEFT
	
	if collidingBodies.size() > 0: #&& collidingBodies[0] != null:
		directional_force += collidingBodies[0].directional_force
		print(directional_force)
	
	vel.x = lerp(vel.x, (directional_force.x * speed), accel)
	
#	vel.y += delta * 60 * gravity
#	clamp (vel.y, -TERMINAL_VELOCITY, TERMINAL_VELOCITY)
#	vel = move_and_slide(vel, global.gravVect() * -1, 5, 4, deg2rad(30), false)
#
##		print(velFinal2)
#	#if directional_force.x != 0:
#	for index in get_slide_count():
#		var coll = get_slide_collision(index)
#		if coll.collider != null && coll.collider.is_in_group("object"):
#			if coll.collider.get_linear_velocity().x < coll.collider.VEL_LIM:
#				if coll.collider.get_applied_force().x == 0:
#					coll.collider.set_applied_force(-coll.normal * 10)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Area2D_body_entered(body):
	pass
	#if body.get_groups().has("astro"):
		
		#collidingBodies.append(body)
	


func _on_Area2D_body_exited(body):
	pass
	#if body.get_groups().has("astro"):
	#	collidingBodies.erase(body)
