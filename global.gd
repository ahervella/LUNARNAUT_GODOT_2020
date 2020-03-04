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

#ALEJANDRO (Mar-01-2020)
#finally got rid of newTweenNoConnection and newTweenOld and made them work just with newTween
#can always check in the future like I was now if shit is working properly by printing the child count
#and child array of global

var interactNode #$"/root/Control/astro/InteractFont"

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
	current_scene = get_tree().get_current_scene()

	
func goto_scene(path):
	get_tree().change_scene(path)
	current_scene = get_tree().get_current_scene()
	
	
#used to get the specific level variables, funcs, and attributes
#will return null if the current scene is not the level given 
func lvl(lvlNum : int = -1):
	var scene = get_tree().get_current_scene()
	#return current lvl (because lvl usually has default vars like astro node
	if (lvlNum == -1):
		return scene
	
	#level scene names must be in "lvl##" format	
	if (int(scene.name.substr(2,4)) == lvlNum):
		return scene
	
	return null
	
	
#VVVVVVV - TWEEN AND TIMER FUNCS - VVVVVVVVVVV#
	
func newTween(object, tweeningMethod, startVars, endVars, time, delay, func_ref = null, transType = Tween.TRANS_LINEAR, tweenType = Tween.EASE_OUT):
	
	var tween = Tween.new()
	#always need to add child to something for it to work
	add_child(tween)

	#connect tween once its done to self destruct (to avoid mem leaks) and call any related funcs if any
	tween.connect("tween_completed", self, "DestroyTween", [tween, func_ref])

	tween.interpolate_property(object, tweeningMethod, startVars, endVars, time, transType, tweenType, delay)
	
	tween.start()
	
	#in case we want to do shit with it
	return tween
	
#here by default func_ref is null if nothing is passed (in case called outside here)
func DestroyTween(object, key, tweenObj, func_ref = null):
	#ensures that next frame free will be called on this tween instance
	tweenObj.call_deferred('free')

	#if any other functions to be called were passed, do that
	if (func_ref != null):
		func_ref.call_func()
	

func newTimer(time, ref = null):
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
	

#these are functions that any interact node must have (acts as an interface enforcer)
#ALSO, the interact node MUST have "interact" in node area group to work
func InteractInterfaceCheck(var interactObj):
	if (!interactObj.has_method('Interact')):
		push_error("Interact item missing 'Interact'")
		
	if (!interactObj.has_method('AutoInteract')):
		push_error("Interact item missing 'AutoInteract'")
		
	if (!interactObj.has_method('AutoCloseInteract')):
		push_error("Interact item missing 'AutoCloseInteract'")
		
			
	