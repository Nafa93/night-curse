@tool
extends SceneTree

const TILESET_PATH := "res://assets/castlevania_minimal_tileset.tres"
const LEVEL_PATH := "res://scenes/LevelDraft.tscn"

const SOLID_SOURCE_ID := 0
const NIGHT_SOURCE_ID := 1
const PURPLE_BLOCK := Vector2i(0, 0)
const STONE_BLOCK := Vector2i(0, 4)

func _initialize() -> void:
	var tile_set := load(TILESET_PATH)
	var player_scene := load("res://scenes/Player.tscn")

	var root := Node2D.new()
	root.name = "LevelDraft"
	root.set_script(load("res://scripts/main.gd"))

	_add_background(root)
	_add_player(root, player_scene)
	_add_hud(root)
	_add_tilemaps(root, tile_set)
	_add_artifact(root, Vector2(560, 196), "SunArtifact")

	var packed_scene := PackedScene.new()
	packed_scene.pack(root)
	ResourceSaver.save(packed_scene, LEVEL_PATH)
	print("Created ", LEVEL_PATH)
	quit()

func _add_background(root: Node2D) -> void:
	var background := CanvasLayer.new()
	background.name = "Background"
	background.layer = -1
	root.add_child(background)
	background.owner = root

	var sky := ColorRect.new()
	sky.name = "Sky"
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.055, 0.063, 0.106, 1)
	background.add_child(sky)
	sky.owner = root

func _add_player(root: Node2D, player_scene: PackedScene) -> void:
	var player := player_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(80, 176)
	root.add_child(player)
	player.owner = root

	var start_position := Marker2D.new()
	start_position.name = "StartPosition"
	start_position.position = player.position
	root.add_child(start_position)
	start_position.owner = root

func _add_hud(root: Node2D) -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	root.add_child(hud)
	hud.owner = root

	var panel := Control.new()
	panel.name = "Panel"
	panel.anchor_right = 1.0
	panel.offset_bottom = 48.0
	hud.add_child(panel)
	panel.owner = root

	var bar := ColorRect.new()
	bar.name = "Bar"
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.color = Color(0.02, 0.02, 0.03, 1)
	panel.add_child(bar)
	bar.owner = root

	_add_hud_label(root, panel, "LivesLabel", "LIVES  III", Vector2(12, 10), Vector2(190, 42), Color(0.93, 0.93, 0.84, 1))
	_add_hud_label(root, panel, "FormLabel", "NIGHT  GHOST", Vector2(148, 10), Vector2(390, 42), Color(0.56, 0.84, 1, 1))
	_add_hud_label(root, panel, "KeyLabel", "KEY  -", Vector2(410, 10), Vector2(540, 42), Color(0.93, 0.93, 0.84, 1))
	var message := _add_hud_label(root, panel, "MessageLabel", "", Vector2(560, 10), Vector2(628, 42), Color(0.93, 0.24, 0.25, 1))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _add_hud_label(root: Node2D, parent: Node, label_name: String, text: String, top_left: Vector2, bottom_right: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.offset_left = top_left.x
	label.offset_top = top_left.y
	label.offset_right = bottom_right.x
	label.offset_bottom = bottom_right.y
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 22)
	label.text = text
	parent.add_child(label)
	label.owner = root
	return label

func _add_tilemaps(root: Node2D, tile_set: TileSet) -> void:
	var tilemaps := Node2D.new()
	tilemaps.name = "TileMaps"
	root.add_child(tilemaps)
	tilemaps.owner = root

	var solid := _add_tilemap_layer(root, tilemaps, "SolidTileMap", tile_set)
	for x in range(0, 18):
		solid.set_cell(Vector2i(x, 15), SOLID_SOURCE_ID, STONE_BLOCK)
	for y in range(10, 15):
		solid.set_cell(Vector2i(0, y), SOLID_SOURCE_ID, STONE_BLOCK)

	var day := _add_tilemap_layer(root, tilemaps, "DayTileMap", tile_set)
	day.set_script(load("res://scripts/day_night_tilemap_layer.gd"))
	day.active_during_night = false
	for x in range(20, 28):
		day.set_cell(Vector2i(x, 13), NIGHT_SOURCE_ID, PURPLE_BLOCK)

	var night := _add_tilemap_layer(root, tilemaps, "NightTileMap", tile_set)
	night.set_script(load("res://scripts/day_night_tilemap_layer.gd"))
	night.active_during_day = false
	for x in range(10, 16):
		night.set_cell(Vector2i(x, 10), NIGHT_SOURCE_ID, PURPLE_BLOCK)

	var decor := _add_tilemap_layer(root, tilemaps, "DecorTileMap", tile_set)
	decor.collision_enabled = false
	decor.z_index = -1

func _add_tilemap_layer(root: Node2D, parent: Node, layer_name: String, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	parent.add_child(layer)
	layer.owner = root
	return layer

func _add_artifact(root: Node2D, position: Vector2, node_name: String) -> void:
	var area := Area2D.new()
	area.name = node_name
	area.position = position
	area.collision_layer = 0
	area.collision_mask = 2
	area.set_script(load("res://scripts/sun_artifact.gd"))
	root.add_child(area)
	area.owner = root

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color(0.88, 0.71, 0.28, 1)
	visual.polygon = PackedVector2Array([Vector2(0, -20), Vector2(12, -6), Vector2(20, 0), Vector2(12, 6), Vector2(0, 20), Vector2(-12, 6), Vector2(-20, 0), Vector2(-12, -6)])
	area.add_child(visual)
	visual.owner = root

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 42.0
	shape.shape = circle
	area.add_child(shape)
	shape.owner = root

	var prompt := Label.new()
	prompt.name = "PromptLabel"
	prompt.offset_left = -58.0
	prompt.offset_top = -72.0
	prompt.offset_right = 58.0
	prompt.offset_bottom = -44.0
	prompt.add_theme_color_override("font_color", Color(0.93, 0.93, 0.84, 1))
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.text = "Z: SUN"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area.add_child(prompt)
	prompt.owner = root
