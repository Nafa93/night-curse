extends CharacterBody2D

const SMALL_HEART_PICKUP := preload("res://scenes/Items/SmallHeartPickup.tscn")

@export var speed := 30.0
@export var patrol_distance := 112.0
@export var starts_moving_right := false
@export var gravity := 980.0
@export var health := 3
@export var score_value := 400
@export var hit_flash_time := 0.12
@export var attack_cooldown := 1.1
@export var attack_vertical_tolerance := 32.0
@export_range(0.0, 1.0, 0.01) var heart_drop_chance := 0.2
@export var active_in_corporeal_world := true
@export var active_in_spectral_world := false

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_visual: AnimatedSprite2D = $AttackVisual
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var damage_area: Area2D = $DamageArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea

var start_x := 0.0
var direction := -1.0
var is_active := true
var is_taking_hit := false
var is_attacking := false
var attack_time_remaining := 0.0
var tracked_target: CharacterBody2D
var hit_target_this_attack := false
var base_collision_layer := 8

func _ready() -> void:
	start_x = global_position.x
	direction = 1.0 if starts_moving_right else -1.0
	base_collision_layer = collision_layer
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	attack_visual.frame_changed.connect(_on_attack_frame_changed)
	attack_visual.animation_finished.connect(_on_attack_finished)
	add_to_group("day_night_reactive")
	_set_attack_enabled(false)
	attack_visual.visible = false
	visual.play(&"walk")
	_update_direction()
	_update_checks()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	attack_time_remaining = maxf(attack_time_remaining - delta, 0.0)

	if not is_attacking and not is_taking_hit and _can_attack_target():
		_start_attack()

	velocity.x = 0.0 if is_taking_hit or is_attacking else direction * speed
	move_and_slide()

	if is_taking_hit or is_attacking:
		return

	if (
		is_on_wall()
		or (is_on_floor() and not floor_check.is_colliding())
		or abs(global_position.x - start_x) >= patrol_distance
	):
		_turn_around()

func set_day_state(is_corporeal: bool) -> void:
	is_active = active_in_corporeal_world if is_corporeal else active_in_spectral_world
	collision_layer = base_collision_layer if is_active else 0
	damage_area.set_deferred("monitoring", is_active)
	detection_area.set_deferred("monitoring", is_active)
	attack_area.set_deferred("monitoring", false)
	attack_shape.set_deferred("disabled", true)
	visible = is_active

func take_hit() -> void:
	if is_taking_hit or health <= 0:
		return

	health -= 1
	if health <= 0:
		_award_points()
		_try_drop_heart()
		queue_free()
		return

	_flash_hit()

func _flash_hit() -> void:
	is_taking_hit = true
	visual.modulate = Color(1.0, 1.0, 1.0, 0.25)
	attack_visual.modulate = visual.modulate
	await get_tree().create_timer(hit_flash_time).timeout
	visual.modulate = Color.WHITE
	attack_visual.modulate = Color.WHITE
	is_taking_hit = false

func _turn_around() -> void:
	direction *= -1.0
	start_x = global_position.x
	_update_direction()
	_update_checks()

func _update_direction() -> void:
	visual.flip_h = direction > 0.0
	attack_visual.flip_h = direction > 0.0
	attack_area.position.x = 16.0 * direction

func _update_checks() -> void:
	floor_check.position.x = 12.0 * direction
	wall_check.target_position = Vector2(18.0 * direction, 0.0)

func _can_attack_target() -> bool:
	return (
		attack_time_remaining <= 0.0
		and is_instance_valid(tracked_target)
		and abs(tracked_target.global_position.y - global_position.y) <= attack_vertical_tolerance
	)

func _start_attack() -> void:
	var target_direction: float = signf(tracked_target.global_position.x - global_position.x)
	if target_direction != 0.0:
		direction = target_direction
	_update_direction()

	is_attacking = true
	hit_target_this_attack = false
	velocity.x = 0.0
	visual.pause()
	attack_visual.visible = true
	attack_visual.play(&"attack")
	_on_attack_frame_changed()

func _on_attack_frame_changed() -> void:
	if not is_attacking:
		return

	_set_attack_enabled(attack_visual.frame >= 2)

func _on_attack_finished() -> void:
	if not is_attacking:
		return

	is_attacking = false
	attack_time_remaining = attack_cooldown
	attack_visual.visible = false
	_set_attack_enabled(false)
	visual.play(&"walk")

func _set_attack_enabled(is_enabled: bool) -> void:
	attack_area.set_deferred("monitoring", is_enabled)
	attack_shape.set_deferred("disabled", not is_enabled)

func _on_detection_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("take_damage"):
		tracked_target = body as CharacterBody2D

func _on_detection_body_exited(body: Node2D) -> void:
	if body == tracked_target:
		tracked_target = null

func _on_attack_area_body_entered(body: Node2D) -> void:
	if hit_target_this_attack or not body.has_method("take_damage"):
		return

	hit_target_this_attack = true
	body.take_damage(global_position)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if is_active and body.has_method("take_damage"):
		body.take_damage(global_position)

func _award_points() -> void:
	var level := get_tree().current_scene
	if level.has_method("award_points"):
		level.award_points(score_value, global_position)
	elif level.has_method("add_points"):
		level.add_points(score_value)

func _try_drop_heart() -> void:
	if randf() > heart_drop_chance:
		return

	var pickup: Area2D = SMALL_HEART_PICKUP.instantiate()
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position
