extends SceneTree

const TILE_SET := preload("res://assets/placeholder_tileset.tres")
const DIMENSION_SCRIPT := preload("res://scripts/day_night_tilemap_layer.gd")

func _init() -> void:
	var scene_root := Node2D.new()
	scene_root.name = "TileMapGeometry"

	var common := _create_layer("Common", null)
	var corporeal := _create_layer("Corporeal", DIMENSION_SCRIPT)
	var spectral := _create_layer("Spectral", DIMENSION_SCRIPT)
	corporeal.active_during_night = false
	spectral.active_during_day = false

	scene_root.add_child(common)
	scene_root.add_child(corporeal)
	scene_root.add_child(spectral)
	common.owner = scene_root
	corporeal.owner = scene_root
	spectral.owner = scene_root

	_paint_common(common)
	_paint_range(corporeal, 24, 26, 5, Vector2i(4, 2))
	_paint_range(spectral, 29, 31, 4, Vector2i(7, 4))
	_paint_range(corporeal, 34, 36, 6, Vector2i(4, 2))

	var packed_scene := PackedScene.new()
	packed_scene.pack(scene_root)
	ResourceSaver.save(packed_scene, "res://scenes/TileMapGeometry.tscn")
	quit()

func _create_layer(layer_name: String, layer_script: Script) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = TILE_SET
	if layer_script != null:
		layer.set_script(layer_script)
	return layer

func _paint_common(layer: TileMapLayer) -> void:
	_paint_range(layer, 0, 6, 6)
	_paint_range(layer, 8, 10, 5)
	_paint_range(layer, 12, 14, 4)
	_paint_range(layer, 16, 23, 6)

	_paint_range(layer, 27, 28, 5)
	_paint_range(layer, 32, 33, 5)
	_paint_range(layer, 37, 46, 6)

	_paint_range(layer, 47, 60, 6)
	_paint_range(layer, 47, 49, 5)
	_paint_range(layer, 50, 52, 4)
	_paint_range(layer, 53, 56, 3)
	_paint_range(layer, 61, 68, 6)

func _paint_range(
	layer: TileMapLayer,
	start_x: int,
	end_x: int,
	y: int,
	atlas_coords := Vector2i(0, 2)
) -> void:
	for x in range(start_x, end_x + 1):
		layer.set_cell(Vector2i(x, y), 0, atlas_coords, 0)

