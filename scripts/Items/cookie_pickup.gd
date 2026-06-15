extends "res://scripts/Items/gravity_pickup.gd"

@export var collectible_id := ""
@export var score_value := 500
@export var bob_height := 2.0
@export var bob_speed := 3.0

@onready var visual: Sprite2D = $Sprite2D

var _elapsed_time := 0.0
var _visual_start_y := 0.0
var _resolved_id := ""
var _collected := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_visual_start_y = visual.position.y
	_resolved_id = _resolve_collectible_id()

	if CollectibleTracker.register_cookie(_resolved_id):
		queue_free()

func _process(delta: float) -> void:
	_elapsed_time += delta
	visual.position.y = _visual_start_y + sin(_elapsed_time * bob_speed) * bob_height

func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.has_method("heal"):
		return

	if CollectibleTracker.collect_cookie(_resolved_id):
		_collected = true
		set_deferred("monitoring", false)
		SoundManager.play_pickup()
		_award_points()
		queue_free()

func _resolve_collectible_id() -> String:
	var scene_path := get_tree().current_scene.scene_file_path
	var position_key := "%d,%d" % [
		roundi(global_position.x),
		roundi(global_position.y)
	]

	if not collectible_id.is_empty():
		return "%s:%s:%s" % [scene_path, collectible_id, position_key]

	return "%s:%s" % [scene_path, position_key]

func _award_points() -> void:
	var level := get_tree().current_scene
	if level.has_method("award_points"):
		level.award_points(score_value, global_position)
	elif level.has_method("add_points"):
		level.add_points(score_value)
