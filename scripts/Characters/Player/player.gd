extends CharacterBody2D

signal lives_changed(lives: int, max_lives: int)
signal keys_changed(key_count: int, max_keys: int)
signal game_over

@export var speed := 90.0
@export var jump_velocity := -270.0
@export var gravity := 900.0
@export var acceleration := 720.0
@export var friction := 900.0
@export var jump_buffer_time := 0.12
@export var direction_buffer_time := 0.12
@export var coyote_time := 0.1
@export var ledge_help_height := 8
@export var ledge_help_reach := 7.0
@export var ledge_help_nudge := 2.0
@export var max_lives := 3
@export var max_keys := 2
@export var fall_limit_y := 420.0
@export var attack_time := 0.18
@export var attack_cooldown := 0.35
@export var knockback_horizontal := 150.0
@export var knockback_vertical := -180.0
@export var hit_feedback_time := 0.3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_visual: AnimatedSprite2D = $AttackArea/Visual
@onready var left_foot_check: RayCast2D = $LeftFootCheck
@onready var right_foot_check: RayCast2D = $RightFootCheck
@onready var ledge_lower_check: RayCast2D = $LedgeLowerCheck
@onready var ledge_upper_check: RayCast2D = $LedgeUpperCheck

var lives := max_lives
var respawn_position := Vector2.ZERO
var is_respawning := false
var is_day_form := false
var key_count := 0
var has_key: bool:
	get:
		return key_count > 0
var facing_direction := 1.0
var can_attack := true
var is_attacking := false
var is_crouching := false
var is_taking_damage := false
var jump_buffer_remaining := 0.0
var direction_buffer_remaining := 0.0
var buffered_direction := 0.0
var coyote_time_remaining := 0.0
var held_jump_consumed := false

func _ready() -> void:
	respawn_position = global_position
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_area.body_entered.connect(_on_attack_body_entered)
	_set_attack_enabled(false)
	_play_animation(&"Idle")
	lives_changed.emit(lives, max_lives)
	keys_changed.emit(key_count, max_keys)

func set_day_state(is_day: bool) -> void:
	is_day_form = is_day
	modulate.a = 1.0

func prepare_for_world_transition() -> void:
	velocity = Vector2.ZERO
	is_crouching = false
	_play_animation(&"Idle")

func set_checkpoint(checkpoint_position: Vector2) -> void:
	respawn_position = checkpoint_position

func restore_from_checkpoint(checkpoint_position: Vector2, restored_key_count: int) -> void:
	global_position = checkpoint_position
	respawn_position = checkpoint_position
	lives = max_lives
	key_count = clampi(restored_key_count, 0, max_keys)
	velocity = Vector2.ZERO
	is_respawning = false
	is_taking_damage = false
	sprite.visible = true
	_reset_movement_assists()
	lives_changed.emit(lives, max_lives)
	keys_changed.emit(key_count, max_keys)

func _physics_process(delta: float) -> void:
	if is_respawning:
		return

	var was_on_floor := is_on_floor()
	var input_direction := Input.get_axis("ui_left", "ui_right")
	_update_input_buffers(delta, input_direction)
	_update_coyote_time(delta, was_on_floor)

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_taking_damage:
		move_and_slide()
		_update_animation()
		return

	is_crouching = is_on_floor() and Input.is_action_pressed("ui_down")

	if is_on_floor() and (is_crouching or is_attacking):
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		var movement_direction := input_direction
		if is_on_floor():
			movement_direction = _get_ground_direction(input_direction)

		if movement_direction != 0.0:
			facing_direction = signf(movement_direction)
			velocity.x = move_toward(
				velocity.x,
				facing_direction * speed,
				acceleration * delta
			)
			sprite.flip_h = facing_direction < 0.0
			if is_on_floor():
				direction_buffer_remaining = 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	_try_consume_buffered_jump()

	move_and_slide()
	if not was_on_floor and is_on_floor():
		coyote_time_remaining = coyote_time
		_apply_buffered_landing_direction(delta, input_direction)
		_try_consume_buffered_jump()
	elif not is_on_floor():
		_try_ledge_help(input_direction)
	_update_animation()

	if is_on_floor() and _has_stable_floor_support():
		respawn_position = global_position

	if global_position.y > fall_limit_y:
		_respawn_after_fall()

	if Input.is_action_just_pressed("attack"):
		_start_attack()

