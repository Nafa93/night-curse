extends Control

const LEVEL_SCENE := "res://scenes/Levels/FirstLevel.tscn"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		get_tree().change_scene_to_file(LEVEL_SCENE)
	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/Levels/MainMenu.tscn")
