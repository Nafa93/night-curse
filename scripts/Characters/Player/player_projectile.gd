extends Area2D

@export var speed := 220.0
@export var lifetime := 1.5

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var direction := 1.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(queue_free)
	visual.play(&"travel")
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func setup(new_direction: float) -> void:
	direction = signf(new_direction)
	if direction == 0.0:
		direction = 1.0
	visual.flip_h = direction < 0.0

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("projectile"):
		area.call_deferred("queue_free")
		call_deferred("queue_free")
		return

	if screen_notifier.is_on_screen() and area.has_method("take_hit"):
		area.take_hit()
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if screen_notifier.is_on_screen() and body.has_method("take_hit"):
		body.take_hit()
	queue_free()
