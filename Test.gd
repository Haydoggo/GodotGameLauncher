extends Node

onready var thread := Thread.new()
signal finished()

func _process(delta):
	$Polygon2D.rotate(delta * TAU)

func _ready():
	thread.start(self, "get_version_number", thread)
	yield(get_tree().create_timer(1),"timeout")
	print(thread.is_active())

func get_version_number(thread):
	var out = []
	OS.execute("curl", ["-g", "https://github.com/Haydoggo/GodotGameLauncher/releases/latest"], true, out)
	var s : String = out[0]
	var b = s.find_last("/tag/")+"/tag/".length()
	var e = s.find_last("\">redirected")
	var version = s.substr(b, e-b)
	$Label.text = version
	thread.call_deferred("wait_to_finish")
