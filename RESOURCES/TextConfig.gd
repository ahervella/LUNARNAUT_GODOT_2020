extends Resource

class_name TextConfig

enum colorType{ 
	info,
	warning,
	alert,
	good
}

var dict = {colorType.info: Color.whitesmoke, colorType.warning: Color.yellow, colorType.alert: Color.red, colorType.good: Color.green }

export(colorType) var ColorType;
export(String) var text;


func _getColor():
	return dict[ColorType]
