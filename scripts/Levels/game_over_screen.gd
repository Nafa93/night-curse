class_name GameOverScreen
extends CanvasLayer

signal continue_selected
signal quit_selected

@export var fade_in_time := 0.6

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
	for child in get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate.a = 0.0
	visible = true
	var tween := create_tween().set_parallel(true)
	for child in get_children():
		if child is CanvasItem:
			tween.tween_property(child, "modulate:a", 1.0, fade_in_time)


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
