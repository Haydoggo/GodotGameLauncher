extends VBoxContainer

var game_file

onready var main_menu = $"../MainMenu"
onready var title_label := $Title
onready var name_field := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/DisplayName/LineEdit
onready var engine_button := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/Engine/OptionButton
onready var version_error_label := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/Engine/VersionErrorLabel

func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")
	var dir = Directory.new()
	dir.get_next()

func _on_visibility_changed():
	if not visible: return
	
	_get_engine_options()
	title_label.text = "%s Settings" % game_file
	name_field.text = Settings.data.games[game_file].name

func _get_engine_options():
	
	var ver = Settings.data.games[game_file].godot_version
	var engines := Settings.get_installed_engines()
	
	engine_button.clear()
	
	version_error_label.hide()
	if not ver in engines:
		version_error_label.show()
		engine_button.add_item(ver)
		engine_button.set_item_disabled(0, true)
		engine_button.selected = 0
	
	for i in engines.size():
		var engine = engines[i]
		if i == 0:
			engine_button.add_item("%s (built in)" % engine)
		else:
			engine_button.add_item(engine)
		if ver == engine:
			engine_button.selected = i
	
	

func _on_LineEdit_text_changed(new_text:String):
	Settings.data.games[game_file].name = new_text

func _on_Okay_pressed():
	if not name_field.text.empty():
		Settings.data.games[game_file].name = name_field.text
	Settings.save_settings()
	hide()
	main_menu.show()

func _on_Cancel_pressed():
	Settings.load_settings()
	hide()
	main_menu.show()

func _on_EngineOptionButton_item_selected(index):
	version_error_label.hide()
	var ver = engine_button.get_item_text(index).split(" (built in)")[0]
	Settings.data.games[game_file].godot_version = ver
