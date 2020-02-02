extends Node

onready var interactNode = $"/root/Control/astro/InteractFont"

var current_scene
var new_scene
#var has_key
#var spawn_key
var current_interact
var pressing_e 
var controls_enabled
var can_reset
#var playtest
#var spawnNora
#var doorOpened
var astroDead

#
func _ready():
	init()
	
func init():
	current_scene = null
	new_scene = null
#	has_key = false
#	spawn_key = true
	current_interact = null
	pressing_e = false
	controls_enabled = true
	can_reset = false
#	spawnNora = false
	astroDead = false
#	doorOpened = false

	#playtest = true
	
	
	#if (playtest):
	#	pass
	#	spawnNora = false
	#	has_key = false
	#	spawn_key = true
	#	astroDead = false
	#	doorOpened = false
	#else:
	#	controls_enabled = true
	
	#var root = get_tree().get_root()
	#current_scene = root.get_child( root.get_child_count() -1 )
	
	
	
#func goto_scene(path):
#	call_deferred("_deferred_goto_scene",path)
#
#func _deferred_goto_scene(path):
#	current_scene.free()
#	var s = ResourceLoader.load(path)
#	current_scene = s.instance()
#	get_tree().set_current_scene( current_scene )

func replay():
	init()
	get_tree().change_scene("res://MainMenu.tscn")

	
func goto_scene(path):
	get_tree().change_scene(path)
#	var s = ResourceLoader.load(path)
#	new_scene = s.instance()
#	#get_tree().get_root().free()
#	get_tree().get_root().add_child(new_scene)
#	get_tree().set_current_scene(new_scene)
#
#	current_scene.queue_free()
#	current_scene = new_scene
	
func newTween(object, tweeningMethod, startVars, endVars, time, delay, timeoutObject, timeOutConnection):
	var tween = Tween.new()
	object.add_child(tween)

	#can you connect tween_completed to multiple methods?
	tween.connect("tween_completed", self, "DestroyTween")

	tween.interpolate_property(object, tweeningMethod, startVars, endVars, time , 0, Tween.EASE_OUT, delay)
	tween.connect("tween_completed", timeoutObject, timeOutConnection)

	
	tween.start()
	#return tween

func newTweenNoConnection(object, tweeningMethod, startVars, endVars, time, delay):
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(object, tweeningMethod, startVars, endVars, time , 0, Tween.EASE_OUT, delay)
	#can you connect tween_completed to multiple methods?
	tween.connect("tween_completed", self, "DestroyTween")
	tween.start()
	
func DestroyTween(object, key):
	pass
	#object.remove(object, key)

func newTimerOLD(object, time, oneshot, timeoutConnection):
#func newTimer(time):#, object, method):
	var timer = Timer.new()
	object.add_child(timer)
	timer.set_one_shot(oneshot)
	timer.set_wait_time(time)
	timer.connect("timeout", object, timeoutConnection)
	timer.start()
	#return 9
	#yield(get_tree().create_timer(time), "timeout")
	#object.method

	
#func newTimer(object, time, oneshot, timeoutConnection):
func newTimer(time, ref):#object, method):#, object, method):
	#var timer = Timer.new()
	#object.add_child(timer)
	#timer.set_one_shot(oneshot)
	#timer.set_wait_time(time)
	#timer.connect("timeout", object, timeoutConnection)
	#timer.start()
	#return 9
	yield(get_tree().create_timer(time), "timeout")
	#execture method after yield is over
	if (ref != null):
		ref.call_func()

func InteractInterfaceCheck(var interactObj):
	if (!interactObj.has_method('Interact')):
		push_error("Interact item missing 'Interact'")
		
	if (!interactObj.has_method('AutoInteract')):
		push_error("Interact item missing 'AutoInteract'")
		
	if (!interactObj.has_method('AutoCloseInteract')):
		push_error("Interact item missing 'AutoCloseInteract'")
		
	#TODO: force TextInteract to be part of it
	if (!interactObj.has_method('TextInteract')):
		push_error("Interact item missing 'TextInteract'")
			
	