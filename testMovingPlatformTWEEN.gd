extends KinematicBody2D

enum MOVE_TYPE {LINEAR, CUSTOM_PATH}

#literally just copied and pasted the tween types cause you can't
#use them directly as an export hint lol
enum TRANS_TYPE {TRANS_LINEAR, TRANS_SINE, TRANS_QUINT,
TRANS_QUART, TRANS_QUAD, TRANS_EXPO, TRANS_ELAST, TRANS_CUBIC,
TRANS_CIRC, TRANS_BOUNCE, TRANS_BACK}

enum EASE_TYPE {EASE_IN, EASE_OUT, EASE_IN_OUT, EASE_OUT_IN}

export (bool) var movingPlatform = false setget setMoving
export (NodePath) var customPath2D = null
export (NodePath) var templatePath = null
export (TRANS_TYPE) var transitionType = TRANS_TYPE.TRANS_QUART
export (EASE_TYPE) var easeType = EASE_TYPE.EASE_IN_OUT
export (bool) var loop = true
export (bool) var changeDirection = true
export (float) var pathTime = 4
export (float) var delayChangeDirection = 0
export (float) var easeTimeOnDisable = 2

var directionRev = false
var readyDone = false

var stopLength = null

onready var tween = Tween.new()
var blah = Vector2(1000, 0)
onready var pathNode = get_node(customPath2D) if customPath2D!= null else get_node(templatePath).get_child(0)

onready var debugLine2D = Line2D.new()

	

func _ready():
	call_deferred("readyDeferred")
func readyDeferred():
	add_child(tween)
	tween.set_owner(self)

	
	if get_tree().is_debugging_collisions_hint():
		get_parent().add_child(debugLine2D)
		debugLine2D.set_owner(get_parent())
		
		var points : PoolVector2Array = [] #pathNode.get_curve().get_baked_points()
		
		var pathNodePos = pathNode.get_global_position()
		var pathNodeScale = pathNode.get_global_scale()
		var pathNodeRot = pathNode.get_global_rotation()
		
		for point in pathNode.get_curve().get_baked_points():
			points.append((point * pathNodeScale).rotated(pathNodeRot) + pathNodePos)
			
		debugLine2D.points = points
		#debugLine2D.set_global_position(pathNode.get_global_position())
	
	
	tween.connect("tween_completed", self, "restartMovement")
	readyDone = true
	
	setMoving(movingPlatform)
	
	
func updatePos(curveDistance):
	var localPoint = pathNode.get_curve().interpolate_baked(curveDistance)
	var pathNodePos = pathNode.get_global_position()
	var pathNodeScale = pathNode.get_global_scale()
	var pathNodeRot = pathNode.get_global_rotation()
	set_global_position((localPoint * pathNodeScale).rotated(pathNodeRot) + pathNodePos)
	stopLength = curveDistance
	
func setMoving(val):
	movingPlatform = val
	if !readyDone: return
	
	if val:
		if stopLength == null:
			startMovement(directionRev, true)
		else: resumeMovement()
	else:
		stopMovement()
	
func startMovement(reversed, overrideDelay = false):
	var startVal = pathNode.get_curve().get_baked_length() if reversed else 0
	var endVal = 0 if reversed else pathNode.get_curve().get_baked_length()
	
	var delay = 0 if overrideDelay else delayChangeDirection
	
	tween.interpolate_method(self, "updatePos", startVal, endVal, pathTime, transitionType, easeType, delay)
	tween.start()
	
func restartMovement(object, key):
	if !loop:
		movingPlatform = false
		return
		
	if changeDirection:
		directionRev = !directionRev
		
	startMovement(directionRev)

func stopMovement():
	tween.stop_all()
	
	
func resumeMovement():
	tween.resume_all()
#	var startVal = stopLength
#	var endVal = 0 if directionRev else pathNode.get_curve().get_baked_length()
#
#	var time = abs(startVal - endVal)/pathNode.get_curve().get_baked_length() * pathTime
#	tween.interpolate_method(self, "updatePos", startVal, endVal, pathTime, transitionType, easeType)
#	tween.start()
#
#	stopLength = null
#
	
	
	
	
