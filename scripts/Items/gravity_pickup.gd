extends Area2D

@export var gravity_enabled := true
@export var fall_gravity := 700.0
@export var max_fall_speed := 240.0
@export_flags_2d_physics var ground_collision_mask := 1

@onready var gravity_collision_shape: CollisionShape2D = $CollisionShape2D

var fall_speed := 0.0
var is_grounded := false

func _physics_process(delta: float) -> void:
	if (
		not gravity_enabled
		or is_grounded
		or gravity_collision_shape == null
		or gravity_collision_shape.shape == null
	):
		return

	fall_speed = minf(fall_speed + fall_gravity * delta, max_fall_speed)
	var motion := Vector2(0.0, fall_speed * delta)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = gravity_collision_shape.shape
	query.transform = gravity_collision_shape.global_transform
	query.motion = motion
	query.collision_mask = ground_collision_mask
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var collision_fractions := get_world_2d().direct_space_state.cast_motion(query)
	var safe_fraction := collision_fractions[0] if not collision_fractions.is_empty() else 1.0
	global_position += motion * safe_fraction

	if safe_fraction < 1.0:
		fall_speed = 0.0
		is_grounded = true
