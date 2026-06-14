class_name GameOverScreen
extends CanvasLayer

signal continue_selected
signal quit_selected

@onready var options: Array[Label] = [
	$Menu/YesLabel,
	$Menu/NoLabel,
]

var selected_option := 0


func _ready() -> void:
	_update_selection()


func show_menu() -> void:
	selected_option = 0
	_update_selection()
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_up"):
		selected_option = wrapi(selected_option - 1, 0, options.size())
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		selected_option = wrapi(selected_option + 1, 0, options.size())
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("start"):
		get_viewport().set_input_as_handled()
		if selected_option == 0:
			continue_selected.emit()
		else:
			quit_selected.emit()


func _update_selection() -> void:
	for index in options.size():
		var option_name := options[index].name.trim_suffix("Label").to_upper()
		options[index].text = ("> " if index == selected_option else "  ") + option_name
