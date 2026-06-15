extends CharacterBody2D

const SMALL_HEART_PICKUP := preload("res://scenes/Items/SmallHeartPickup.tscn")
const CANDY_PICKUP := preload("res://scenes/Items/CandyPickup.tscn")

@export var speed := 45.0
@export var patrol_distance := 120.0
@export var gravity := 980.0
@export var health := 1
@export var score_value := 100
@export var hit_flash_time := 0.12
@export_range(0.0, 1.0, 0.01) var heart_drop_chance := 0.15
@export_range(0.0, 1.0, 0.01) var candy_drop_chance := 0.1
@export var active_in_corporeal_world := true
@export var active_in_spectral_world := false

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var damage_area: Area2D = $DamageArea
@onready var activation_notifier: VisibleOnScreenNotifier2D = $ActivationNotifier

var start_x := 0.0
var direction := 1.0
var is_active := false
var is_world_enabled := true
var is_near_screen := false
var is_taking_hit := false
var base_collision_layer := 8

func _ready() -> void:
	start_x = global_position.x
	base_collision_layer = collision_layer
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	activation_notifier.screen_entered.connect(_on_screen_entered)
	activation_notifier.screen_exited.connect(_on_screen_exited)
	add_to_group("day_night_reactive")
	visual.play("default")
	_update_visual_direction()
	_update_checks()
	refresh_activation_state()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * speed
	move_and_slide()

	if is_on_wall() or (is_on_floor() and not floor_check.is_colliding()) or abs(global_position.x - start_x) >= patrol_distance:
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
	if not is_active:
		velocity = Vector2.ZERO

func take_hit() -> void:
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

func _turn_around() -> void:
	direction *= -1.0
	_update_visual_direction()
	_update_checks()

func _update_visual_direction() -> void:
	visual.flip_h = direction > 0.0

func _update_checks() -> void:
	floor_check.position.x = 12.0 * direction
	wall_check.target_position = Vector2(18.0 * direction, 0.0)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if is_active and body.has_method("take_damage"):
		body.take_damage(global_position)

func _on_screen_entered() -> void:
	is_near_screen = true
	refresh_activation_state()

func _on_screen_exited() -> void:
	is_near_screen = false
	refresh_activation_state()
