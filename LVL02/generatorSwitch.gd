extends "res://SCRIPTS/INTERACT/intr_default.gd"

const PROMPT_ON_TEXT = ">>POWER _ON _GENERATOR"
const ON_TEXT = "<<GENERATOR _ON"

const PROMPT_OFF_TEXT = ">>POWER _OFF _GENERATOR"
const OFF_TEXT = "<<GENERATOR _OFF"


func Interact():
	if !global.lvl().generatorOn:
		set_rotation(deg2rad(200))
		global.lvl().generatorOn = true
		TC_INTERACT.text = ON_TEXT
		TC_INTERACT.ColorType = TextConfig.colorType.good
		TC_AUTO.text = PROMPT_OFF_TEXT
	else:
		set_rotation(deg2rad(245))
		global.lvl().generatorOn = false
		TC_INTERACT.text = OFF_TEXT
		TC_INTERACT.ColorType = TextConfig.colorType.alert
		TC_AUTO.text = PROMPT_ON_TEXT
	.Interact()
	

