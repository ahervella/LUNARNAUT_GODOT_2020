tool
extends Sprite



export (Texture) var acidTexture setget setAcidTexture
export (Texture) var elecTexture setget setElectTexture

export (global.HAZ) var hazardType = global.HAZ.ACID

func setAcidTexture(val):
	acidTexture = val
	setTexture()

func setElectTexture(val):
	elecTexture = val
	setTexture()

func setTexture():
	if hazardType == global.HAZ.ACID:
		set_texture(acidTexture)
	else:
		set_texture(elecTexture)

func _on_HAZARD_AREA_body_entered(body):
	if !body.is_in_group("astro") && !body.is_in_group("object"): return
	body.hazardEnabled(true, hazardType)


func _on_HAZARD_AREA_body_exited(body):
	if !body.is_in_group("astro") && !body.is_in_group("object"): return
	body.hazardEnabled(false)
