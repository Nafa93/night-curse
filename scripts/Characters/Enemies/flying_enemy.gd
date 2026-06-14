extends CharacterBody2D

const SMALL_HEART_PICKUP := preload("res://scenes/Items/SmallHeartPickup.tscn")

enum MovementMode {
	PATROL,
	FLY_THROUGH,
}

@export var movement_mode := MovementMode.PATROL
@export var speed := 55.0
@export var patrol_distance := 140.0
@export var oscillation_amplitude := 48.0
@export var wave_length := 240.0
@export var starts_moving_right := true
@export var health := 1
@export var score_value := 200
@export_range(0.0, 1.0, 0.01) var heart_drop_chance := 0.15
@export var active_in_corporeal_world := true
@export var active_in_spectral_world := true

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var activation_notifier: VisibleOnScreenNotifier2D = $ActivationNotifier

var start_position := Vector2.ZERO
var direction := 1.0
var is_active := false
var is_world_enabled := true
var is_near_screen := false
var base_collision_layer := 8
var entered_screen := false

func _ready() -> void:
	start_position = global_position
	direction = 1.0 if starts_moving_right else -1.0
	base_collision_layer = collision_layer
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	activation_notifier.screen_entered.connect(_on_screen_entered)
	activation_notifier.screen_exited.connect(_on_screen_exited)
	add_to_group("day_night_reactive")
	visual.play("fly")
	_update_visual_direction()
	refresh_activation_state()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	velocity = Vector2(direction * speed, 0.0)
	move_and_slide()
	var horizontal_distance: float = abs(global_position.x - start_position.x)
	var safe_wave_length: float = max(wave_length, 1.0)
	global_position.y = start_position.y + sin(horizontal_distance / safe_wave_length * TAU) * oscillation_amplitude

	if movement_mode == MovementMode.PATROL and abs(global_position.x - start_position.x) >= patrol_distance:
		global_position.x = start_position.x + patrol_distance * sign(global_position.x - start_position.x)
		direction *= -1.0
		_update_visual_direction()

func set_day_state(is_corporeal: bool) -> void:
	is_world_enabled = active_in_corporeal_world if is_corporeal else active_in_spectral_world
	visible = is_world_enabled
	refresh_activation_state()

func refresh_activation_state() -> void:
	is_active = is_world_enabled and is_near_screen and is_visible_in_tree()
	set_physics_process(is_active)
	set_deferred("collision_layer", base_collision_layer if is_active else 0)
	damage_area.set_deferred("monitoring", is_active)
	if not is_active:
		velocity = Vector2.ZERO

func take_hit() -> void:
	health -= 1
	if health <= 0:
		var level := get_tree().current_scene
		if level.has_method("award_points"):
			level.award_points(score_value, global_position)
		elif level.has_method("add_points"):
			level.add_points(score_value)
		_try_drop_heart()
		queue_free()

func _try_drop_heart() -> void:
	if randf() > heart_drop_chance:
		return

	var level := get_tree().current_scene as Node2D
	var pickup: Area2D = SMALL_HEART_PICKUP.instantiate()
	pickup.position = level.to_local(global_position)
	level.call_deferred("add_child", pickup)

func _update_visual_direction() -> void:
	visual.flip_h = direction > 0.0

func _on_damage_area_body_entered(body: Node2D) -> void:
	if is_active and body.has_method("take_damage"):
		body.take_damage(global_position)

func _on_screen_entered() -> void:
	entered_screen = true
	is_near_screen = true
	refresh_activation_state()

func _on_screen_exited() -> void:
	if movement_mode == MovementMode.FLY_THROUGH and entered_screen:
		queue_free()
		return

	is_near_screen = false
	refresh_activation_state()
