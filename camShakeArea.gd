extends Area2D

export (global.SHAKE) var shakeMagnitude = global.SHAKE.MED
export (bool) var indefiniteShake = false
export (float) var shakeTime = 4
export (bool) var customShakeDecay = false
export (float) var customShakeDecayTime = 2
export (bool) var oneShotShake = true
export (bool) var stopShakeOnAreaLeave = false
var disabled = false

func startShake():
	if disabled: return
	
	var time = null if indefiniteShake else shakeTime
	var decayTime = customShakeDecayTime if customShakeDecay else null
	
	global.lvl().astroNode.CAMERA_NODE.shake(shakeMagnitude, time, decayTime)
	
	if oneShotShake: disabled = true


func stopShake():
	global.lvl().astroNode.CAMERA_NODE.shake(global.SHAKE.NONE)
	
	

func _on_camShakeArea_body_entered(body):
	if body.is_in_group("astro"):
		startShake()



func _on_camShakeArea_body_exited(body):
	if !stopShakeOnAreaLeave: return
	
	if body.is_in_group("astro"):
		stopShake()
