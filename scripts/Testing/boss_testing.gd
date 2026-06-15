extends Node2D

@export var camera_vertical_offset := -24.0

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $TileMapLayer/Player/Camera2D

func _ready() -> void:
	_configure_camera()

func _configure_camera() -> void:
	var world_bounds := _get_tilemap_bounds()
	if world_bounds.size == Vector2.ZERO:
		return

	var viewport_size := get_viewport_rect().size
	var minimum_zoom := maxf(
		viewport_size.x / world_bounds.size.x,
		viewport_size.y / world_bounds.size.y
	)
	var target_zoom := maxf(camera.zoom.x, minimum_zoom)

	camera.zoom = Vector2(target_zoom, target_zoom)
	camera.position.y = camera_vertical_offset
	camera.limit_left = floori(world_bounds.position.x)
	camera.limit_top = floori(world_bounds.position.y)
	camera.limit_right = ceili(world_bounds.end.x)
	camera.limit_bottom = ceili(world_bounds.end.y)
	camera.limit_smoothed = true
	camera.reset_smoothing()

func _get_tilemap_bounds() -> Rect2:
	var used_rect := tile_map.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return Rect2()

	var half_tile := Vector2(tile_map.tile_set.tile_size) * 0.5
	var first_cell_center := tile_map.map_to_local(used_rect.position)
	var last_cell := used_rect.position + used_rect.size - Vector2i.ONE
	var last_cell_center := tile_map.map_to_local(last_cell)
	var top_left := tile_map.to_global(first_cell_center - half_tile)
	var bottom_right := tile_map.to_global(last_cell_center + half_tile)
	return Rect2(top_left, bottom_right - top_left)
