extends VBoxContainer


onready var main_menu = $"../MainMenu"
onready var open_behaviour_button := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/OpenGameBehaviour/OptionButton
onready var open_file_behaviour_button := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/OpenFile/OptionButton
onready var replace_behaviour_button := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/Replace/OptionButton
onready var copy_builtin := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/CopyBuiltin

func _ready():
	for option in Settings.ACTION_ON_LAUNCH:
		open_behaviour_button.add_item(option.capitalize())
	open_behaviour_button.select(Settings.data.action_on_launch)
	
	for option in Settings.ACTION_ON_OPEN_FILE:
		open_file_behaviour_button.add_item(option.capitalize())
	open_file_behaviour_button.select(Settings.data.action_on_open_file)
	
	for option in Settings.ACTION_ON_REPLACE:
		replace_behaviour_button.add_item(option.capitalize())
	replace_behaviour_button.select(Settings.data.action_on_replace)

func _on_Okay_pressed():
	Settings.save_settings()
	hide()
	main_menu.show()

func _on_Cancel_pressed():
	Settings.load_settings()
	hide()
	main_menu.show()

func _on_CloseBehaviour_item_selected(index):
	Settings.data.action_on_launch = index

func _on_OpenFile_item_selected(index):
	Settings.data.action_on_open_file = index

func _on_Replace_item_selected(index):
	Settings.data.action_on_replace = index


func _on_SettingsMenu_opened():
	if not visible: return
	
	open_behaviour_button.clear()
	for option in Settings.ACTION_ON_LAUNCH:
		open_behaviour_button.add_item(option.capitalize())
	open_behaviour_button.select(Settings.data.action_on_launch)
	
	open_file_behaviour_button.clear()
	for option in Settings.ACTION_ON_OPEN_FILE:
		open_file_behaviour_button.add_item(option.capitalize())
	open_file_behaviour_button.select(Settings.data.action_on_open_file)
	
	replace_behaviour_button.clear()
	for option in Settings.ACTION_ON_REPLACE:
		replace_behaviour_button.add_item(option.capitalize())
	replace_behaviour_button.select(Settings.data.action_on_replace)
	
	
	copy_builtin.disabled = Settings.launcher_godot_version in Settings.get_installed_engines(false)

func _on_OpenGamesFolder_pressed():
	OS.shell_open("file://" + Settings.save_location)

func _on_OpenEnginesFolder_pressed():
	OS.shell_open("file://" + Settings.engine_save_location)

func _on_CopyBuiltin_pressed():
	var dir = Directory.new()
	var target_dir = Settings.engine_save_location + Settings.launcher_godot_version + ".exe"
	dir.copy(OS.get_executable_path(), target_dir)
	copy_builtin.disabled = true
	copy_builtin.release_focus()


