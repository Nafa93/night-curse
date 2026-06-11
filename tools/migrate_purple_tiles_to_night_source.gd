@tool
extends SceneTree

const LEVEL_PATH := "res://scenes/LevelDraft.tscn"
const OLD_SOURCE := 0
const NIGHT_SOURCE := 1
const PURPLE_BLOCK := Vector2i(0, 0)

func _initialize() -> void:
	var packed_scene := load(LEVEL_PATH) as PackedScene
	var root := packed_scene.instantiate()

	for layer_path in ["TileMaps/DayTileMap", "TileMaps/NightTileMap"]:
		var layer := root.get_node_or_null(layer_path) as TileMapLayer
		if layer == null:
			continue

		for cell in layer.get_used_cells():
			if layer.get_cell_source_id(cell) == OLD_SOURCE and layer.get_cell_atlas_coords(cell) == PURPLE_BLOCK:
				layer.set_cell(cell, NIGHT_SOURCE, PURPLE_BLOCK)

	var new_scene := PackedScene.new()
	new_scene.pack(root)
	ResourceSaver.save(new_scene, LEVEL_PATH)
	print("Migrated purple tiles in ", LEVEL_PATH)
	quit()
