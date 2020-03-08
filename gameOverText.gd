extends RichTextLabel


#ALEJANDRO (Feb-07-2020)
#Script for showing a successfully completed demo ontop
#of the end of demo video
#
var timer
var breakTimerLoop = false
var blink = true
export (String) var gameWonText = ">> LOGGING_PROGRESS >> OXYGEN_STABLE"
export (Vector2) var gameWonPos = Vector2(330, 340)
export (String) var gameLostText = ">> . . . _SIGNAL _LOST//"
export (Vector2) var gameLostPos = Vector2(480, 340)
var currText
var gameWon

const TYPE_TEXT_TIME = 3
const ERASE_TEXT_TIME = 1
const DISPLAY_TEXT_TIME = 4
const DELAY_AFTER_TEXT = 2

func timer_reset():
	
	#need to to do this or else timers stack up on eachother for somereason, despite being
	#called to self destroy when they are done running
	#been needing to check class due to mem reassigning bug, then make it null anyways
	#in case it is pointing to something bogus
	if (is_instance_valid(timer) && timer.is_class("Timer")):
		timer.call_deferred('free')
	timer = null
	
	if (breakTimerLoop):
		breakTimerLoop = false
		return
		
	if (blink):
		set_text(str(currText, "_"))

	else:
		set_text(currText)
		
		
	
	timer = global.newTimer(1, funcref(self, 'on_timeout_complete'))
	
#
func on_timeout_complete():
	blink = !blink
	timer_reset()




func animateText(wonBool):
	gameWon = wonBool
	currText = gameLostText
	set_position(gameLostPos)
	
	if (wonBool):
		currText = gameWonText
		set_text(gameWonText)
		set_position(gameWonPos)
		
	set_percent_visible(0)
	set_text(currText)
	global.newTween(self, 'percent_visible', 0, 1, TYPE_TEXT_TIME, 0, funcref(self, 'postTextAnimate'))
	
	
func postTextAnimate():
	timer_reset()
	global.newTween(self, 'percent_visible', 1, 0, ERASE_TEXT_TIME, DISPLAY_TEXT_TIME, funcref(self, 'startDelayTimer'))
	
	
func startDelayTimer():
	global.newTimer(DELAY_AFTER_TEXT, funcref(self, 'continueGame'))
	
func continueGame():
	if gameWon:
		print("sfdf")
		global.lvl().loadNextLevel()
		return
		
	global.lvl().reloadLevelLastSave()