extends CharacterBody2D

signal defeated
signal charge_started
signal charge_finished

const SMALL_HEART_PICKUP := preload("res://scenes/Items/SmallHeartPickup.tscn")
const CANDY_PICKUP := preload("res://scenes/Items/CandyPickup.tscn")

enum State {
	PATROL,
	TELEGRAPH,
	CHARGE,
	RECOVER,
	DEFEATED,
}

@export var autonomous := true
@export var return_to_home := false
@export var home_return_speed := 150.0
@export var aim_at_target := false
@export var redirect_damage_to_parent := false
@export var patrol_speed := 36.0
@export var patrol_distance := 96.0
@export var charge_speed := 220.0
@export var charge_distance := 150.0
@export var telegraph_time := 0.55
@export var recover_time := 0.65
@export var shake_distance := 2.0
@export var shake_speed := 45.0
@export var gravity := 980.0
@export var health := 2
@export var hit_flash_time := 0.12
@export var score_value := 300
@export_range(0.0, 1.0, 0.01) var heart_drop_chance := 0.2
@export_range(0.0, 1.0, 0.01) var candy_drop_chance := 0.15
@export var active_in_corporeal_world := true
@export var active_in_spectral_world := true
@export var remove_on_defeat := true

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var damage_area: Area2D = $DamageArea
@onready var detection_area: Area2D = $DetectionArea
@onready var activation_notifier: VisibleOnScreenNotifier2D = $ActivationNotifier

var home_position := Vector2.ZERO
var charge_target_y := 0.0
var state := State.PATROL
var direction := -1.0
var start_x := 0.0
var charge_start_x := 0.0
var state_time := 0.0
var is_active := false
var is_world_enabled := true
var is_near_screen := false
var is_taking_hit := false
var base_collision_layer := 8
var tracked_target: CharacterBody2D

func _ready() -> void:
	home_position = global_position
	start_x = global_position.x
	base_collision_layer = collision_layer
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	activation_notifier.screen_entered.connect(_on_screen_entered)
	activation_notifier.screen_exited.connect(_on_screen_exited)
	add_to_group("day_night_reactive")
	_enter_patrol()
	refresh_activation_state()

func _physics_process(delta: float) -> void:
	if not is_active or state == State.DEFEATED:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		State.PATROL:
			_process_patrol(delta)
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.CHARGE:
			_process_charge()
		State.RECOVER:
			_process_recover(delta)

	move_and_slide()

	if state == State.CHARGE and (is_on_wall() or (aim_at_target and get_slide_collision_count() > 0)):
		_enter_recover()

func set_day_state(is_corporeal: bool) -> void:
	is_world_enabled = active_in_corporeal_world if is_corporeal else active_in_spectral_world
	visible = is_world_enabled
	refresh_activation_state()

func refresh_activation_state() -> void:
	is_active = is_world_enabled and is_near_screen and is_visible_in_tree()
	set_physics_process(is_active and state != State.DEFEATED)
	set_deferred("collision_layer", base_collision_layer if is_active else 0)
	damage_area.set_deferred("monitoring", is_active)
	detection_area.set_deferred("monitoring", is_active and autonomous)
	if not is_active:
		velocity = Vector2.ZERO
		tracked_target = null

func trigger_attack(target_position: Vector2) -> void:
	if not is_active or state in [State.TELEGRAPH, State.CHARGE, State.DEFEATED]:
		return
	if return_to_home and global_position.distance_to(home_position) > 2.0:
		return

	var target_direction: float = signf(target_position.x - global_position.x)
	if target_direction != 0.0:
		direction = target_direction
	if aim_at_target:
		charge_target_y = target_position.y
	_update_direction()
	_enter_telegraph()

func reset_attack() -> void:
	if state == State.DEFEATED:
		return

	start_x = global_position.x
	_enter_patrol()

func take_hit() -> void:
	if redirect_damage_to_parent:
		var parent := get_parent()
		if parent and parent.has_method("take_hit"):
			parent.take_hit()
		return

	if is_taking_hit or state == State.DEFEATED:
		return

	SoundManager.play_impact()
	health -= 1
	if health > 0:
		_flash_hit()
		return

	state = State.DEFEATED
	velocity = Vector2.ZERO
	defeated.emit()
	_award_points()
	_try_drop_heart()
	_try_drop_candy()

	if remove_on_defeat:
		queue_free()
	else:
		collision_layer = 0
		damage_area.set_deferred("monitoring", false)
		detection_area.set_deferred("monitoring", false)
		visible = false
		set_physics_process(false)

