extends Area2D

@export var heal_amount := 1
@export var full_heal := false
@export var lifetime := 0.0
@export var bob_height := 2.0
@export var bob_speed := 3.0

@onready var visual: Sprite2D = $Sprite2D

var elapsed_time := 0.0
var visual_start_y := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visual_start_y = visual.position.y
	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	elapsed_time += delta
	visual.position.y = visual_start_y + sin(elapsed_time * bob_speed) * bob_height

func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("heal"):
		return

	var amount: int = 999 if full_heal else heal_amount
	var was_healed: bool = body.heal(amount)
	if was_healed:
		queue_free()
