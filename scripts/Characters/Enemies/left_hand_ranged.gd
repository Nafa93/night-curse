extends CharacterBody2D

const SMALL_HEART_PICKUP := preload("res://scenes/Items/SmallHeartPickup.tscn")
const CANDY_PICKUP := preload("res://scenes/Items/CandyPickup.tscn")

@export var projectile_scene: PackedScene = preload("res://scenes/Characters/Enemies/EnemyProjectile.tscn")
@export var speed := 28.0
@export var patrol_distance := 100.0
@export var starts_moving_right := false
@export var health := 3
@export var hit_flash_time := 0.12
@export var score_value := 500
@export var shoot_cooldown := 1.5
@export var shoot_hold_time := 0.25
@export var oscillation_amplitude := 20.0
@export var oscillation_speed := 1.5
@export_range(0.0, 1.0, 0.01) var heart_drop_chance := 0.2
@export_range(0.0, 1.0, 0.01) var candy_drop_chance := 0.15
@export var autonomous := true
@export var aim_at_player_y := false
@export var redirect_damage_to_parent := false
@export var always_track_player := false
@export var manual_shoot_only := false
@export var active_in_corporeal_world := true
@export var active_in_spectral_world := false

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var detection_area: Area2D = $DetectionArea
@onready var muzzle: Marker2D = $Muzzle
@onready var activation_notifier: VisibleOnScreenNotifier2D = $ActivationNotifier

var start_x := 0.0
var start_y := 0.0
var float_elapsed := 0.0
var direction := -1.0
var facing_direction := -1.0
var is_active := false
var is_world_enabled := true
var is_near_screen := false
var is_taking_hit := false
var is_shooting := false
var shoot_time_remaining := 0.0
var tracked_target: CharacterBody2D
var player_target: CharacterBody2D
var base_collision_layer := 8

func _ready() -> void:
	start_x = global_position.x
	start_y = global_position.y
	direction = 1.0 if starts_moving_right else -1.0
	facing_direction = direction
	base_collision_layer = collision_layer
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	activation_notifier.screen_entered.connect(_on_screen_entered)
	activation_notifier.screen_exited.connect(_on_screen_exited)
	add_to_group("day_night_reactive")
	player_target = _find_player()
	visual.play(&"move")
	_update_facing_direction(direction)
	refresh_activation_state()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	if not is_instance_valid(player_target):
		player_target = _find_player()
	if is_instance_valid(player_target):
		_face_player()

	if always_track_player and is_instance_valid(player_target):
		tracked_target = player_target

	shoot_time_remaining = maxf(shoot_time_remaining - delta, 0.0)
	if is_instance_valid(tracked_target):
		velocity.x = 0.0
		if shoot_time_remaining <= 0.0 and not is_shooting and not manual_shoot_only:
			_shoot()
	elif autonomous:
		velocity.x = direction * speed
		if abs(global_position.x - start_x) >= patrol_distance:
			direction *= -1.0
			start_x = global_position.x
			_update_facing_direction(direction)
	else:
		velocity.x = 0.0

	float_elapsed += delta
	velocity.y = 0.0
	move_and_slide()
	global_position.y = start_y + sin(float_elapsed * oscillation_speed) * oscillation_amplitude

func set_day_state(is_corporeal: bool) -> void:
	is_world_enabled = active_in_corporeal_world if is_corporeal else active_in_spectral_world
	visible = is_world_enabled
	refresh_activation_state()

func refresh_activation_state() -> void:
	is_active = is_world_enabled and is_near_screen and is_visible_in_tree()
	set_physics_process(is_active)
	set_deferred("collision_layer", base_collision_layer if is_active else 0)
	damage_area.set_deferred("monitoring", is_active)
	detection_area.set_deferred("monitoring", is_active and activation_notifier.is_on_screen())
	if not is_active:
		velocity = Vector2.ZERO
		tracked_target = null
		is_shooting = false

func trigger_shoot() -> void:
	if is_active and not is_shooting and is_instance_valid(tracked_target):
		_shoot()

func take_hit() -> void:
	if redirect_damage_to_parent:
		var parent := get_parent()
		if parent and parent.has_method("take_hit"):
			parent.take_hit()
		return

	if is_taking_hit or health <= 0:
		return

	SoundManager.play_impact()
	health -= 1
	if health <= 0:
		var level := get_tree().current_scene
		if level.has_method("award_points"):
			level.award_points(score_value, global_position)
		elif level.has_method("add_points"):
			level.add_points(score_value)
		_try_drop_heart()
		_try_drop_candy()
		queue_free()
		return

	_flash_hit()

func _flash_hit() -> void:
	is_taking_hit = true
	visual.modulate = Color(1.0, 1.0, 1.0, 0.25)
	await get_tree().create_timer(hit_flash_time).timeout
	visual.modulate = Color.WHITE
	is_taking_hit = false

func _shoot() -> void:
	is_shooting = true
	shoot_time_remaining = shoot_cooldown
	visual.play(&"shoot")

	var projectile := projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = muzzle.global_position
	if aim_at_player_y and is_instance_valid(tracked_target):
		var aim_dir := tracked_target.global_position - muzzle.global_position
		projectile.setup_aimed(aim_dir)
	else:
		projectile.setup(facing_direction)

	await get_tree().create_timer(shoot_hold_time).timeout
	if is_instance_valid(self) and not is_queued_for_deletion():
		is_shooting = false
		visual.play(&"move")

func _face_player() -> void:
	var target_direction := signf(player_target.global_position.x - global_position.x)
	if target_direction != 0.0 and target_direction != facing_direction:
		_update_facing_direction(target_direction)

func _find_player() -> CharacterBody2D:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var candidate := scene.find_child("Player", true, false)
	if candidate is CharacterBody2D and candidate.has_method("take_damage"):
		return candidate as CharacterBody2D
	return null

func _update_facing_direction(new_direction: float) -> void:
	facing_direction = new_direction
	visual.flip_h = facing_direction > 0.0
	muzzle.position.x = 16.0 * facing_direction

func _try_drop_heart() -> void:
	if randf() > heart_drop_chance:
		return
	var level := get_tree().current_scene as Node2D
	var pickup: Area2D = SMALL_HEART_PICKUP.instantiate()
	pickup.position = level.to_local(global_position)
	level.call_deferred("add_child", pickup)

func _try_drop_candy() -> void:
	if randf() > candy_drop_chance:
		return
	var level := get_tree().current_scene as Node2D
	var pickup: Area2D = CANDY_PICKUP.instantiate()
	pickup.position = level.to_local(global_position)
	level.call_deferred("add_child", pickup)

func _on_detection_body_entered(body: Node2D) -> void:
	if (
		activation_notifier.is_on_screen()
		and body is CharacterBody2D
		and body.has_method("take_damage")
	):
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
