@tool
extends StaticBody2D

@export var platform_size := Vector2(128, 32):
	set(value):
		platform_size = value
		_update_shape_and_tiles()
@export var tile_texture: Texture2D:
	set(value):
		tile_texture = value
		_update_shape_and_tiles()
@export var tile_region := Rect2(16, 104, 16, 16):
	set(value):
		tile_region = value
		_update_shape_and_tiles()
@export var tile_size := Vector2(16, 16):
	set(value):
		tile_size = value
		_update_shape_and_tiles()
@export var active_during_day := true
@export var active_during_night := true
@export var inactive_alpha := 0.18

var base_collision_layer := 1

func _ready() -> void:
	base_collision_layer = collision_layer
	add_to_group("day_night_reactive")
	_update_shape_and_tiles()

func set_day_state(is_day: bool) -> void:
	var is_active := active_during_day if is_day else active_during_night
	collision_layer = base_collision_layer if is_active else 0
	visible = true
	modulate.a = 1.0 if is_active else inactive_alpha

func _update_shape_and_tiles() -> void:
	if not is_inside_tree():
		return

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		var rectangle := collision_shape.shape as RectangleShape2D
		if rectangle == null:
			rectangle = RectangleShape2D.new()
			collision_shape.shape = rectangle
		rectangle.size = platform_size

	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		var half_size := platform_size * 0.5
		visual.polygon = PackedVector2Array(
			[
				Vector2(-half_size.x, -half_size.y),
				Vector2(half_size.x, -half_size.y),
				Vector2(half_size.x, half_size.y),
				Vector2(-half_size.x, half_size.y),
			]
		)

	var top_edge := get_node_or_null("TopEdge") as Line2D
	if top_edge != null:
		var half_width := platform_size.x * 0.5
		top_edge.position.y = -platform_size.y * 0.5 + 1.0
		top_edge.points = PackedVector2Array([Vector2(-half_width, 0), Vector2(half_width, 0)])

	var tile_skin := get_node_or_null("TileSkin")
	if tile_skin != null:
		tile_skin.texture = tile_texture
		tile_skin.size = platform_size
		tile_skin.tile_region = tile_region
		tile_skin.tile_size = tile_size
