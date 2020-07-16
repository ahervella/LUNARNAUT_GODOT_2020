tool
extends Sprite



export (Texture) var acidTexture setget setAcidTexture
export (Texture) var elecTexture setget setElectTexture
export (bool) var enabled = true setget setEnabled
export (NodePath) var customCollShapePath = null 

export (global.HAZ) var hazardType = global.HAZ.ACID setget setTexture

#export (NodePath) var hazardAreaPath = NodePath("HAZARD_AREA") setget setHazArea
var hazardArea = null

#export (NodePath) var hazardDefShapePath = NodePath("HAZARD_AREA/HAZARD_SHAPE")
var hazardDefShape = null

var customCollShape = null

var childAreaDict = {}


func _ready():
	if Engine.editor_hint: return
	
	setHazardAreaAndShape()
	
	if customCollShapePath != null:
		setCustomShape(get_node(customCollShapePath))
	
func setHazardAreaAndShape():
	hazardArea = get_node("HAZARD_AREA")
	hazardDefShape = get_node("HAZARD_AREA/HAZARD_SHAPE")	

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

func setEnabled(val):
	enabled = val
	
	if Engine.editor_hint: return
	
	setHazardAreaAndShape()

	for child in hazardArea.get_children():
		child.set_disabled(!val)
		
	if customCollShape != null:
		hazardDefShape.set_disabled(true)


func clearCustomShape():
	#customCollShapePath = val
	
	setHazardAreaAndShape()
	
	enabledDefaultShape(true)
	for child in hazardArea.get_children():#hazArea:
		if child != hazardDefShape:
			hazardArea.remove_child(child)
		customCollShape = null
	
	setEnabled(enabled)

func setCustomShape(shape):
	
	setHazardAreaAndShape()
	
	if (shape is CollisionShape2D || shape is Polygon2D):
		customCollShape = shape.duplicate()
		hazardArea.add_child(customCollShape)
		customCollShape.set_owner(hazardArea)
		enabledDefaultShape(false)
#	else:
#		enabledDefaultShape(true)
#		for child in hazardArea.get_children():
#			if child != hazardDefShape:
#				hazardArea.remove_child(child)
#			customCollShape = null
			
			
		setEnabled(enabled)
	

func enabledDefaultShape(enable):
	
	
	#if Engine.editor_hint: return
	if hazardDefShape == null: return
	hazardDefShape.set_disabled(!enable)
	hazardDefShape.set_visible(enable)

func clearTextures():
	acidTexture = null
	elecTexture = null
	set_texture(null)

func _on_HAZARD_AREA_body_entered(body):
	bodyEntered(body, "HAZARD_AREA")


func _on_HAZARD_AREA_body_exited(body):
	bodyExited(body, "HAZARD_AREA")


func bodyEntered(body, areaID):
	if Engine.editor_hint: return
	
	if (!body.is_in_group("astro") 
	&& !body.is_in_group("object")
	&& !body.is_in_group("block")): return
	
	if body.is_in_group("block"):
		body.get_parent().hazardEnabled(true, hazardType, areaID, self)
	else:
		body.hazardEnabled(true, hazardType, areaID, self)
	
func bodyExited(body, areaID):
	if Engine.editor_hint: return
	
	if (!body.is_in_group("astro") 
	&& !body.is_in_group("object")
	&& !body.is_in_group("block")): return
	
	if body.is_in_group("block"):
		body.get_parent().hazardEnabled(false, hazardType, areaID, self)
	else:
		body.hazardEnabled(false, hazardType, areaID, self)

func addHazardShape(hazID, objShape, parentAreaID):
	if Engine.editor_hint: return
	
	var dupShape = objShape.duplicate()
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
	if Engine.editor_hint: return
	
	for child in get_children():
		if child.get_name() == hazID:
			child.get_child(0).set_global_transform(objTransform)
			child.get_child(0).set_global_scale(objTransform.get_scale() * 1.05)
			break
	
func removeHazardShape(hazID):
	if Engine.editor_hint: return

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
	
	
	
	
	
	
	
	
	
	
	

