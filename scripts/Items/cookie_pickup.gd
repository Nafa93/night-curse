extends Area2D

@export var collectible_id := ""
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
		monitoring = false
		queue_free()

func _resolve_collectible_id() -> String:
	if not collectible_id.is_empty():
		return collectible_id

	var scene_path := get_tree().current_scene.scene_file_path
	return "%s:%s" % [scene_path, get_path()]
