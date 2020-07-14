tool
extends Sprite



export (Texture) var acidTexture setget setAcidTexture
export (Texture) var elecTexture setget setElectTexture

export (global.HAZ) var hazardType = global.HAZ.ACID setget setTexture

var childAreaDict = {}

func setAcidTexture(val):
	acidTexture = val
	setTexture()

func setElectTexture(val):
	elecTexture = val
	setTexture()

func setTexture(val = null):
	if val != null:
		hazardType = val
	if hazardType == global.HAZ.ACID:
		if acidTexture != null:
			set_texture(acidTexture)
	else:
		if elecTexture != null:
			set_texture(elecTexture)




func _on_HAZARD_AREA_body_entered(body):
	bodyEntered(body, "HAZARD_AREA")


func _on_HAZARD_AREA_body_exited(body):
	bodyExited(body, "HAZARD_AREA")


func bodyEntered(body, areaID):
	if !body.is_in_group("astro") && !body.is_in_group("object"): return
	body.hazardEnabled(true, hazardType, areaID, self)
	
func bodyExited(body, areaID):
	if !body.is_in_group("astro") && !body.is_in_group("object"): return
	body.hazardEnabled(false, hazardType, areaID, self)

func addHazardShape(hazID, objShape, parentAreaID):
	var dupShape = objShape.duplicate()
	#dupShape.add_to_group(hazID)
	var newArea = Area2D.new()
	newArea.set_name(hazID)
	
	add_child(newArea)
	newArea.set_owner(self)
	
	newArea.connect("body_entered", self, "bodyEntered", [hazID])
	newArea.connect("body_exited", self, "bodyExited", [hazID])
	
	newArea.add_child(dupShape)
	dupShape.set_owner(newArea)
	
	childAreaDict[parentAreaID] = hazID
	
	
	
	updateHazardShape(hazID, objShape.get_global_transform())
	
func updateHazardShape(hazID, objTransform):
	for child in get_children():
		if child.get_name() == hazID:
			child.get_child(0).set_global_transform(objTransform)
			child.get_child(0).set_global_scale(objTransform.get_scale() * 1.05)
			break
	
func removeHazardShape(hazID):
	for child in get_children():
		if child.get_name() == hazID:
			remove_child(child)
			
			if childAreaDict.has(hazID):
				removeHazardShape(childAreaDict[hazID])
				
			for key in childAreaDict.keys():
				if childAreaDict[key] == hazID:
					childAreaDict.erase(key)
					break
			
			return
	
	
	
	
	
	
	
	
	
	
	

