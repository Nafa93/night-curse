extends CharacterBody2D

signal defeated
signal charge_started
signal charge_finished

const SMALL_HEART_PICKUP := preload("res://scenes/Items/SmallHeartPickup.tscn")

enum State {
	PATROL,
	TELEGRAPH,
	CHARGE,
	RECOVER,
	DEFEATED,
}

@export var autonomous := true
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
@export var score_value := 300
@export_range(0.0, 1.0, 0.01) var heart_drop_chance := 0.2
@export var active_in_corporeal_world := true
@export var active_in_spectral_world := true
@export var remove_on_defeat := true

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var damage_area: Area2D = $DamageArea
@onready var detection_area: Area2D = $DetectionArea

var state := State.PATROL
var direction := -1.0
var start_x := 0.0
var charge_start_x := 0.0
var state_time := 0.0
var is_active := true
var base_collision_layer := 8
var tracked_target: CharacterBody2D

func _ready() -> void:
	start_x = global_position.x
	base_collision_layer = collision_layer
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	add_to_group("day_night_reactive")
	_enter_patrol()

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

	if state == State.CHARGE and is_on_wall():
		_enter_recover()

func set_day_state(is_corporeal: bool) -> void:
	is_active = active_in_corporeal_world if is_corporeal else active_in_spectral_world
	collision_layer = base_collision_layer if is_active else 0
	damage_area.set_deferred("monitoring", is_active)
	detection_area.set_deferred("monitoring", is_active and autonomous)
	visible = is_active

func trigger_attack(target_position: Vector2) -> void:
	if not is_active or state in [State.TELEGRAPH, State.CHARGE, State.DEFEATED]:
		return

	var target_direction: float = signf(target_position.x - global_position.x)
	if target_direction != 0.0:
		direction = target_direction
	_update_direction()
	_enter_telegraph()

func reset_attack() -> void:
	if state == State.DEFEATED:
		return

	start_x = global_position.x
	_enter_patrol()

func take_hit() -> void:
	if state == State.DEFEATED:
		return

	health -= 1
	if health > 0:
		return

	state = State.DEFEATED
	velocity = Vector2.ZERO
	defeated.emit()
	_award_points()
	_try_drop_heart()

	if remove_on_defeat:
		queue_free()
	else:
		collision_layer = 0
		damage_area.set_deferred("monitoring", false)
		detection_area.set_deferred("monitoring", false)
		visible = false
		set_physics_process(false)

func _process_patrol(_delta: float) -> void:
	if not autonomous:
		velocity.x = 0.0
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
	velocity.x = direction * charge_speed
	if abs(global_position.x - charge_start_x) >= charge_distance:
		_enter_recover()

func _process_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, charge_speed * delta * 5.0)
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
	visual.play(&"charge")
	charge_started.emit()

func _enter_recover() -> void:
	if state != State.CHARGE:
		return

	state = State.RECOVER
	state_time = 0.0
	visual.play(&"detect")
	charge_finished.emit()

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

	var pickup: Area2D = SMALL_HEART_PICKUP.instantiate()
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position
