class_name SectionDoor
extends StaticBody2D

signal opened
signal closed
signal locked

enum DoorState {
	CLOSED,
	OPENING,
	OPEN,
	CLOSING,
	LOCKED,
}

@export var opens_from_left := true
@export var locks_after_crossing := true
@export var starts_open := false
@export var close_distance := 12.0
@export var creates_room_boundary := true
@export var checkpoint_distance := 32.0

@onready var left_door: AnimatedSprite2D = $LeftDoor
@onready var right_door: AnimatedSprite2D = $RightDoor
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea

var _state := DoorState.CLOSED
var _tracked_player: CharacterBody2D
var _active_door: AnimatedSprite2D
var _inactive_door: AnimatedSprite2D

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	_configure_door_sides()

	if starts_open:
		_state = DoorState.OPEN
		_active_door.play(&"open")
		_set_collision_enabled(false)
	else:
		_active_door.play(&"closed")
		_set_collision_enabled(true)
	_inactive_door.play(&"closed")

func _physics_process(_delta: float) -> void:
	if _state != DoorState.OPEN or not is_instance_valid(_tracked_player):
		return

	var crossing_direction := get_crossing_direction()
	var distance_past_door := (
		_tracked_player.global_position.x - global_position.x
	) * crossing_direction

	if distance_past_door >= close_distance:
		close_door(locks_after_crossing)

func open_door() -> void:
	if _state not in [DoorState.CLOSED]:
		return

	_state = DoorState.OPENING
	_active_door.play(&"opening")
	await _active_door.animation_finished

	if _state != DoorState.OPENING:
		return

	_state = DoorState.OPEN
	_set_collision_enabled(false)
	opened.emit()

func close_door(lock_after_closing := false) -> void:
	if _state not in [DoorState.OPEN]:
		return

	_state = DoorState.CLOSING
	_set_collision_enabled(true)
	_active_door.play(&"closing")
	await _active_door.animation_finished

	if _state != DoorState.CLOSING:
		return

	_state = DoorState.LOCKED if lock_after_closing else DoorState.CLOSED
	_tracked_player = null
	closed.emit()

	if _state == DoorState.LOCKED:
		locked.emit()

func reset_door() -> void:
	_state = DoorState.CLOSED
	_tracked_player = null
	_configure_door_sides()
	_active_door.play(&"closed")
	_inactive_door.play(&"closed")
	_set_collision_enabled(true)

func restore_locked_after_crossing() -> void:
	_state = DoorState.LOCKED
	_tracked_player = null
	_configure_door_sides()
	_active_door.play(&"closed")
	_inactive_door.play(&"closed")
	_set_collision_enabled(true)

func is_open() -> bool:
	return _state == DoorState.OPEN

func is_locked() -> bool:
	return _state == DoorState.LOCKED

func get_crossing_direction() -> float:
	return 1.0 if opens_from_left else -1.0

func get_checkpoint_position(player_y: float) -> Vector2:
	return Vector2(
		global_position.x + get_crossing_direction() * checkpoint_distance,
		player_y
	)

func get_active_door() -> AnimatedSprite2D:
	return _active_door

func _configure_door_sides() -> void:
	_active_door = right_door if opens_from_left else left_door
	_inactive_door = left_door if opens_from_left else right_door

func _on_detection_body_entered(body: Node2D) -> void:
	if _state != DoorState.CLOSED or not _is_player(body):
		return

	var crossing_direction := get_crossing_direction()
	var approach_distance := (body.global_position.x - global_position.x) * crossing_direction
	if approach_distance >= 0.0:
		return

	_tracked_player = body as CharacterBody2D
	open_door()

func _on_detection_body_exited(body: Node2D) -> void:
	if body != _tracked_player or _state != DoorState.OPEN:
		return

	var crossing_direction := get_crossing_direction()
	var exit_distance := (body.global_position.x - global_position.x) * crossing_direction
	if exit_distance < 0.0:
		close_door(false)

func _is_player(body: Node2D) -> bool:
	return body is CharacterBody2D and body.has_method("heal")

func _set_collision_enabled(is_enabled: bool) -> void:
	collision_shape.set_deferred("disabled", not is_enabled)
