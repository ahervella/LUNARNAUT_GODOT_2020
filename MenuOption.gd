tool
extends HBoxContainer

export (String) var menuOptText setget setText
#export (int) var textSize setget setFontSize
export (bool) var sideBrackets setget setSideBrackets


func setText(val):
	menuOptText = val
	$"menuOptTEXT".set_text(val)
	
func setColor(val):
	for child in get_children():
		child.set("custom_colors/font_color", val)

#func setFontSize(val):
#	textSize = val
#	for child in get_children():
#		print(child)
#		child.get("custom_fonts/font").set_size(26)
		
func setSideBrackets(val):
	sideBrackets = val
	for child in get_children():
		if child == $"menuOptTEXT": continue
#		if sideBrackets:
#			child.show()
#		else:
#			child.hide()
