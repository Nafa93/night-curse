class_name WorldContainer
extends Node2D

var _collision_states: Dictionary = {}

func _ready() -> void:
	_cache_collision_states()

func set_world_active(is_active: bool) -> void:
	_cache_collision_states()
	visible = is_active
	process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED

	for tile_map in find_children("*", "TileMapLayer", true, false):
		var layer := tile_map as TileMapLayer
		layer.enabled = is_active
		layer.collision_enabled = is_active

	for collision_object in find_children("*", "CollisionObject2D", true, false):
		var body := collision_object as CollisionObject2D
		var state: Vector2i = _collision_states[body.get_instance_id()]
		body.collision_layer = state.x if is_active else 0
		body.collision_mask = state.y if is_active else 0

	for node in find_children("*", "", true, false):
		if node.has_method("refresh_activation_state"):
			node.refresh_activation_state()

func _cache_collision_states() -> void:
	for collision_object in find_children("*", "CollisionObject2D", true, false):
		var body := collision_object as CollisionObject2D
		var instance_id := body.get_instance_id()
		if not _collision_states.has(instance_id):
			_collision_states[instance_id] = Vector2i(
				body.collision_layer,
				body.collision_mask
			)
