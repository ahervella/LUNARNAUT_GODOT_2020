extends Area2D

export (Resource) var tutorialTextConfig
export (bool) var useShowTime = true
export (float) var showTime = 5
export (float) var delay = 0
export (bool) var oneShot = true
export (bool) var closeOnLeaveArea = true
var tutorialITN
var completed = false
var startedClose = true

onready var timer = Timer.new()
onready var delayTimer = Timer.new()

func _ready():
	if !useShowTime: return
	
	add_child(timer)
	add_child(delayTimer)
	timer.set_wait_time(showTime)
	delayTimer.set_wait_time(delay)
	delayTimer.connect("timeout", self, "startTutorialText")
	timer.connect("timeout", self, "closeTutorialText")

func _on_TUTORIAL_TEXT_body_entered(body):
	
	if !body.is_in_group("astro"): return
	
	startTutorialTextTimer()

func _on_TUTORIAL_TEXT_body_exited(body):
	if !body.is_in_group("astro") || !closeOnLeaveArea: return
	closeTutorialText()
	
	
func startTutorialTextTimer():
	delayTimer.start(0)
	
	
	
func startTutorialText():
	yield(get_tree(), "idle_frame")
	if completed: return
	
	tutorialITN = global.lvl().astroNode.CAMERA_NODE.get_node("InteractFont/InteractFontLabel")#global.addNewIndependantTextNode()
	tutorialITN.animateTutorialText(tutorialTextConfig)
	if oneShot:
		completed = true
		
	if useShowTime: timer.start()
	startedClose = false
	
func closeTutorialText():
	delayTimer.stop()
	if startedClose: return
	startedClose = true
	tutorialITN.closeText()
