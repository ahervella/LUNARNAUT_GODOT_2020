extends Label


export (global.CHAR) var timeline

func setTimeline(astroChar):
	set_text("%s - %s" % [global.astroChar2String(astroChar), String(global.charYearDict[astroChar])])

func _ready():
	call_deferred("readyExt")
func readyExt():
	setTimeline(global.CharacterRes.id)
