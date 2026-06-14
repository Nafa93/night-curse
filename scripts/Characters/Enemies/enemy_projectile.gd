extends Area2D

@export var speed := 120.0
@export var lifetime := 3.0

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var direction := 1.0
var entered_screen := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	screen_notifier.screen_entered.connect(_on_screen_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)
	visual.play(&"fly")
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func setup(new_direction: float) -> void:
	direction = signf(new_direction)
	if direction == 0.0:
		direction = 1.0
	visual.flip_h = direction < 0.0

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(global_position)
	queue_free()

func _on_screen_entered() -> void:
	entered_screen = true

func _on_screen_exited() -> void:
	if entered_screen:
		queue_free()
