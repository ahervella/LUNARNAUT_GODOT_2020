extends Node2D

#ALEJANDRO (Feb-18-2020)
#This is our script for the audio resource manager! I've thought about how
#we should go about managing sounds, and being able to adjust the volume on
#each within the inspector, and be able to edit the sounds assigned to each
#easily. 

#To do this, I made a custom inspector property that takes the file name. By not having
#it as a resource and file path, none of the sounds are actually loaded on runtime (or compile time)

#The rest of the audio code searches through the SOUNDS folder to find
#the sound file when it's time to load it!




#ALEJANDRO (Feb-23-2020)
#Here was thinking of using enums so that when selecting a sound in the script, there would be a menu instead
#of the programmer having to give a string that would have to match up and would only cause an error on run time
#but moving nodes around in the editor audio scene would require to touch the code as well, so if the code
#can just stay put and people move the groups around in the editor then that just might be better
#enum GLOBAL {
#	suitBeep,
#	breathingCalm,
#	breathingScared,
#	breathingHurt,
#	gotObject,
#	doorTextSound,
#	doorOpenSound,
#	}
#
#var global : Dictionary #= {
##	GLOBAL.suitBeep : $"global/suitBeep",
##	GLOBAL.breathingCalm : $"global/breathingCalm",
##	GLOBAL.breathingScared : $"global/breathingScared",
##	GLOBAL.gotObject : $"global/gotObject",
##	GLOBAL.doorText : $"global/doorText",
##	GLOBAL.doorOpen : $"global/doorOpen"
##	}
#
#
#enum LVL01 {
#	music,
#	musicIntense,
#	cinematicBoom,
#	cinematicBoom2,
#	lowPulse
#	}
#
#var lvl01 : Dictionary #= {
##	GLOBAL.music : $"lvl01/suitBeep",
##	GLOBAL.musicIntense : $"lvl01/breathingCalm",
##	GLOBAL.cinematicBoom : $"lvl01/cinematicBoom",
##	GLOBAL.cinematicBoom2 : $"lvl01/cinematicBoom2",
##	GLOBAL.lowPulse : $"lvl01/lowPulse"
##	}

var enumSounds : Dictionary

var sounds : Dictionary

var files : Array = []

func _ready():

	#populateSoundDict(global, GLOBAL, "global/")
	#populateSoundDict(lvl01, LVL01, "lvl01/")


	files = filesInDirectory(files, "res://SOUNDS/")
	
	
	for group in get_children():
		
		var soundGroup : Dictionary
		
		for soundNode in group.get_children():
			
			if (soundNode.get_stream() != null):
				#this error is to make sure a programmer does NOT populate any of the audioStream fields!
				push_error("Alejandro: don't add a path/resource to the stream, for the sound resource manager!")
				
			var soundNameString = soundNode.get("SoundNameString")
			if (!files.has(soundNameString)):
				push_error(soundNameString + ": file not found in SOUNDS folder(s)")
				
			soundGroup[soundNode.name] = soundNode.get("SoundNameString")
			
			
			soundNode.set_stream(null)
		
		sounds[group.name] = soundGroup
	
	loadLevelSounds("global")
	
	
#func populateSoundDict(dict : Dictionary, enumObj, nodeGroupPathName : String):
#	for enumVal in enumObj.keys():
#		dict[enumObj[enumVal]] = get_node(nodeGroupPathName + enumVal)
	
func filesInDirectory(files : PoolStringArray, path) -> PoolStringArray:
	var dir = Directory.new()
	if (dir.open(path) == OK):
		
		dir.list_dir_begin()
		
		var file_name = null
		
		while (file_name != ""):
			file_name = dir.get_next()
			
			if (file_name.begins_with(".")):
				continue
			
			if (dir.current_is_dir()):
				files = filesInDirectory(files, (path + file_name))
				continue
				
			elif(!file_name.ends_with(".import")):
				files.append(file_name)
			
			file_name = dir.get_next()
			
			
		dir.list_dir_end()
		
		#for s in files:
			#print(s)
	
	else:
		push_error("couldn't open dat directory!")
	
	return files
	
	
	
func sound(soundNode : String, soundGroup : String = "global"):
	return get_node(soundGroup + "/" + soundNode)
	
	
func unloadLevelSounds():
	for group in get_children():
		#should always have global sounds loaded
		if (group.name == "global"):
			continue
		for soundNode in group.get_children():
			soundNode.set_stream(null)
	
	
	
func loadLevelSounds(lvl, unloadAllOtherSounds = true):
	
	if unloadAllOtherSounds:
		unloadLevelSounds()
	
	if has_node(lvl):
		for soundNode in get_node(lvl).get_children():
			
			soundNode.set_stream(load ("res://SOUNDS/" + sounds[lvl][soundNode.name]))
	
	
