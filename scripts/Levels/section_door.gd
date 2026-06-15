class_name SectionDoor
extends StaticBody2D

signal opened
signal closed
signal locked
signal unlock_failed

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
@export var lockable := false
@export_range(0, 2, 1) var required_keys := 1
@export var close_distance := 12.0
@export var creates_room_boundary := true
@export var checkpoint_distance := 32.0

@onready var door_sprite: AnimatedSprite2D = $RightDoor
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea

var _state := DoorState.CLOSED
var _tracked_player: CharacterBody2D
var _key_lock_opened := false

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)

	if starts_open:
		_state = DoorState.OPEN
		_key_lock_opened = true
		door_sprite.play(&"open")
		_set_collision_enabled(false)
	else:
		door_sprite.play(&"closed")
		_set_collision_enabled(true)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_tracked_player):
		return

	if _state != DoorState.OPEN:
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
	door_sprite.play(&"opening")
	await door_sprite.animation_finished

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
	door_sprite.play(&"closing")
	await door_sprite.animation_finished

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
	_key_lock_opened = false
	door_sprite.play(&"closed")
	_set_collision_enabled(true)

func restore_locked_after_crossing() -> void:
	_state = DoorState.LOCKED
	_tracked_player = null
	door_sprite.play(&"closed")
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
	return door_sprite

func _on_detection_body_entered(body: Node2D) -> void:
	if _state != DoorState.CLOSED or not _is_player(body):
		return

	var crossing_direction := get_crossing_direction()
	var approach_distance := (body.global_position.x - global_position.x) * crossing_direction
	if approach_distance >= 0.0:
		return

	_tracked_player = body as CharacterBody2D
	if not lockable or _key_lock_opened:
		open_door()

func _on_detection_body_exited(body: Node2D) -> void:
	if body != _tracked_player:
		return

	if _state == DoorState.CLOSED:
		_tracked_player = null
		return

	if _state != DoorState.OPEN:
		return

	var crossing_direction := get_crossing_direction()
	var exit_distance := (body.global_position.x - global_position.x) * crossing_direction
	if exit_distance < 0.0:
		close_door(false)

func _try_unlock() -> void:
	if not is_instance_valid(_tracked_player):
		return

	var keys_needed := maxi(required_keys, 0)
	if not _tracked_player.has_method("use_keys") or not _tracked_player.use_keys(keys_needed):
		unlock_failed.emit()
		return

	_key_lock_opened = true
	open_door()

func _is_player(body: Node2D) -> bool:
	return body is CharacterBody2D and body.has_method("heal")

func _set_collision_enabled(is_enabled: bool) -> void:
	collision_shape.set_deferred("disabled", not is_enabled)
