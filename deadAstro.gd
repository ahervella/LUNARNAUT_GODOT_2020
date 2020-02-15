extends Sprite

#ALEJANDRO (Feb-14-2020)
#don't know if this is finished yet, but idealy the
#script both deadAstros from the first level can extend
#and assign their own text, or possibly make it an editor
#field so that you type in the text via the node.
#Could maybe turn into a shared script by all things that
#Have basic text that shit could extend from?

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