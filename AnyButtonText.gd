extends RichTextLabel

var blink = true
var timer
var gameover_timer
var texttt
var gameOverText = "[   PRESS ANY BUTTON FOR MAIN MENU   ]"
var timer_for_text = true
var textTween
var act = false
var gameWon = false

func _ready():
	set_text("")
	set_percent_visible(0)
	
	#for centering the text
	set_position(Vector2(get_viewport().get_size().x/2 - get_size().x/2, get_position().y))
	
	#onGameOver()
	#var camthign = get_node("Camera2D").get_viewport().get_global_position()
	#print (camthign)
func onGameOver(gameState):
	gameWon = gameState
	
	gameover_timer = Timer.new()
	add_child(gameover_timer)
	gameover_timer.set_one_shot(true)
	gameover_timer.set_wait_time(1)
	
	gameover_timer.connect("timeout", self, "on_gameover_timer_fin")
	gameover_timer.start()
	
func on_gameover_timer_fin():
	if(!gameWon):
		animateText(gameOverText)
		
#	else:
#		#global.set("game_won", true):
#		var demoOutro = $"/root/Control/DemoOutro"
#		demoOutro.connect("finished", self, "DemoOutroFinished")
#		demoOutro.show()
#		demoOutro.play()
#		#global.set("can_reset", true)
#		#global.set("game_won", true)

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
#
func on_timeout_complete():
	blink = !blink
	timer_reset(texttt)
	
func animateText(text):

	self.set_text(text)
	texttt = text
	var text_time = 2
	
	textTween = Tween.new()
	add_child(textTween)
	textTween.connect("tween_started", self, "on_tween_start")
	textTween.interpolate_property(self, "percent_visible", 0, 1, text_time , 0, Tween.EASE_OUT, 6)
	textTween.start()
	timer_reset(text)
	
	
func on_tween_start(object, key):
	
	global.set("can_reset", true)
	