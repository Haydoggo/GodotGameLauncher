extends Control

const game_button_scene = preload("res://GameButton.tscn")

var save_location := Settings.save_location
var engine_save_location := Settings.engine_save_location
var current_version := "v0.5"
var updating = false
var update_file_size := 0.0
var selected_game
var last_selected_game

onready var dir := Directory.new()
onready var req :=  $HTTPRequest
onready var dl_req := $DownloadHTTPRequest
onready var title_label := $Title
onready var games_list := $HSplitContainer/Control/VBoxContainer/MarginContainer/ScrollContainer/GamesList
onready var empty_label := $HSplitContainer/Control/EmptyLabel
onready var launch_game_button := $HSplitContainer/Buttons/LaunchGame
onready var game_settings_button := $HSplitContainer/Buttons/GameSettings
onready var checking_update_label := $HSplitContainer/Buttons/CheckingUpdateLabel
onready var update_launcher_button := $HSplitContainer/Buttons/UpdateLauncher
onready var download_label := $HSplitContainer/Buttons/DownloadLabel
onready var progress_bar := $HSplitContainer/Buttons/ProgressBar
onready var settings_menu := $"../SettingsMenu"
onready var game_settings_menu := $"../GameSettingsMenu"

func _ready():
	OS.min_window_size = Vector2(600, 200)
	
	if not dir.dir_exists(save_location):
		dir.make_dir(save_location)
	
	if not dir.dir_exists(engine_save_location):
		dir.make_dir(engine_save_location)
	
	title_label.text += " " + current_version
	
	# Handle extra arguments
	for arg in OS.get_cmdline_args():
		arg = arg.replace("\\", "/")
		
		# If the launcher has been opened as the result of an update. 
		# Proceed to delete and replace the old launcher.
		if arg == "updated":
			var exec_path := OS.get_executable_path()
			dir.remove(exec_path.get_basename() + ".exe")
			dir.rename(exec_path, exec_path.get_file().get_basename() + ".exe")
		
		# If any of the arguments are paths, it will be from the user opening 
		# opening a game file with the exe. Attempt to open these as games.
		elif arg.is_abs_path():
			var path = arg
			if Settings.data.action_on_open_file == Settings.ACTION_ON_OPEN_FILE.Open:
				open_game(path)
				get_tree().quit()
			if Settings.data.action_on_open_file == Settings.ACTION_ON_OPEN_FILE.Save:
				import_game(path)
			if Settings.data.action_on_open_file == Settings.ACTION_ON_OPEN_FILE.SaveAndOpen:
				var imported = import_game(path)
				if imported is GDScriptFunctionState:
					yield(imported, "completed")
				open_game(path)
				get_tree().quit()
	
	get_tree().connect("files_dropped", self, "import_games_from_drop")
	generate_buttons()
	
	# Check for new launcher version
	if not OS.is_debug_build() or true:
		req.connect("request_completed", self, "version_request_completed")
		req.request("https://github.com/Haydoggo/GodotGameLauncher/releases/latest")

func _process(_delta):
	if updating:
		download_label.text = "%s of %s downloaded" %\
				 [String.humanize_size(dl_req.get_downloaded_bytes()),
				  String.humanize_size(int(update_file_size))]
		if update_file_size > 0:
			progress_bar.value = dl_req.get_downloaded_bytes()/float(update_file_size) * 100.0

func _on_ImportGame_pressed():
	var file_diag = FileDialog.new()
	add_child(file_diag)
	file_diag.add_filter("*.pck; Godot game packages")
	file_diag.mode_overrides_title = false
	file_diag.window_title = "Pick a game"
	file_diag.mode = FileDialog.MODE_OPEN_FILE
	file_diag.access = FileDialog.ACCESS_FILESYSTEM
	file_diag.popup_centered_ratio()
	file_diag.connect("file_selected", self, "import_game")
	file_diag.connect("files_selected", self, "import_game")

func _on_LaunchGame_pressed():
	open_game(save_location + selected_game)

func version_request_completed(_result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray) -> void:
	req.disconnect("request_completed", self, "version_request_completed")
	
	# Search body for latest version number
	if response_code == HTTPClient.RESPONSE_OK:
		var s := body.get_string_from_utf8()
		var tag_token := "tag/"
		var version_num_start : int = s.find(tag_token) + tag_token.length()
		var version_num_end := s.find("\"", version_num_start)
		var latest_version := s.substr(version_num_start, version_num_end - version_num_start)
		update_launcher_button.text += " (%s available)" %  latest_version
		if current_version != latest_version:
			update_launcher_button.show()
			update_launcher_button.connect("pressed", self, "update_launcher", [latest_version])
		else:
			$HSplitContainer/Buttons/HSeparator2.hide()
	checking_update_label.hide()

