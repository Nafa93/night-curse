extends Area2D

@export var score_value := 100
@export var lifetime := 8.0
@export var bob_height := 2.0
@export var bob_speed := 3.0

@onready var visual: Sprite2D = $Sprite2D

var _elapsed_time := 0.0
var _visual_start_y := 0.0
var _collected := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_visual_start_y = visual.position.y
	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	_elapsed_time += delta
	visual.position.y = _visual_start_y + sin(_elapsed_time * bob_speed) * bob_height

func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.has_method("heal"):
		return

	_collected = true
	set_deferred("monitoring", false)
	_award_points()
	queue_free()

func _award_points() -> void:
	var level := get_tree().current_scene
	if level.has_method("award_points"):
		level.award_points(score_value, global_position)
	elif level.has_method("add_points"):
		level.add_points(score_value)
