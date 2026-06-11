@tool
extends SceneTree

const TILESET_PATH := "res://assets/castlevania_minimal_tileset.tres"

const SOLID_SOURCE := 0
const NIGHT_SOURCE := 1
const ATLAS_MARGIN := Vector2i(16, 35)
const NIGHT_ATLAS_MARGIN := Vector2i(16, 36)
const ATLAS_SEPARATION := Vector2i(1, 1)
const TILE_REGIONS := {
	"stone_block": Vector2i(0, 4),
	"column": Vector2i(0, 13),
}
const NIGHT_TILE_REGIONS := {
	"purple_block": Vector2i(0, 0),
}

func _initialize() -> void:
	var texture := load("res://assets/castlevania_tileset.png")
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	tile_set.add_physics_layer(0)
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.margins = ATLAS_MARGIN
	source.separation = ATLAS_SEPARATION
	source.texture_region_size = Vector2i(16, 16)

	for atlas_coords in TILE_REGIONS.values():
		source.create_tile(atlas_coords)

	tile_set.add_source(source, SOLID_SOURCE)

	for atlas_coords in TILE_REGIONS.values():
		var tile_data := source.get_tile_data(atlas_coords, 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(
			0,
			0,
			PackedVector2Array(
				[
					Vector2(-8, -8),
					Vector2(8, -8),
					Vector2(8, 8),
					Vector2(-8, 8),
				]
			)
		)

	var night_source := TileSetAtlasSource.new()
	night_source.texture = texture
	night_source.margins = NIGHT_ATLAS_MARGIN
	night_source.separation = ATLAS_SEPARATION
	night_source.texture_region_size = Vector2i(16, 16)

	for atlas_coords in NIGHT_TILE_REGIONS.values():
		night_source.create_tile(atlas_coords)

	tile_set.add_source(night_source, NIGHT_SOURCE)

	for atlas_coords in NIGHT_TILE_REGIONS.values():
		var tile_data := night_source.get_tile_data(atlas_coords, 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(
			0,
			0,
			PackedVector2Array(
				[
					Vector2(-8, -8),
					Vector2(8, -8),
					Vector2(8, 8),
					Vector2(-8, 8),
				]
			)
		)

	ResourceSaver.save(tile_set, TILESET_PATH)
	print("Created ", TILESET_PATH)
	quit()
