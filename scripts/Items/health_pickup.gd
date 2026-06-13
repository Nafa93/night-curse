extends Area2D

@export var heal_amount := 1
@export var full_heal := false
@export var score_value := 50
@export var lifetime := 0.0
@export var bob_height := 2.0
@export var bob_speed := 3.0

@onready var visual: Sprite2D = $Sprite2D

var elapsed_time := 0.0
var visual_start_y := 0.0
var is_collected := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visual_start_y = visual.position.y
	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	elapsed_time += delta
	visual.position.y = visual_start_y + sin(elapsed_time * bob_speed) * bob_height

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body.has_method("heal"):
		return

	is_collected = true
	set_deferred("monitoring", false)
	var amount: int = 999 if full_heal else heal_amount
	body.heal(amount)
	_award_points()
	queue_free()

func _award_points() -> void:
	var level := get_tree().current_scene
	if level.has_method("award_points"):
		level.award_points(score_value, global_position)
	elif level.has_method("add_points"):
		level.add_points(score_value)
