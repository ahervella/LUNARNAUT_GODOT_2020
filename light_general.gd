extends Light2D

export (bool) var blink = false
export (bool) var fadeBlink = false
export (float) var fadeTime = 0.5
#export (float) var blinkOffTime = 1
#export (float) var blinkOnTime = 1
export (Array, float) var blinkOnOffSequence = [1.0, 1.0]

var tween
var timer
var startAlpha
var currBlinkOn = true
var currBlinkIndex = 0

func _ready():
	if !blink: return
	
	tween = Tween.new()
	add_child(tween)
	
	timer = Timer.new()
	add_child(timer)
	
	startAlpha = get_color().a
	
	timer.connect("timeout", self, "nextBlink")
	#tween.connect("tween_completed", self, "nextBlink")
	blink(currBlinkOn)
	
func blink(blinkOn):
	var currClr = get_color()
	var newClr = Color(currClr.r, currClr.g, currClr.b, startAlpha) if blinkOn else Color(currClr.r, currClr.g, currClr.b, 0)
	var blinkTime = blinkOnOffSequence[currBlinkIndex]
	var tweenTime = fadeTime if fadeBlink else 0
	
	tween.stop_all()
	tween.interpolate_property(self, "color", currClr, newClr, tweenTime, Tween.TRANS_LINEAR)
	tween.start()
	
	timer.set_wait_time(blinkTime)
	timer.start()
	#was causing weird processing spikes. Should probably revisit this shit so
	#that its just a short cut for doing this and adding to the designated node
	#with the option to remove
	#global.newTimer(blinkTime, funcref(self, "nextBlink"))

func nextBlink(object = null, key = null):
	currBlinkIndex += 1
	if currBlinkIndex == blinkOnOffSequence.size():
		currBlinkIndex = 0
		
	currBlinkOn = !currBlinkOn
	blink(currBlinkOn)
