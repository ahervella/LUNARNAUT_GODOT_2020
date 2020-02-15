extends AnimatedSprite

#ALEJANDRO (Feb-14-2020)
#interact script for the oxygen canister (only for level 1
# as of this date). Takes care of all interactions and actions
# having to do with the canister

var canUseO2 : bool = true;
const O2_TEXT = "OXYGEN"
onready var soundNode = null

func _ready():
	self.set_animation("GREEN")
	#set_process()


func Interact():
	if (canUseO2):
		use_o2()
		global.interactNode.closeText()

func AutoInteract():
	print("canisterInteract")
	TextInteract()

func AutoCloseInteract():
	if (canUseO2):
		global.interactNode.closeText()

	
func TextInteract():
	if (canUseO2):
		global.interactNode.animateText(O2_TEXT)
	

func use_o2():
	$"/root/Control/astro/gotKeySound".play(0)
	self.set_animation("RED")
	canUseO2 = false
	$"/root/Control/astro".inc_health()
	$"/root/Control/astro".inc_health()
	$"/root/Control/astro".inc_health()
		
