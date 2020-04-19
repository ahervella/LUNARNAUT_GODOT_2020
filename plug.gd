extends Resource

class_name Plug

enum PLUG_TYPE {
	AUX,
	PWR,
	VGA,
	NET
}

enum PLUG_REGION {
	USA,
	RUS,
	GER,
	UNI
}

export (bool) var male = false
export (bool) var canGrab = true
export (Texture) var plugSprite = null
export (PLUG_REGION) var plugRegion = PLUG_TYPE.AUX
export (PLUG_TYPE) var plugType = PLUG_REGION.USA
#connPlug is set by cable when its cable end collision area runs into another
#cable or port collision area
var connPlug = null setget setConnection

func getSprite():
	return plugSprite

func setConnection(plugPath):
	#if is not of type plug && its not a port && this is male, return && not null && not astro
	if (plugPath.has_method("setConnection")):

		if (plugPath.male != male
		&& (plugPath.plugRegion == plugPath || plugPath.plugRegion == PLUG_REGION.UNI)
		&& (plugPath.plugType == plugType)):
			connPlug = plugPath
			return
	
	if (plugPath.script == "res://SCRIPTS/astroPlayer.gd"):
		connPlug = plugPath
		return
	
	else:
		connPlug = null
		return
	

