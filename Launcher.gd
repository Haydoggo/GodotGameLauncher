extends Control

var save_location = OS.get_user_data_dir()+"/SavedGames/"
var current_version = "v0.4"
var updating = false
var update_file_size := 0.0

onready var req = $HTTPRequest
onready var games_list = $MarginContainer/VBoxContainer/Control/VBoxContainer/MarginContainer2/ScrollContainer/GamesList
onready var title_label = $MarginContainer/VBoxContainer/Title
onready var update_launcher_button = $MarginContainer/VBoxContainer/UpdateLauncher
onready var emptyLabel = $MarginContainer/VBoxContainer/Control/EmptyLabel
onready var download_label = $MarginContainer/VBoxContainer/DownloadLabel
onready var progress_bar = $MarginContainer/VBoxContainer/ProgressBar

func _ready():
	var dirManager = Directory.new()
	if not dirManager.dir_exists(save_location):
		dirManager.make_dir(save_location)
	
	title_label.text += " " + current_version

	# Handle extra arguments
	for arg in OS.get_cmdline_args():
		# If the launcher has been opened as the result of an update. 
		# Proceed to delete and replace the old launcher.
		if arg == "updated":
			var exec_path = OS.get_executable_path()
			var exec_fname = exec_path.get_file()
			dirManager.open(exec_path.get_base_dir())
			dirManager.remove(exec_fname.split(".tmp")[0] + ".exe")
			dirManager.rename(exec_fname, exec_path.get_file().split(".tmp")[0] + ".exe")
		
		# If any of the arguments are paths, it will be from the user opening 
		# opening a game file with the exe. Attempt to open these as games.
		elif arg.replace("\\", "/").is_abs_path():
			var path = arg
			open_game(path)
			get_tree().quit()
			Directory
	
	self.get_tree().connect("files_dropped", self, "import_games_from_drop")
	refresh_games_list()
	
	# Check for new launcher version
	if not OS.is_debug_build() or true:
		req.connect("request_completed", self, "version_request_completed")
		req.request("https://github.com/Haydoggo/GodotGameLauncher/releases/latest")

func _process(_delta):
	if updating:
		download_label.text = "%skB of %skB downloaded" %\
				 [add_commas(req.get_downloaded_bytes()/1024),
				  add_commas(update_file_size/1024)]
		progress_bar.value = req.get_downloaded_bytes()/float(update_file_size) * 100.0

func version_request_completed(_result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray):
	req.disconnect("request_completed", self, "version_request_completed")
	
	# Search body for latest version number
	if response_code == HTTPClient.RESPONSE_OK:
		var s := body.get_string_from_utf8()
		var tag_token = "tag/"
		var version_num_start = s.find(tag_token) + tag_token.length()
		var version_num_end = s.find("\"", version_num_start)
		var latest_version = s.substr(version_num_start, version_num_end - version_num_start)
		update_launcher_button.text += " (%s available)" %  latest_version
		if current_version != latest_version:
			update_launcher_button.visible = true
			update_launcher_button.connect("pressed", self, "update_launcher", [latest_version])

func update_launcher(version : String):
	var exec_path = OS.get_executable_path()
	req.connect("request_completed", self, "update_request_complete")
	var download_url = "https://github.com/Haydoggo/GodotGameLauncher/releases/download/%s/Launcher.exe"%version
	req.request(download_url, [], true, HTTPClient.METHOD_HEAD)
	update_launcher_button.disabled = true
	update_launcher_button.text = "Fetching File Size"
	
	# Wait until file size is fetched
	yield(req, "request_completed")
	# Download update as .tmp
	req.download_file = exec_path.split(".exe")[0] + ".tmp"
	req.request(download_url)
	progress_bar.visible = true
	download_label.visible = true
	updating = true
	update_launcher_button.text = "Downloading %s" % version
	
	# Wait until file size is downloaded
	yield(req, "request_completed")
	if not OS.is_debug_build():
		var _pid = OS.execute(req.download_file, ["updated"], false)
		get_tree().quit()
	
func update_request_complete(_result: int, _response_code: int, headers: PoolStringArray, _body: PoolByteArray):
	req.disconnect("request_completed", self, "update_request_complete")
	for header in headers:
		if header.begins_with("Content-Length"):
			update_file_size = int(header.split(": ")[1])
			break