func update_launcher(version : String) -> void:
	var download_url = "https://github.com/Haydoggo/GodotGameLauncher/releases/download/%s/Launcher.exe"%version
	req.connect("request_completed", self, "update_request_complete")
	update_launcher_button.disabled = true
	progress_bar.show()
	download_label.show()
	updating = true
	update_launcher_button.text = "Downloading %s" % version
	req.request(download_url, [], true, HTTPClient.METHOD_HEAD)
	dl_req.download_file = "%s/%s.tmp" % [OS.get_executable_path().get_base_dir(),
			OS.get_executable_path().get_file().get_basename()]
	dl_req.request(download_url)
	
	# Wait until file size is downloaded
	yield(dl_req, "request_completed")
	if not OS.is_debug_build():
		OS.execute(dl_req.download_file, ["updated"], false)
	get_tree().quit()

func update_request_complete(_result: int, _response_code: int, headers: PoolStringArray, _body: PoolByteArray):
	req.disconnect("request_completed", self, "update_request_complete")
	for header in headers:
		if header.begins_with("Content-Length"):
			update_file_size = int(header.split(": ")[1])
			break

func generate_buttons():
	for button in games_list.get_children():
		button.free()
	for game in Settings.data.games.keys():
		add_button(game)
	empty_label.visible = (games_list.get_child_count() == 0)

func refresh_games_list():
	var games = get_games_in_directory()
	for game in games:
		if not game in Settings.data.games.keys():
			Settings.add_game(game)
	var games_to_remove := []
	for game in Settings.data.games.keys():
		if not game in games:
			games_to_remove.append(game)
	for game in games_to_remove:
		Settings.data.games.erase(game)
	Settings.save_settings()
	generate_buttons()

func add_button(game_file_name):
	var game_path = save_location + game_file_name
	var button = game_button_scene.instance()
	games_list.add_child(button)
	button.game_name = Settings.data.games[game_file_name].name
	button.connect("open_game", self, "open_game",  [game_path])
	button.connect("focus_entered", self, "select_game", [game_file_name])

func get_games_in_directory() -> Array:
	var games := []
	if dir.open(save_location) == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			games.append(file_name)
			file_name = dir.get_next()
	return games

func select_game(game_path : String):
	selected_game = game_path
	var is_game_selected = selected_game != ""
	if is_game_selected:
		last_selected_game = selected_game
	launch_game_button.disabled = !is_game_selected
	game_settings_button.disabled = !is_game_selected

# Copies game at file_path to save location.
# If the file already exists at the location, the user may be prompted to choose
# To replace the file or not, depending on their settings.
func import_game(file_path:String):
	if file_path.get_extension() != "pck":
		print_debug("Invalid file type")
		return
	if dir.file_exists(save_location + file_path.get_file()):
		if Settings.data.action_on_replace == Settings.ACTION_ON_REPLACE.DoNotReplace:
			return
		if Settings.data.action_on_replace == Settings.ACTION_ON_REPLACE.Ask:
			var popup = ConfirmationDialog.new()
			add_child(popup)
			popup.dialog_text = file_path.get_file() + " already exists, replace?"
			popup.get_cancel().text = "No"
			popup.get_ok().text = "Yes"
			popup.popup_centered_minsize()
			popup.connect("confirmed", self, "save_game", [file_path])
			yield(popup, "hide")
			popup.queue_free()
			return
	save_game(file_path)

func import_games(file_paths:PoolStringArray):
	for file_path in file_paths:
		import_game(file_path.replace("\\", "/"))

func import_games_from_drop(file_paths:PoolStringArray, _screen:int):
	import_games(file_paths)

func save_game(file_path:String):
	var game_file_name = file_path.get_file()
	Directory.new().copy(file_path, save_location + game_file_name)
	if not game_file_name in Settings.data.games.keys():
		Settings.add_game(game_file_name)
		Settings.save_settings()
		add_button(game_file_name)

func open_game(file_path:String):
	if file_path.get_extension() != "pck":
		print_debug("Invalid file type")
		return
	
	var game_file_name = file_path.get_file()
	
	var game_engine_version = Settings.data.games[game_file_name].godot_version
	print(game_engine_version)
	if not game_engine_version in Settings.get_installed_engines():
		_on_GameSettings_pressed()
		return
	
	var engine_path := OS.get_executable_path()
	if game_engine_version != Settings.launcher_godot_version:
		engine_path = Settings.engine_save_location + game_engine_version + ".exe"
	OS.execute(engine_path, ["--main-pack", file_path.get_file(),
			"--path", file_path.get_base_dir()],false)
	match int(Settings.data.action_on_launch):
		Settings.ACTION_ON_LAUNCH.None:
			pass
		Settings.ACTION_ON_LAUNCH.Minimise:
			# for some reason immediately minimising causes the selected button
			# to register another input click and therefore launch the game again,
			# so we yield one frame here
			yield(get_tree(), "idle_frame")
			OS.window_minimized = true
		Settings.ACTION_ON_LAUNCH.Close:
			get_tree().quit()

func open_games(file_paths:PoolStringArray):
	for file_path in file_paths:
		open_game(file_path.replace("\\", "/"))

func _on_Settings_pressed():
	hide()
	settings_menu.show()

func _on_GameSettings_pressed():
	game_settings_menu.game_file = last_selected_game
	hide()
	game_settings_menu.show()

func _on_OpenFolder_pressed():
	OS.shell_open("file://" + save_location)
