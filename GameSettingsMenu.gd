extends VBoxContainer

var game_file

onready var main_menu = $"../MainMenu"
onready var title_label := $Title
onready var name_field := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/DisplayName/LineEdit
onready var engine_button := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/Engine/OptionButton

func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")
	engine_button.add_item("Godot 3.3.2")

func _on_visibility_changed():
	if visible:
		title_label.text = "%s Settings" % Settings.data.games[game_file].name
		name_field.text = Settings.data.games[game_file].name

func _on_LineEdit_text_changed(new_text:String):
	Settings.data.games[game_file].name = new_text

func _on_Back_pressed():
	if not name_field.text.empty():
		Settings.data.games[game_file].name = name_field.text
	Settings.save_settings()
	hide()
	main_menu.show()
