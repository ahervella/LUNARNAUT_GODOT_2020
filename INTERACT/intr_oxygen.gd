extends AnimatedSprite

#ALEJANDRO (Feb-14-2020)
#interact script for the oxygen canister (only for level 1
# as of this date). Takes care of all interactions and actions
# having to do with the canister

var canUseO2 : bool = true
var processed = false
export (Resource) var TEXT_INTERACT

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
		global.interactNode.animateText(TEXT_INTERACT)
	

func use_o2():
	audio.sound("gotObject").play(0)
	self.set_animation("RED")
	canUseO2 = false
	global.lvl().astroNode.inc_health()
	global.lvl().astroNode.inc_health()
	global.lvl().astroNode.inc_health()
		
