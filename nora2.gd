extends KinematicBody2D

#ALEJANDRO (Feb-14-2020)
#This is the latest script for making nora (the monster) do shit!
#This features calculating ray casts to know when to chase in the given direction
#our astronaut is at. Need to make this more independant if we're going to use it
#in other scenes, and probably clean up this code AND rename to something better


#make this a class?
var musicChange = true
var wait = 0
var attack = false
var attackTimer = 0
var defaultGrav = 100
var speed = 180
var grav = 100
var fric = 1
var one_shot = true
onready var rayGround = get_node("noraRayGroundRight")
onready var rayAttackTop = get_node("noraRayAttackRightTop")
onready var rayAttackBottom = get_node("noraRayAttackRightBottom")

func noraFaceRight(right):
	
	if(right):
		#rayGround = $"noraRayGroundRight" 
		rayAttackTop = $"noraRayAttackRightTop"
		rayAttackBottom = $"noraRayAttackRightBottom"
	else:
		#rayGround = $"noraRayGroundLeft" 
		rayAttackTop = $"noraRayAttackLeftTop"
		rayAttackBottom = $"noraRayAttackLeftBottom"
		
	$"noraAnim".set_flip_h(!right)
	$"noraAnimMask".set_flip_h(!right)
	
	#$"noraShapeBodyRight".set_disabled(!right)
	#$"noraShapeBodyLeft".set_disabled(right)
	
	#$"noraShapeGroundRight".set_disabled(!right)
	#$"noraShapeGroundRight2".set_disabled(!right)
	#$"noraShapeGroundLeft".set_disabled(right)
	#$"noraShapeGroundLeft2".set_disabled(right)
	if($"/root/Control".has_key):
		$"noraRayAttackRightTop".set_enabled(right)
		$"noraRayAttackRightBottom".set_enabled(right)
		$"noraRayAttackLeftTop".set_enabled(!right)
		$"noraRayAttackLeftBottom".set_enabled(!right)
	
	$"noraRayGroundRight".set_enabled(right)
	$"noraRayGroundLeft".set_enabled(!right)
	
	$"noraAreaHitBox/noraAreaHitBoxShapeRight".set_disabled(!right)
	$"noraAreaHitBox/noraAreaHitBoxShapeLeft".set_disabled(right)

func noraAnim(name):
		get_node("noraAnim").set_animation(name)
		get_node("noraAnimMask").set_animation(name + "Mask")
	 

func _ready():
	#max_move_speed = 200
	#acceleration = 10
	#decceleration = true
	noraAnim("idle")
	$"noraAnim".connect("animation_finished", self, "anim_fin")
	noraFaceRight(false)
	toggleAllNoraNodes(self, true)
	
func anim_fin():
	pass#if(get_linear_velocity().x<10 && get_node("noraAnim").get_animation() == "run"):
	#	noraAnim("idle")
	
func toggleNode(node, off):
	if node is CollisionShape2D:
		node.set_disabled(off)
	
	elif node is RayCast2D:
		node.set_enabled(!off)

func toggleAllNoraNodes(nodee, offf):
	for n in nodee.get_children():
		toggleNode(n, offf)
		if n.get_child_count() > 0:
			toggleAllNoraNodes(n, offf)

func moveLeft():
	noraFaceRight(false)
	#self.move_and_slide_with_snap(Vector2(-100, 5), Vector2(0, 10), Vector2.UP, false, 40, 0.9, true)
	self.move_and_slide_with_snap(Vector2(-speed, 100), Vector2(0, 0), Vector2(0, 1))
	noraAnim("run")
	#anim_key=0


func moveRight():
	noraFaceRight(true)
	#self.move_and_slide_with_snap(Vector2(100, 5), Vector2(0, 10), Vector2.UP, false, 40, 0.9, true)
	self.move_and_slide_with_snap(Vector2(speed, 100), Vector2(0, 100), Vector2(0, 1))
	#ray.set_collide_with_bodies(true)
	#directional_force += DIRECTION.RIGHT
	#if anim_key==1:
	noraAnim("run")


func _physics_process(delta):
	
	if (!$"/root/Control".spawnNora && one_shot):
		return
	else:
		one_shot = false
		toggleAllNoraNodes(self, false)
	#var get_fric = get_physics_material_override()
	
	#ray cast to attack astro
	var attackingTop = (rayAttackTop.is_colliding()==true && rayAttackTop.get_collider().is_in_group("astro")) 
	var attackingBottom = (rayAttackBottom.is_colliding()==true && rayAttackBottom.get_collider().is_in_group("astro")) 
	if ((attackingTop || attackingBottom) && !global.get("astroDead")  ):
		#print("gethim!!!!")

		attack = true
	else:
		#print("nor")
		attack = false
		attackTimer = 0

	var noraGP = get_global_position()
	var astroGP = $"/root/Control/astro".get_global_position()
		
	
	
	

	if (attack):
		
		#SCARY NOISES
		if (musicChange):
			var music = $"/root/Control/astro/music"
			var musicIntense = $"/root/Control/astro/musicIntense"
			
			var timePlay = music.get_playback_position()
			var ogVol = music.get_volume_db()
			musicIntense.set_volume_db (-50)
			musicIntense.play(timePlay)
			#fade the two in and out
			global.newTween(music, "volume_db", ogVol, -50, 3, 0, self, "onMusicStop")
			global.newTweenNoConnection(musicIntense, "volume_db", -50,  ogVol, 1, 0)
			
			$"/root/Control/astro/cinematicBoom".play(0)
			$"/root/Control/astro/lowPulse".play(0)
			$"/root/Control/astro/breathingScared".play(0)
			$"/root/Control/astro/breathingCalm".stop()
			musicChange = false
		
		attackTimer += 1
		
		if(attackTimer < 300):
			wait = 0
			#print("movingin")
		
			if (noraGP.x < astroGP.x):
				moveRight()
			else:
				moveLeft()
		else:
			var noraPosX = self.get_global_position().x
			var astroPosX = $"/root/Control/astro".get_global_position().x
			
			if (noraPosX > astroPosX ):
				noraFaceRight(false)
			else:
				noraFaceRight(true)
			
			noraAnim("idle")
		
	if(attackTimer >= (360)):
		if(attack):
			attackTimer = 0
		else:
			if(!musicChange):
				$"/root/Control/astro/breathingScared".stop(0)
				$"/root/Control/astro/breathingCalm".play(0)
				musicChange = true
	
	wait += 1
	
	if (wait>=180 and wait<(240) && !attack):
		moveLeft()
		#moveRight()

	elif (wait>=400 and wait<480 && !attack):
		#moveLeft()
		moveRight()
		
	elif(!attack):
		noraAnim("idle")
		
	if(wait >= 480):
		wait = 0;
	

func onMusicStop(object, key):
	$"/root/Control/astro/music".stop()

func _on_noraAreaHitBox_body_entered(body):
	var groups = body.get_groups()
	if(groups.has("astro")):
		attackTimer = 300
		wait = 0
	