func _flash_hit() -> void:
	is_taking_hit = true
	visual.modulate = Color(1.0, 1.0, 1.0, 0.25)
	await get_tree().create_timer(hit_flash_time).timeout
	visual.modulate = Color.WHITE
	is_taking_hit = false

func _process_patrol(_delta: float) -> void:
	if not autonomous:
		if return_to_home:
			var diff := home_position - global_position
			if diff.length() <= 2.0:
				velocity = Vector2.ZERO
				global_position = home_position
				_face_player_direction()
			else:
				velocity = diff.normalized() * home_return_speed
				direction = signf(diff.x)
				_update_direction()
		else:
			velocity.x = 0.0
			_face_player_direction()
		return

	if _can_detect_target():
		trigger_attack(tracked_target.global_position)
		return

	velocity.x = direction * patrol_speed
	if (
		is_on_wall()
		or (is_on_floor() and not floor_check.is_colliding())
		or abs(global_position.x - start_x) >= patrol_distance
	):
		_turn_around()

func _process_telegraph(delta: float) -> void:
	velocity.x = 0.0
	state_time += delta
	visual.position.x = sin(state_time * shake_speed) * shake_distance

	if state_time >= telegraph_time:
		visual.position = Vector2.ZERO
		_enter_charge()

func _process_charge() -> void:
	if aim_at_target:
		var target := Vector2(charge_start_x + direction * charge_distance, charge_target_y)
		velocity = (target - global_position).normalized() * charge_speed
	else:
		velocity.x = direction * charge_speed
	if abs(global_position.x - charge_start_x) >= charge_distance:
		_enter_recover()

func _process_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, charge_speed * delta * 5.0)
	velocity.y = move_toward(velocity.y, 0.0, charge_speed * delta * 5.0)
	state_time += delta
	if state_time >= recover_time:
		direction *= -1.0
		start_x = global_position.x
		_enter_patrol()

func _enter_patrol() -> void:
	state = State.PATROL
	state_time = 0.0
	visual.position = Vector2.ZERO
	visual.play(&"move")
	_update_direction()
	_update_checks()

func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	state_time = 0.0
	velocity.x = 0.0
	visual.play(&"detect")

func _enter_charge() -> void:
	state = State.CHARGE
	charge_start_x = global_position.x
	if aim_at_target:
		var player := _find_player()
		if is_instance_valid(player):
			charge_target_y = player.global_position.y
	visual.play(&"charge")
	charge_started.emit()

func _find_player() -> CharacterBody2D:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var candidate := scene.find_child("Player", true, false)
	if candidate is CharacterBody2D and candidate.has_method("take_damage"):
		return candidate as CharacterBody2D
	return null

func _enter_recover() -> void:
	if state != State.CHARGE:
		return

	state = State.RECOVER
	state_time = 0.0
	visual.play(&"detect")
	charge_finished.emit()

func _face_player_direction() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var player := scene.find_child("Player", true, false)
	if player == null:
		return
	var dir := signf((player as Node2D).global_position.x - global_position.x)
	if dir != 0.0 and dir != direction:
		direction = dir
		_update_direction()

func _turn_around() -> void:
	direction *= -1.0
	start_x = global_position.x
	_update_direction()
	_update_checks()

func _update_direction() -> void:
	visual.flip_h = direction > 0.0

func _update_checks() -> void:
	floor_check.position.x = 12.0 * direction
	wall_check.target_position = Vector2(18.0 * direction, 0.0)

func _can_detect_target() -> bool:
	return (
		is_instance_valid(tracked_target)
		and abs(tracked_target.global_position.y - global_position.y) <= 40.0
	)

func _on_detection_body_entered(body: Node2D) -> void:
	if autonomous and _is_player(body):
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

func _is_player(body: Node2D) -> bool:
	return body is CharacterBody2D and body.has_method("take_damage")

func _award_points() -> void:
	var level := get_tree().current_scene
	if level.has_method("award_points"):
		level.award_points(score_value, global_position)
	elif level.has_method("add_points"):
		level.add_points(score_value)

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
