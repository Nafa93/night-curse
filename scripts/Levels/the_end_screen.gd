class_name TheEndScreen
extends CanvasLayer

@export var fade_in_time := 1.2

func show_screen() -> void:
	for child in get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate.a = 0.0
	visible = true
	var tween := create_tween().set_parallel(true)
	for child in get_children():
		if child is CanvasItem:
			tween.tween_property(child, "modulate:a", 1.0, fade_in_time)
