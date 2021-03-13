extends Control

var save_location = OS.get_user_data_dir()+"/SavedGames/"
var current_version = "v0.2"
var updating = false
var update_file_size := 0

onready var req = $HTTPRequest
onready var games_list = $MarginContainer/VBoxContainer/Control/VBoxContainer/MarginContainer2/ScrollContainer/GamesList
onready var title_label = $MarginContainer/VBoxContainer/Title
onready var update_launcher_button = $MarginContainer/VBoxContainer/UpdateLauncher
onready var emptyLabel = $MarginContainer/VBoxContainer/Control/EmptyLabel
onready var download_label = $MarginContainer/VBoxContainer/DownloadLabel
onready var progress_bar = $MarginContainer/VBoxContainer/ProgressBar

func _ready():
	
	var dirManager = Directory.new()
	title_label.text += " " + current_version
	for arg in OS.get_cmdline_args():
		if arg == "updated":
			var exec_path = OS.get_executable_path()
			var exec_fname = exec_path.get_file()
			dirManager.open(exec_path.get_base_dir())
			dirManager.remove(exec_path.get_file().split(".tmp")[0] + ".exe")
			dirManager.rename(exec_path.get_file(), exec_path.get_file().split(".tmp")[0] + ".exe")
		
		elif arg.replace("\\", "/").is_abs_path():
			import_game(arg.replace("\\", "/"))
		
	if not dirManager.dir_exists(save_location):
		dirManager.make_dir_recursive(save_location)
	
	# warning-ignore:return_value_discarded
	get_tree().connect("files_dropped", self, "import_games_from_drop")
	refresh_games_list()
	
	req.connect("request_completed", self, "version_request_completed")
	req.request("https://github.com/Haydoggo/GodotGameLauncher/releases/latest")
	

func version_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	req.disconnect("request_completed", self, "version_request_completed")
	if response_code == HTTPClient.RESPONSE_OK:
		var s := body.get_string_from_utf8()
		var tag_token = "tag/"
		var version_num_start = s.find(tag_token) + tag_token.length()
		var version_num_end = s.find("\"", version_num_start)
		var latest_version = s.substr(version_num_start, version_num_end - version_num_start)
		if latest_version != current_version:
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
	# Download update to Launcher.tmp
	req.download_file = exec_path.split(".exe")[0] + ".tmp"
	req.request(download_url)
	progress_bar.visible = true
	download_label.visible = true
	updating = true
	update_launcher_button.text = "Downloading %s" % version
	
	# Wait until file size is downloaded
	yield(req, "request_completed")
	OS.execute(req.download_file, ["updated"], false)
	get_tree().quit()
	
func update_request_complete(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
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
			print("Found file: " + file_name)
			var link = Button.new()
			link.rect_scale.y = 2
			games_list.add_child(link)
			link.text = file_name
			link.connect("pressed", self, "open_game", [dir.get_current_dir() + "/" + file_name])
			
			file_name = dir.get_next()
	emptyLabel.visible = (games_list.get_child_count() == 0)

func _process(delta):
	if updating:
		download_label.text = "%dkB of %dkB downloaded" % [req.get_downloaded_bytes()/1024, update_file_size/1024]
		progress_bar.value = req.get_downloaded_bytes()/float(update_file_size) * 100.0

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
	print(filePath)
	if filePath.get_extension() != "pck":
		print("Invalid file type")
	else:
		var path = filePath.substr(0,filePath.find_last("/"))
		var fileName = filePath.substr(filePath.find_last("/")+1, -1)
		print("path: " + path)
		print("fileName: " + fileName)
		# warning-ignore:return_value_discarded
		OS.execute(OS.get_executable_path(),["--main-pack", fileName, "--path", path],false)


func open_games(filePaths:PoolStringArray):
	for filePath in filePaths:
		open_game(filePath.replace("\\", "/"))


func import_games_from_drop(filePaths:PoolStringArray, _fromMonitor:int):
	import_games(filePaths)
	
func open_games_folder():
	OS.shell_open(save_location)
