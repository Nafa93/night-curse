extends CharacterBody2D

signal lives_changed(lives: int, max_lives: int)
signal key_changed(has_key: bool)
signal game_over

@export var speed := 180.0
@export var jump_velocity := -460.0
@export var gravity := 980.0
@export var acceleration := 1200.0
@export var friction := 1400.0
@export var max_lives := 3
@export var fall_limit_y := 420.0
@export var attack_time := 0.18
@export var attack_cooldown := 0.35
@export var knockback_horizontal := 150.0
@export var knockback_vertical := -180.0
@export var hit_feedback_time := 0.3
@export var spectral_projectile_scene: PackedScene

@onready var sprite: Polygon2D = $Body
@onready var head: Polygon2D = $Head
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_visual: Polygon2D = $AttackArea/Visual
@onready var left_foot_check: RayCast2D = $LeftFootCheck
@onready var right_foot_check: RayCast2D = $RightFootCheck

var lives := max_lives
var respawn_position := Vector2.ZERO
var is_respawning := false
var is_day_form := false
var has_key := false
var facing_direction := 1.0
var can_attack := true
var is_taking_damage := false

func _ready() -> void:
	respawn_position = global_position
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_area.body_entered.connect(_on_attack_body_entered)
	_set_attack_enabled(false)
	lives_changed.emit(lives, max_lives)
	key_changed.emit(has_key)

func set_day_state(is_day: bool) -> void:
	is_day_form = is_day
	if is_day:
		sprite.color = Color(0.74, 0.16, 0.18, 1)
		head.color = Color(0.91, 0.78, 0.55, 1)
		modulate.a = 1.0
	else:
		sprite.color = Color(0.36, 0.72, 0.94, 1)
		head.color = Color(0.72, 0.91, 1.0, 1)
		modulate.a = 0.62

func _physics_process(delta: float) -> void:
	if is_respawning:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_taking_damage:
		move_and_slide()
		return

	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0.0:
		facing_direction = sign(direction)
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		sprite.scale.x = facing_direction
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = jump_velocity

	move_and_slide()

	if is_on_floor() and _has_stable_floor_support():
		respawn_position = global_position

	if global_position.y > fall_limit_y:
		_respawn_after_fall()

	if Input.is_action_just_pressed("attack"):
		_start_attack()

func _has_stable_floor_support() -> bool:
	return left_foot_check.is_colliding() and right_foot_check.is_colliding()

func collect_key() -> void:
	has_key = true
	key_changed.emit(has_key)

func use_key() -> bool:
	if not has_key:
		return false

	has_key = false
	key_changed.emit(has_key)
	return true

func take_damage(source_position: Vector2 = Vector2.ZERO) -> void:
	if is_respawning or is_taking_damage:
		return

	is_taking_damage = true
	var knockback_direction: float = sign(global_position.x - source_position.x)
	if knockback_direction == 0.0:
		knockback_direction = -facing_direction
	velocity = Vector2(knockback_direction * knockback_horizontal, knockback_vertical)

	await _flash_player()
	await _apply_life_loss()
	is_taking_damage = false

func _flash_player() -> void:
	var flash_interval := hit_feedback_time / 6.0
	for _flash_index in range(3):
		sprite.visible = false
		head.visible = false
		await get_tree().create_timer(flash_interval).timeout
		sprite.visible = true
		head.visible = true
		await get_tree().create_timer(flash_interval).timeout

func _start_attack() -> void:
	if not can_attack:
		return

	can_attack = false
	if is_day_form:
		await _start_melee_attack()
	else:
		_fire_spectral_projectile()

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _start_melee_attack() -> void:
	attack_area.position.x = 26.0 * facing_direction
	attack_visual.scale.x = facing_direction
	_set_attack_enabled(true)
	await get_tree().create_timer(attack_time).timeout
	_set_attack_enabled(false)

func _fire_spectral_projectile() -> void:
	if spectral_projectile_scene == null:
		return

	var projectile := spectral_projectile_scene.instantiate()
	projectile.global_position = global_position + Vector2(24.0 * facing_direction, -8.0)
	projectile.setup(facing_direction)
	get_tree().current_scene.add_child(projectile)

func _set_attack_enabled(is_enabled: bool) -> void:
	attack_area.monitoring = is_enabled
	attack_shape.disabled = not is_enabled
	attack_visual.visible = is_enabled

func _on_attack_area_entered(area: Area2D) -> void:
	if area.has_method("take_hit"):
		area.take_hit()

func _on_attack_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()

func _respawn_after_fall() -> void:
	if is_respawning:
		return

	is_respawning = true
	await _apply_life_loss()
	global_position = respawn_position
	velocity = Vector2.ZERO
	await _flash_player()
	is_respawning = false

func _apply_life_loss() -> void:
	lives -= 1
	lives_changed.emit(lives, max_lives)

	if lives <= 0:
		game_over.emit()
		lives = max_lives
		respawn_position = get_parent().get_node("StartPosition").global_position
		await get_tree().create_timer(0.8).timeout

	lives_changed.emit(lives, max_lives)
