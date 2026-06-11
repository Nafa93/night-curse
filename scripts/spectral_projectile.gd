extends Area2D

@export var speed := 260.0
@export var lifetime := 1.2

var direction := 1.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func setup(new_direction: float) -> void:
	direction = sign(new_direction)
	if direction == 0.0:
		direction = 1.0
	scale.x = direction

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_hit"):
		area.take_hit()
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()
	queue_free()
