tool
extends Sprite



export (Texture) var acidTexture setget setAcidTexture
export (Texture) var elecTexture setget setElectTexture
export (bool) var enabled = true setget setEnabled
export (bool) var deathUponTouchingSource = false
export (NodePath) var customCollShapePath = null 

export (global.HAZ) var hazardType = global.HAZ.ACID setget setTexture

#export (NodePath) var hazardAreaPath = NodePath("HAZARD_AREA") setget setHazArea
var hazardArea = null

#export (NodePath) var hazardDefShapePath = NodePath("HAZARD_AREA/HAZARD_SHAPE")
var hazardDefShape = null

var customCollShape = null

var childAreaDict = {}

var hazIDNodeDict = {}


func _ready():
	if Engine.editor_hint: return
	
	setHazardAreaAndShape()
	
	if customCollShapePath != null:
		setCustomShape(get_node(customCollShapePath))
		
	
	
func setHazardAreaAndShape():
	hazardArea = get_node("HAZARD_AREA")
	hazardDefShape = get_node("HAZARD_AREA/HAZARD_SHAPE")
	
	hazIDNodeDict["HAZARD_AREA"] = hazardArea

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
		#child.set_disabled(!val)
		child.set_deferred("disabled", !val)
		
	if customCollShape != null:
		#hazardDefShape.set_disabled(true)
		hazardDefShape.set_deferred("disabled", true)

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
	hazardDefShape.set_deferred("disabled", !enable)#set_disabled(!enable)
	hazardDefShape.set_visible(enable)

func clearTextures():
	acidTexture = null
	elecTexture = null
	set_texture(null)

func _on_HAZARD_AREA_body_entered(body):
	bodyEntered(body, "HAZARD_AREA", deathUponTouchingSource)


func _on_HAZARD_AREA_body_exited(body):
	bodyExited(body, "HAZARD_AREA")


func bodyEntered(body, areaID, killAstro = false):
	if Engine.editor_hint: return
	
	if (!body.is_in_group("astro") 
	&& !body.is_in_group("object")
	&& !body.is_in_group("block")): return
	
	if body.is_in_group("block"):
		body.get_parent().hazardEnabled(true, hazardType, areaID, self, killAstro)
	else:
		body.hazardEnabled(true, hazardType, areaID, self, killAstro)
	
func bodyExited(body, areaID):
	if Engine.editor_hint: return
	
	if (!body.is_in_group("astro") 
	&& !body.is_in_group("object")
	&& !body.is_in_group("block")): return
	
	if body.is_in_group("block"):
		body.get_parent().hazardEnabled(false, hazardType, areaID, self, false)
	else:
		body.hazardEnabled(false, hazardType, areaID, self, false)


func isAreaInSourceRoute(hazID, startingHazID):
	var parentHazID = null
	for key in childAreaDict.keys():
		if childAreaDict[key].has(startingHazID):
			parentHazID = key
			break
	if parentHazID == null: return false
	if parentHazID == hazardArea.get_name(): return false
	else:
		if parentHazID == hazID: return true
		return isAreaInSourceRoute(hazID, parentHazID)
		

func addHazardShape(hazID, objShape, objToAddTo, parentAreaID):
	
	call_deferred("addHazardShapeDEFERRED", hazID, objShape, objToAddTo, parentAreaID)
	
	
func addHazardShapeDEFERRED(hazID, objShape, objToAddTo, parentAreaID):
	if Engine.editor_hint: return
	
	#if isParentLoop(): return
	
	var dupShape = objShape.duplicate()
	dupShape.set_global_scale(objShape.get_global_scale() * 1.05)
	var newArea = Area2D.new()
	newArea.set_name(hazID)
	
	objToAddTo.add_child(newArea)
	newArea.set_owner(objToAddTo)
	
	hazIDNodeDict[hazID] = newArea
	
	
	
	#yield(get_tree(), "idle_frame")
	newArea.add_child(dupShape)
	dupShape.set_owner(newArea)
	
	dupShape.set_global_scale(objShape.get_global_scale() * 1.05)
	
	if !childAreaDict.has(parentAreaID):
		childAreaDict[parentAreaID] = []
		
	childAreaDict[parentAreaID].append(hazID)
	
	
	
	#updateHazardShape(hazID, objShape.get_global_transform())
	
	newArea.connect("body_entered", self, "bodyEntered", [hazID])
	newArea.connect("body_exited", self, "bodyExited", [hazID])
	
func updateHazardShape(hazID, objTransform):
	if Engine.editor_hint: return
	
	for child in get_children():
		if child.get_name() == hazID:
			child.get_child(0).set_global_transform(objTransform)
			child.get_child(0).set_global_scale(objTransform.get_scale() * 1.05)
			break
	
func removeHazardShape(hazID):
	if Engine.editor_hint: return

	for key in hazIDNodeDict.keys():
		if key == hazID:
			#remove_child(child)
			if hazIDNodeDict[key] != hazardArea:
				hazIDNodeDict[key].queue_free()
				hazIDNodeDict.erase(key)
			
			if childAreaDict.has(hazID):
				for haz in childAreaDict[hazID]:
					removeHazardShape(haz)
				
				childAreaDict.erase(hazID)
				
			for key in childAreaDict.keys():
				if childAreaDict[key].has(hazID):
					childAreaDict[key].erase(key)
					break
			
			return
	
	
	
	
	
	
	
	
	
	
	

