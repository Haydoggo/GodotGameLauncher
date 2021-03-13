extends Control

var save_location = OS.get_user_data_dir()+"/SavedGames/"

export var games_list_path:NodePath
export var empty_label_path:NodePath

func _ready():
	var dirManager = Directory.new()
	if not dirManager.dir_exists(save_location):
		dirManager.make_dir_recursive(save_location)	
	get_tree().get_root().set_transparent_background(true)
	
	# warning-ignore:return_value_discarded
	get_tree().connect("files_dropped", self, "import_games_from_drop")
	import_games(OS.get_cmdline_args())
	refresh_games_list()

func refresh_games_list():
	var gamesList = get_node(games_list_path)
	for link in gamesList.get_children():
		link.free()
	var dir = Directory.new()
	if dir.open(save_location) == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			print("Found file: " + file_name)
			var link = Button.new()
			link.rect_scale.y = 2
			gamesList.add_child(link)
			link.text = file_name
			link.connect("pressed", self, "open_game", [dir.get_current_dir() + "/" + file_name])
			
			file_name = dir.get_next()
	var emptyLabel = get_node(empty_label_path)
	emptyLabel.visible = (gamesList.get_child_count() == 0)


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
