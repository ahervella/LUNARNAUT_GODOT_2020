extends Sprite

var grav = 0
var gravDiff = 0.5
func _physics_process(delta):
		set_physics_process(true)
		#print("heeeeeeeeeeeee")
		grav += gravDiff
		global.changeGrav(1, grav, delta)
			
