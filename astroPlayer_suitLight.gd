extends Light2D


enum LIGHT {THREE_GREEN, TWO_GREEN, ONE_GREEN, ZERO_GREEN}

var lightDict = {LIGHT.THREE_GREEN : Color(0.3, 1, 0.3, 1), 
LIGHT.TWO_GREEN : Color(0.6, 0.8, 0.3, 1), 
LIGHT.ONE_GREEN : Color(0.8, 0.6, 0.3, 1), 
LIGHT.ZERO_GREEN : Color(1, 0.3, 0.3, 1)}


func setSuitLight(light):
	set_color(lightDict[light])
