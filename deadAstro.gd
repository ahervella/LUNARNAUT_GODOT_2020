extends Sprite

#finish adding message text
const O2_TEXT = "OXYGEN"
onready var soundNode = $"deadAstro2Sound"

func Interact():
	global.interactNode.closeText()

func AutoInteract():
	TextInteract()

func AutoCloseInteract():
	global.interactNode.closeText()

	
func TextInteract():
	global.interactNode.animateText(O2_TEXT)

func PlayMessage():
	soundNode.play(0)