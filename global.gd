extends Node

#ALEJANDRO (Feb-14-2020)
#this is the global script that should be used across all levels.
#I think its still in development of transitiong all of its original
#functionality to the lvl1 script and leaving here only the actual
#global functionalities across all the levels.

#ALEJANDRO (Feb-23-2020)
#changed the queue_free to deferred with free due to a
#a smart guy on reddit saying to do so... hahaha
#https://www.reddit.com/r/godot/comments/8hp3ok/use_call_deferredfree_instead_of_queue_free/

onready var interactNode = $"/root/Control/astro/InteractFont"

var current_scene
var new_scene

var current_interact
var pressing_e 
var controls_enabled
var can_reset
var playTest
var astroDead

#
func _ready():
	init()
	
func init():
	current_scene = null
	new_scene = null
	current_interact = null
	pressing_e = false
	controls_enabled = true
	can_reset = false
	astroDead = false
	

	playTest = false
	


func replay():
	init()
	get_tree().change_scene("res://MainMenu.tscn")

	
func goto_scene(path):
	get_tree().change_scene(path)
	
func newTween(object, tweeningMethod, startVars, endVars, time, delay, timeoutObject, timeOutConnection):
	var tween = Tween.new()
	object.add_child(tween)

	#can you connect tween_completed to multiple methods?
	tween.connect("tween_completed", self, "DestroyTween", [tween])

	tween.interpolate_property(object, tweeningMethod, startVars, endVars, time , 0, Tween.EASE_OUT, delay)
	tween.connect("tween_completed", timeoutObject, timeOutConnection)

	
	tween.start()
	
	#in case we want to do shit with it
	return tween

func newTweenNoConnection(object, tweeningMethod, startVars, endVars, time, delay):
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(object, tweeningMethod, startVars, endVars, time , 0, Tween.EASE_OUT, delay)
	#can you connect tween_completed to multiple methods?
	tween.connect("tween_completed", self, "DestroyTween", [tween])
	tween.start()
	
	#in case we want to do shit with it
	return tween
	
func DestroyTween(object, key, tweenObj):
	
	tweenObj.call_deferred('free')

	
#func newTimer(object, time, oneshot, timeoutConnection):
func newTimer(time, ref = null):#object, method):#, object, method):
	var timer = Timer.new()
	add_child(timer)
	timer.set_one_shot(true)
	timer.set_wait_time(time)
	timer.connect("timeout", self, 'DestroyTimer', [timer, ref])
	timer.start()
	return timer
	

func DestroyTimer(timer, ref):
	#before was using yield which seemed to cause some memory issues,
	#so went back to old way and just used the refs that were being passed
	#that had already been setup
	
	timer.call_deferred('free')
	
	#refered method
	if (ref != null):
		ref.call_func()
	

func InteractInterfaceCheck(var interactObj):
	if (!interactObj.has_method('Interact')):
		push_error("Interact item missing 'Interact'")
		
	if (!interactObj.has_method('AutoInteract')):
		push_error("Interact item missing 'AutoInteract'")
		
	if (!interactObj.has_method('AutoCloseInteract')):
		push_error("Interact item missing 'AutoCloseInteract'")
		
			
	