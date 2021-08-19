extends Button

signal open_game()

var game_name = "" setget _set_game_name

func _set_game_name(v):
	game_name = v
	text = game_name

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed\
				and is_hovered() and event.doubleclick:
			emit_signal("open_game")
