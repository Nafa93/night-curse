extends CharacterBody2D

const SMALL_HEART_PICKUP := preload("res://scenes/Items/SmallHeartPickup.tscn")

@export var projectile_scene: PackedScene
@export var speed := 28.0
@export var patrol_distance := 100.0
@export var starts_moving_right := false
@export var gravity := 980.0
@export var health := 3
@export var score_value := 300
@export var shoot_cooldown := 1.5
@export_range(0.0, 1.0, 0.01) var heart_drop_chance := 0.2
@export var active_in_corporeal_world := true
@export var active_in_spectral_world := false

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var damage_area: Area2D = $DamageArea
@onready var detection_area: Area2D = $DetectionArea
@onready var muzzle: Marker2D = $Muzzle
@onready var activation_notifier: VisibleOnScreenNotifier2D = $ActivationNotifier

var start_x := 0.0
var direction := -1.0
var is_active := false
var is_world_enabled := true
var is_near_screen := false
var shoot_time_remaining := 0.0
var tracked_target: CharacterBody2D
var base_collision_layer := 8

func _ready() -> void:
	start_x = global_position.x
	direction = 1.0 if starts_moving_right else -1.0
	base_collision_layer = collision_layer
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	activation_notifier.screen_entered.connect(_on_screen_entered)
	activation_notifier.screen_exited.connect(_on_screen_exited)
	add_to_group("day_night_reactive")
	visual.play(&"walk")
	_update_direction()
	_update_checks()
	refresh_activation_state()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	shoot_time_remaining = maxf(shoot_time_remaining - delta, 0.0)
	if is_instance_valid(tracked_target):
		_face_target()
		velocity.x = 0.0
		if shoot_time_remaining <= 0.0:
			_shoot()
	else:
		velocity.x = direction * speed

	move_and_slide()

	if is_instance_valid(tracked_target):
		return

	if (
		is_on_wall()
		or (is_on_floor() and not floor_check.is_colliding())
		or abs(global_position.x - start_x) >= patrol_distance
	):
		_turn_around()

func set_day_state(is_corporeal: bool) -> void:
	is_world_enabled = active_in_corporeal_world if is_corporeal else active_in_spectral_world
	visible = is_world_enabled
	refresh_activation_state()

func refresh_activation_state() -> void:
	is_active = is_world_enabled and is_near_screen and is_visible_in_tree()
	set_physics_process(is_active)
	set_deferred("collision_layer", base_collision_layer if is_active else 0)
	damage_area.set_deferred("monitoring", is_active)
	detection_area.set_deferred("monitoring", is_active)
	if not is_active:
		velocity = Vector2.ZERO
		tracked_target = null

func take_hit() -> void:
	health -= 1
	if health > 0:
		return

	var level := get_tree().current_scene
	if level.has_method("award_points"):
		level.award_points(score_value, global_position)
	elif level.has_method("add_points"):
		level.add_points(score_value)
	_try_drop_heart()
	queue_free()

func _shoot() -> void:
	if projectile_scene == null:
		return

	shoot_time_remaining = shoot_cooldown
	var projectile := projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.setup(direction)

func _face_target() -> void:
	var target_direction := signf(tracked_target.global_position.x - global_position.x)
	if target_direction != 0.0 and target_direction != direction:
		direction = target_direction
		_update_direction()
		_update_checks()

func _turn_around() -> void:
	direction *= -1.0
	start_x = global_position.x
	_update_direction()
	_update_checks()

func _update_direction() -> void:
	visual.flip_h = direction > 0.0
	muzzle.position.x = 24.0 * direction

func _update_checks() -> void:
	floor_check.position.x = 17.0 * direction
	wall_check.target_position = Vector2(24.0 * direction, 0.0)

func _try_drop_heart() -> void:
	if randf() > heart_drop_chance:
		return

	var level := get_tree().current_scene as Node2D
	var pickup: Area2D = SMALL_HEART_PICKUP.instantiate()
	pickup.position = level.to_local(global_position)
	level.call_deferred("add_child", pickup)

func _on_detection_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("take_damage"):
		tracked_target = body as CharacterBody2D

func _on_detection_body_exited(body: Node2D) -> void:
	if body == tracked_target:
		tracked_target = null

func _on_damage_area_body_entered(body: Node2D) -> void:
	if is_active and body.has_method("take_damage"):
		body.take_damage(global_position)

func _on_screen_entered() -> void:
	is_near_screen = true
	refresh_activation_state()

func _on_screen_exited() -> void:
	is_near_screen = false
	refresh_activation_state()
