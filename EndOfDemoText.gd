extends RichTextLabel

var blink = true
var timer
var gameover_timer
var texttt
var gameOverText = null
var completeText = ">>DEMO_COMPLETE_//*(er44)**LUNAR_BASE_COMPROMISED"
var deathText = ">>LOSS_OF_VITAL_SIGNS_//*RELAY*_REPORTING_SURVIVORS"
var timer_for_text = true
var textTween
var act = false

func _ready():
	set_text("")
	set_percent_visible(0)
	
	#for centering the text
	set_position(Vector2(get_viewport().get_size().x/2 - get_size().x/2, get_position().y))
	
	#onGameOver()
	#var camthign = get_node("Camera2D").get_viewport().get_global_position()
	#print (camthign)
func onGameOver(won):
	if (won):
		gameOverText = completeText
		gameover_timer = Timer.new()
		add_child(gameover_timer)
		gameover_timer.set_one_shot(true)
		gameover_timer.set_wait_time(4)
		gameover_timer.connect("timeout", self, "on_gameover_timer_fin_WON")
		gameover_timer.start()
	
	else:
		gameOverText = deathText
		startText()

	
#function for completing demo (activated by EndOfDemoArea script
func startText():
	
	gameover_timer = Timer.new()
	add_child(gameover_timer)
	gameover_timer.set_one_shot(true)
	gameover_timer.set_wait_time(1)
	gameover_timer.connect("timeout", self, "on_gameover_timer_fin")
	gameover_timer.start()
	
func on_gameover_timer_fin():
	#if (timer_for_text):
	animateText(gameOverText)
	
func on_gameover_timer_fin_WON():
	print("step2")
	var outro = $"/root/Control/DemoOutro"
	outro.show()
	$"/root/Control/Cam2D"._set_current(false)
	$"/root/Control/DemoOutro/DemoOutroCam"._set_current(true)
	#outro.set_global_position($"/root/Control/Cam2D".get_global_position())
	
	outro.connect("finished", self, "on_outro_fin")
	outro.play()
#	else:
#		#make text disapear
func on_outro_fin():
	global.replay()

#		textTween.interpolate_property(self, "percent_visible", 1, 0, 0.2 , 0, Tween.EASE_OUT)
#		textTween.start()
#		remove_child(gameover_timer)
	 
#func _process(delta):
#	var camPosX
#	var camPosY
#	if(true):
#		var camthign = get_node("Camera2D").get_viewport().get_position()
#		camPosX = get_node("Camera2D").get_visible_rect().size.x/2
#		camPosY = get_node("Camera2D").get_visible_rect().size.y/2
#		self.set_position(camthign)
#		print(camthign)
func timer_reset(text):
	if (blink):
		set_text(str(text, "_"))

	else: set_text(text)

	timer = Timer.new()
	add_child(timer)
	timer.set_one_shot(true)
	timer.set_wait_time(1)
	timer.connect("timeout", self, "on_timeout_complete")
	timer.start()
	#if (global.get("pressing_e")):
#
func on_timeout_complete():
	blink = !blink
	timer_reset(texttt)
	
func animateText(text):

	self.set_text(text)
	texttt = text
	var text_time = 3
	
	textTween = Tween.new()
	add_child(textTween)
	textTween.interpolate_property(self, "percent_visible", 0, 1, text_time , 0, Tween.EASE_OUT, 2)
	textTween.start()
	timer_reset(text)