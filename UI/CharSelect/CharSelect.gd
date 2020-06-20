extends Node

export (NodePath) var childContainer
export (PackedScene) var child

var path = "res://RESOURCES/CHARACTERS"

# Called when the node enters the scene tree for the first time.
func _ready():
	var files = []
	
	for astroChar in global.availableChar:
		files.append(global.charResDict[astroChar])#load(global.astroCharUserDict[astroChar]))
#
#	var dir = Directory.new()
#	dir.open(path)
#	dir.list_dir_begin(true, true)
#	var file_name = dir.get_next()
#	while file_name != "":
#		var assetPath = "%s/%s" % [path,file_name]
#		var asset = load(assetPath)
#		files.append(asset)
#		file_name = dir.get_next()
	
	for file in files:
		var entry = child.instance()
		entry.initialize(file)
		remove_child(entry)
		get_node(childContainer).add_child(entry)
	
	get_node(childContainer).queue_sort()
