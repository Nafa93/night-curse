class_name TheEndScreen
extends CanvasLayer

signal finished

@export var fade_in_time := 1.2
@export var prompt_delay := 1.5
@export var prompt_blink_speed := 0.55

@onready var press_start_label: Label = $PressStartLabel

var _accepting_input := false

func show_screen() -> void:
	for child in get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate.a = 0.0
	press_start_label.visible = false
	visible = true
	var tween := create_tween().set_parallel(true)
	for child in get_children():
		if child is CanvasItem:
			tween.tween_property(child, "modulate:a", 1.0, fade_in_time)
	await tween.finished
	await get_tree().create_timer(prompt_delay).timeout
	press_start_label.visible = true
	_accepting_input = true
	_blink_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not _accepting_input or not visible:
		return
	if event.is_action_pressed("start") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		finished.emit()

func _blink_prompt() -> void:
	while _accepting_input:
		press_start_label.visible = not press_start_label.visible
		await get_tree().create_timer(prompt_blink_speed).timeout
