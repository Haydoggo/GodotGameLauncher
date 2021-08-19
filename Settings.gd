# check for save file
# create save file
# get game info
# set game info
# get installed engines
# check for new launcher pck

extends Node

enum ACTION_ON_LAUNCH{
	None,
	Minimise,
	Close,
}

enum ACTION_ON_OPEN_FILE{
	Save,
	Open,
	SaveAndOpen,
}

enum ACTION_ON_REPLACE{
	Replace,
	DoNotReplace,
	Ask,
}

var config_file_path = OS.get_user_data_dir() + "/settings.cfg"
var data := {}
onready var dir := Directory.new()
onready var file := File.new()

func _ready():
	load_settings()

func _exit_tree():
	save_settings()

func add_game(game_file_name : String):
	data.games[game_file_name] = {
		name=game_file_name.get_file().get_basename(),
		godot_version="3.3.2",
	}

func load_settings():
	#Default settings
	data = {
			action_on_launch = ACTION_ON_LAUNCH.None,
			action_on_open_file = ACTION_ON_OPEN_FILE.SaveAndOpen,
			action_on_replace = ACTION_ON_REPLACE.Ask,
			games={},
		}
	
	if dir.file_exists(config_file_path):
		file.open(config_file_path, File.READ)
		var file_data = JSON.parse(file.get_line()).result
		for key in file_data.keys():
			data[key] = file_data[key]
		file.close()

func save_settings():
	file.open(config_file_path, File.WRITE)
	file.store_line(to_json(data))
	file.close()
