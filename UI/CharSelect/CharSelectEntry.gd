extends Node

export (Resource) var Character

export (NodePath) var textName
export (NodePath) var textNationality
export (NodePath) var textDescription
export (NodePath) var texture


func initialize(character):
	Character = character
	get_node(textName).text = "Name: %s" % Character.name
	get_node(textNationality).text = "Nationality: %s" % Character.nationality
	get_node(textDescription).text = "Description: %s" % Character.description
	get_node(texture).texture = Character.texture


func _on_Button_button_up():
	global.initCharSwitch(Character.id)
	