func _update_input_buffers(delta: float, input_direction: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_remaining = jump_buffer_time
	elif Input.is_action_pressed("jump") and not is_on_floor() and not held_jump_consumed:
		jump_buffer_remaining = jump_buffer_time
	else:
		jump_buffer_remaining = maxf(jump_buffer_remaining - delta, 0.0)
	if not Input.is_action_pressed("jump"):
		held_jump_consumed = false

	if input_direction != 0.0:
		buffered_direction = signf(input_direction)
		direction_buffer_remaining = direction_buffer_time
	else:
		direction_buffer_remaining = maxf(direction_buffer_remaining - delta, 0.0)

func _update_coyote_time(delta: float, was_on_floor: bool) -> void:
	if was_on_floor:
		coyote_time_remaining = coyote_time
	else:
		coyote_time_remaining = maxf(coyote_time_remaining - delta, 0.0)

func _get_ground_direction(input_direction: float) -> float:
	if input_direction != 0.0:
		return signf(input_direction)
	if direction_buffer_remaining > 0.0:
		return buffered_direction
	return 0.0

func _apply_buffered_landing_direction(delta: float, input_direction: float) -> void:
	if is_crouching or is_attacking:
		return

	var landing_direction := _get_ground_direction(input_direction)
	if landing_direction == 0.0:
		return

	facing_direction = landing_direction
	sprite.flip_h = facing_direction < 0.0
	velocity.x = move_toward(velocity.x, landing_direction * speed, acceleration * delta)
	direction_buffer_remaining = 0.0

func _try_consume_buffered_jump() -> void:
	if (
		jump_buffer_remaining <= 0.0
		or coyote_time_remaining <= 0.0
		or is_crouching
		or is_attacking
	):
		return

	velocity.y = jump_velocity
	jump_buffer_remaining = 0.0
	coyote_time_remaining = 0.0
	held_jump_consumed = true

func _try_ledge_help(input_direction: float) -> void:
	if velocity.y <= 0.0 or input_direction == 0.0:
		return

	var direction := signf(input_direction)
	ledge_lower_check.target_position = Vector2(ledge_help_reach * direction, 0.0)
	ledge_upper_check.target_position = Vector2(ledge_help_reach * direction, 0.0)
	ledge_lower_check.force_raycast_update()
	ledge_upper_check.force_raycast_update()
	if not ledge_lower_check.is_colliding() or ledge_upper_check.is_colliding():
		return

	for lift in range(1, ledge_help_height + 1):
		var vertical_motion := Vector2(0.0, -float(lift))
		if test_move(transform, vertical_motion):
			continue

		var lifted_transform := transform.translated(vertical_motion)
		var horizontal_motion := Vector2(ledge_help_nudge * direction, 0.0)
		if test_move(lifted_transform, horizontal_motion):
			continue

		position += vertical_motion + horizontal_motion
		velocity.y = 0.0
		apply_floor_snap()
		return

func _update_animation() -> void:
	if is_attacking:
		_play_animation(&"CrouchAttack" if is_crouching else &"Attack")
	elif not is_on_floor():
		_play_animation(&"Jump" if velocity.y < 0.0 else &"Fall")
	elif is_crouching:
		_play_animation(&"Crouch")
	elif abs(velocity.x) > 1.0:
		_play_animation(&"Walking")
	else:
		_play_animation(&"Idle")

func _play_animation(animation_name: StringName) -> void:
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)

func _has_stable_floor_support() -> bool:
	return left_foot_check.is_colliding() and right_foot_check.is_colliding()

func collect_key() -> bool:
	if key_count >= max_keys:
		return false

	key_count += 1
	keys_changed.emit(key_count, max_keys)
	return true

func use_key() -> bool:
	return use_keys(1)

func use_keys(amount: int) -> bool:
	var keys_to_use := maxi(amount, 0)
	if key_count < keys_to_use:
		return false

	key_count -= keys_to_use
	keys_changed.emit(key_count, max_keys)
	return true

func heal(amount: int) -> bool:
	if lives >= max_lives or amount <= 0:
		return false

	lives = min(lives + amount, max_lives)
	lives_changed.emit(lives, max_lives)
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
	var survived := _apply_life_loss()
	if not survived:
		return
	is_taking_damage = false

func _flash_player() -> void:
	var flash_interval := hit_feedback_time / 6.0
	for _flash_index in range(3):
		sprite.visible = false
		await get_tree().create_timer(flash_interval).timeout
		sprite.visible = true
		await get_tree().create_timer(flash_interval).timeout

func _start_attack() -> void:
	if not can_attack:
		return

	can_attack = false
	is_attacking = true
	await _start_melee_attack()
	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _start_melee_attack() -> void:
	attack_area.position = Vector2(
		18.0 * facing_direction,
		7.0 if is_crouching else 0.0
	)
	attack_visual.flip_h = facing_direction < 0.0
	attack_visual.play(&"attack")
	_set_attack_enabled(true)
	await get_tree().create_timer(attack_time).timeout
	_set_attack_enabled(false)

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
	var survived := _apply_life_loss()
	if not survived:
		return
	global_position = respawn_position
	velocity = Vector2.ZERO
	_reset_movement_assists()
	await _flash_player()
	is_respawning = false

func _reset_movement_assists() -> void:
	jump_buffer_remaining = 0.0
	direction_buffer_remaining = 0.0
	buffered_direction = 0.0
	coyote_time_remaining = 0.0
	held_jump_consumed = false

func _apply_life_loss() -> bool:
	lives -= 1
	lives_changed.emit(lives, max_lives)

	if lives <= 0:
		game_over.emit()
		return false

	return true
