tool
#added tool so it could be extended and not break
extends Sprite

enum MOVE_TYPE {LINEAR, CUSTOM_PATH}

#literally just copied and pasted the tween types cause you can't
#use them directly as an export hint lol
enum TRANS_TYPE {TRANS_LINEAR, TRANS_SINE, TRANS_QUINT,
TRANS_QUART, TRANS_QUAD, TRANS_EXPO, TRANS_ELAST, TRANS_CUBIC,
TRANS_CIRC, TRANS_BOUNCE, TRANS_BACK}

enum EASE_TYPE {EASE_IN, EASE_OUT, EASE_IN_OUT, EASE_OUT_IN}

export (bool) var movingPlatform = false setget setMoving
export (NodePath) var customPath2D #= null
export (NodePath) var templatePath #= null
export (TRANS_TYPE) var transitionType = TRANS_TYPE.TRANS_QUART
export (EASE_TYPE) var easeType = EASE_TYPE.EASE_IN_OUT
export (bool) var loop = true
export (bool) var changeDirection = true
export (float) var pathTime = 4
export (float) var delayChangeDirection = 0
export (float) var easeTimeOnDisable = 2

var kbNode

var directionRev = false
var readyDone = false

var stopLength = null

onready var tween = Tween.new()
var blah = Vector2(1000, 0)
var pathNode = null

onready var debugLine2D = Line2D.new()

	

func _ready():
	call_deferred("readyDeferred")
	
	
func readyDeferred():
	if Engine.editor_hint: return
	
	add_child(tween)
	tween.set_owner(self)

	
	if customPath2D != null && customPath2D != "":
		pathNode = get_node(customPath2D)
	elif templatePath != null && templatePath != "":
		pathNode = get_node(templatePath).get_child(0)
	
	
	drawDebugPathLine()
	rearrangeKinematicBody2D()
	
	
	tween.connect("tween_completed", self, "restartMovement")
	readyDone = true
	
	setMoving(movingPlatform)
	
	
func rearrangeKinematicBody2D():
	for child in get_children():
		if child is KinematicBody2D:
			kbNode = child
			break
			
	if kbNode == null: return
	
	var kbPos = kbNode.get_global_position()
	remove_child(kbNode)
	get_parent().add_child_below_node(self, kbNode)
	kbNode.set_owner(get_parent())
	kbNode.set_global_position(kbPos)
	
	var selfPos = get_global_position()
	get_parent().remove_child(self)
	kbNode.add_child(self)
	set_owner(kbNode)
	set_global_position(selfPos)
	
	
	
func drawDebugPathLine():
	if get_tree().is_debugging_collisions_hint() && !pathNode == null:
		get_parent().add_child(debugLine2D)
		debugLine2D.set_owner(get_parent())
		
		var points : PoolVector2Array = [] #pathNode.get_curve().get_baked_points()
		
		var pathNodePos = pathNode.get_global_position()
		var pathNodeScale = pathNode.get_global_scale()
		var pathNodeRot = pathNode.get_global_rotation()
		
		for point in pathNode.get_curve().get_baked_points():
			points.append((point * pathNodeScale).rotated(pathNodeRot) + pathNodePos)
			
		debugLine2D.points = points
	
	
	
func updatePos(curveDistance):
	if Engine.editor_hint: return
	
	var localPoint = pathNode.get_curve().interpolate_baked(curveDistance)
	var pathNodePos = pathNode.get_global_position()
	var pathNodeScale = pathNode.get_global_scale()
	var pathNodeRot = pathNode.get_global_rotation()
	
	kbNode.set_global_position((localPoint * pathNodeScale).rotated(pathNodeRot) + pathNodePos)

	pathNode.set_global_position(pathNodePos)
	stopLength = curveDistance
	
func setMoving(val):
	
	movingPlatform = val
	
	if !readyDone: return
	
	if (pathNode == null || kbNode == null) && !Engine.editor_hint:
		movingPlatform = false
		return
	
	

	
	if Engine.editor_hint: return
	
	if val:
		if stopLength == null:
			startMovement(directionRev, true)
		else: resumeMovement()
	else:
		stopMovement()
	
func startMovement(reversed, overrideDelay = false):
	if Engine.editor_hint: return
	
	var startVal = pathNode.get_curve().get_baked_length() if reversed else 0
	var endVal = 0 if reversed else pathNode.get_curve().get_baked_length()
	
	var delay = 0 if overrideDelay else delayChangeDirection
	
	tween.interpolate_method(self, "updatePos", startVal, endVal, pathTime, transitionType, easeType, delay)
	tween.start()
	
func restartMovement(object, key):
	if Engine.editor_hint: return
	
	if !loop:
		movingPlatform = false
		return
		
	if changeDirection:
		directionRev = !directionRev
		
	startMovement(directionRev)

func stopMovement():
	if Engine.editor_hint: return
	
	tween.stop_all()
	
	
func resumeMovement():
	if Engine.editor_hint: return
	
	tween.resume_all()
	
	
	
	
