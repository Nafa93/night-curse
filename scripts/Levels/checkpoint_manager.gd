extends Node

var has_checkpoint := false
var level_scene_path := ""
var door_path := NodePath()
var spawn_position := Vector2.ZERO
var is_otherside := false
var score := 0
var key_count := 0


func save_checkpoint(
	scene_path: String,
	checkpoint_door_path: NodePath,
	checkpoint_position: Vector2,
	checkpoint_is_otherside: bool,
	checkpoint_score: int,
	checkpoint_key_count: int
) -> void:
	has_checkpoint = true
	level_scene_path = scene_path
	door_path = checkpoint_door_path
	spawn_position = checkpoint_position
	is_otherside = checkpoint_is_otherside
	score = checkpoint_score
	key_count = checkpoint_key_count


func has_checkpoint_for(scene_path: String) -> bool:
	return has_checkpoint and level_scene_path == scene_path


func clear() -> void:
	has_checkpoint = false
	level_scene_path = ""
	door_path = NodePath()
	spawn_position = Vector2.ZERO
	is_otherside = false
	score = 0
	key_count = 0
