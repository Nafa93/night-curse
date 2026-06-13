extends Control

const CONTROLS_SCENE := "res://scenes/Levels/ControlsScreen.tscn"

@onready var options: Array[Label] = [
	$Menu/StartLabel,
	$Menu/QuitLabel,
]

var selected_option := 0

func _ready() -> void:
	_update_selection()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		selected_option = wrapi(selected_option - 1, 0, options.size())
		_update_selection()
	elif event.is_action_pressed("ui_down"):
		selected_option = wrapi(selected_option + 1, 0, options.size())
		_update_selection()
	elif event.is_action_pressed("start"):
		if selected_option == 0:
			get_tree().change_scene_to_file(CONTROLS_SCENE)
		else:
			get_tree().quit()

func _update_selection() -> void:
	for index in options.size():
		options[index].text = ("> " if index == selected_option else "  ") + options[index].name.trim_suffix("Label").to_upper()