func refresh_games_list():
	for link in games_list.get_children():
		link.free()
	var dir = Directory.new()
	if dir.open(save_location) == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			var link = Button.new()
			link.rect_scale.y = 2
			games_list.add_child(link)
			link.text = file_name
			link.connect("pressed", self, "open_game", [dir.get_current_dir() + "/" + file_name])
			
			file_name = dir.get_next()
	emptyLabel.visible = (games_list.get_child_count() == 0)

func _on_ImportGame_pressed():
	var fileDiag = FileDialog.new()
	add_child(fileDiag)
	fileDiag.add_filter("*.pck; Godot game packages")
	fileDiag.mode_overrides_title = false
	fileDiag.window_title = "Pick a game"
	fileDiag.mode = FileDialog.MODE_OPEN_FILE
	fileDiag.access = FileDialog.ACCESS_FILESYSTEM
	fileDiag.popup_centered_ratio()
	fileDiag.connect("file_selected", self, "import_game")
	fileDiag.connect("files_selected", self, "import_game")

func _on_LoadGame_pressed():
	var fileDiag = FileDialog.new()
	add_child(fileDiag)
	fileDiag.add_filter("*.pck; Godot game packages")
	fileDiag.mode_overrides_title = false
	fileDiag.window_title = "Pick a game"
	fileDiag.access = FileDialog.ACCESS_FILESYSTEM
	fileDiag.mode = FileDialog.MODE_OPEN_FILES
	fileDiag.connect("file_selected", self, "open_game")
	fileDiag.connect("files_selected", self, "open_games")
	fileDiag.current_dir = save_location
	fileDiag.popup_centered_ratio()

func import_game(filePath:String):
	if filePath.get_extension() != "pck":
		print_debug("Invalid file type")
		return
	print("importing game")
	var fileName = filePath.substr(filePath.find_last("/")+1, -1)
	var dirMngr = Directory.new()
	print(save_location + fileName)
	if dirMngr.file_exists(save_location + fileName):
		var popup = ConfirmationDialog.new()
		add_child(popup)
		popup.dialog_text = fileName + " already exists, replace?"
		popup.popup_centered_minsize()
		popup.connect("confirmed", self, "save_game", [filePath])
		print("file exists")
	else:
		save_game(filePath)

func import_games(filePaths:PoolStringArray):
	for filePath in filePaths:
		import_game(filePath.replace("\\", "/"))

func save_game(filePath:String):
	var fileName = filePath.substr(filePath.find_last("/")+1, -1)
	var tempFile = File.new()
	tempFile.open(save_location + fileName, File.WRITE)
	tempFile.close()
	# warning-ignore:return_value_discarded
	Directory.new().copy(filePath, save_location + fileName)
	refresh_games_list()

func open_game(filePath:String):
	if filePath.get_extension() != "pck":
		print_debug("Invalid file type")
	else:
		var path = filePath.substr(0,filePath.find_last("/"))
		var fileName = filePath.substr(filePath.find_last("/")+1, -1)
		print("path: " + path)
		print("fileName: " + fileName)
		var _pid = OS.execute(OS.get_executable_path(),["--main-pack", fileName, "--path", path],false)

func open_games(filePaths:PoolStringArray):
	for filePath in filePaths:
		open_game(filePath.replace("\\", "/"))

func import_games_from_drop(filePaths:PoolStringArray, _fromMonitor:int):
	import_games(filePaths)
	
func open_games_folder():
	var _err = OS.shell_open(save_location)

# https://www.croben.com/2020/10/add-commas-on-floats-or-ints-in-gdscript.html
func add_commas(value: int) -> String:
	# Convert value to string.
	var str_value: String = str(value)
	
	# Check if the value is positive or negative.
	# Use index 0(excluded) if positive to avoid comma before the 1st digit.
	# Use index 1(excluded) if negative to avoid comma after the - sign.
	var loop_end: int = 0 if value > -1 else 1
	
	# Loop backward starting at the last 3 digits,
	# add comma then, repeat every 3rd step.
	for i in range(str_value.length()-3, loop_end, -3):
		str_value = str_value.insert(i, ",")
	
	# Return the formatted string.
	return str_value
