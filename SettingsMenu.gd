extends VBoxContainer


onready var main_menu = $"../MainMenu"
onready var open_behaviour_button := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/OpenGameBehaviour/OptionButton
onready var open_file_behaviour_button := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/OpenFile/OptionButton
onready var replace_behaviour_button := $Control/MarginContainer/Buttons/ScrollContainer/VBoxContainer/Replace/OptionButton

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

func _on_Back_pressed():
	Settings.save_settings()
	hide()
	main_menu.show()

func _on_CloseBehaviour_item_selected(index):
	Settings.data.action_on_launch = index

func _on_OpenFile_item_selected(index):
	Settings.data.action_on_open_file = index

func _on_Replace_item_selected(index):
	Settings.data.action_on_replace = index
