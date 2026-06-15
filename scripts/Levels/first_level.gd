extends Node2D

signal world_changed(is_otherside: bool)

const FLOATING_SCORE_SCENE := preload("res://scenes/Levels/FloatingScore.tscn")

@export var camera_vertical_offset := -24.0
@export var room_camera_transition_time := 0.9
@export var room_camera_smoothing_speed := 3.0
@export var camera_bounds_horizontal_padding := 32.0
@export var camera_door_limit_inset := 8.0
@export var camera_door_bounds_inset := 16.0
@export var camera_door_back_reveal := 8.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var hud: GameHUD = $HUD
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var the_end_screen: TheEndScreen = $TheEndScreen
@onready var regular_world: WorldContainer = $Worlds/Regular
@onready var otherside_world: WorldContainer = $Worlds/Otherside
@onready var regular_tile_map: TileMapLayer = $Worlds/Regular/TileMap
@onready var otherside_tile_map: TileMapLayer = $Worlds/Otherside/TileMap
@onready var world_transition: WorldTransition = $WorldTransition

var is_otherside := false
var is_world_transitioning := false
var is_game_over := false
var points := 0
var base_camera_zoom := Vector2.ONE
var base_camera_smoothing_speed := 8.0
var has_room_limit_left := false
var has_room_limit_right := false
var room_limit_left := 0.0
var room_limit_right := 0.0
var section_doors: Array[SectionDoor] = []
var last_camera_bounds_cell_x := 2147483647

func _ready() -> void:
	_connect_section_doors()
	_connect_final_boss()
	_configure_camera()
	player.lives_changed.connect(_on_player_lives_changed)
	player.keys_changed.connect(_on_player_keys_changed)
	player.game_over.connect(_on_player_game_over)
	game_over_screen.continue_selected.connect(_on_continue_selected)
	game_over_screen.quit_selected.connect(_on_quit_selected)
	_restore_checkpoint()
	_on_player_lives_changed(player.lives, player.max_lives)
	_on_player_keys_changed(player.key_count, player.max_keys)
	_update_points_label()
	_apply_world_state()

func _process(_delta: float) -> void:
	if is_game_over or is_world_transitioning:
		return

	var active_tile_map := otherside_tile_map if is_otherside else regular_tile_map
	var player_cell := active_tile_map.local_to_map(
		active_tile_map.to_local(player.global_position)
	)
	if player_cell.x == last_camera_bounds_cell_x:
		return

	_update_camera_limits(active_tile_map, false)

func _configure_camera() -> void:
	base_camera_zoom = camera.zoom
	base_camera_smoothing_speed = camera.position_smoothing_speed
	camera.position.y = camera_vertical_offset
	camera.limit_smoothed = true
	_update_camera_limits(regular_tile_map)

func _connect_section_doors() -> void:
	for node in find_children("*", "SectionDoor", true, false):
		var door := node as SectionDoor
		section_doors.append(door)
		door.locked.connect(_on_section_door_locked.bind(door))
		door.unlock_failed.connect(_on_section_door_unlock_failed)

func _connect_final_boss() -> void:
	for node in get_tree().get_nodes_in_group("final_boss"):
		if node.has_signal("defeated"):
			node.defeated.connect(_on_final_boss_defeated)

func _on_final_boss_defeated() -> void:
	player.set_physics_process(false)
	the_end_screen.show_screen()

func _update_camera_limits(world: TileMapLayer, reset_smoothing := true) -> void:
	var world_bounds: Rect2 = _get_tilemap_bounds(world)
	var viewport_size: Vector2 = get_viewport_rect().size
	var minimum_zoom: float = maxf(
		viewport_size.x / world_bounds.size.x,
		viewport_size.y / world_bounds.size.y
	)
	var target_zoom: float = maxf(base_camera_zoom.x, minimum_zoom)
	camera.zoom = Vector2(target_zoom, target_zoom)
	var room_bounds: Rect2 = _get_current_room_tilemap_bounds(world, world_bounds)
	var left_limit := floori(room_bounds.position.x)
	var right_limit := ceili(room_bounds.end.x)
	if has_room_limit_left:
		left_limit = floori(room_limit_left)
	if has_room_limit_right:
		right_limit = ceili(room_limit_right)

	camera.limit_left = left_limit
	camera.limit_top = floori(room_bounds.position.y)
	camera.limit_right = right_limit
	camera.limit_bottom = ceili(room_bounds.end.y)
	last_camera_bounds_cell_x = world.local_to_map(
		world.to_local(player.global_position)
	).x
	if reset_smoothing:
		camera.reset_smoothing()

func _get_tilemap_bounds(layer: TileMapLayer) -> Rect2:
	var used_rect := layer.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return Rect2()

	var half_tile := Vector2(layer.tile_set.tile_size) * 0.5
	var first_cell_center := layer.map_to_local(used_rect.position)
	var last_cell := used_rect.position + used_rect.size - Vector2i.ONE
	var last_cell_center := layer.map_to_local(last_cell)
	var top_left := layer.to_global(first_cell_center - half_tile)
	var bottom_right := layer.to_global(last_cell_center + half_tile)
	return Rect2(top_left, bottom_right - top_left)

func _get_current_room_tilemap_bounds(layer: TileMapLayer, world_bounds: Rect2) -> Rect2:
	var room_left := world_bounds.position.x
	var room_right := world_bounds.end.x
	var player_x := player.global_position.x
	var has_left_door := false
	var has_right_door := false

	for door in section_doors:
		if not is_instance_valid(door) or not door.creates_room_boundary:
			continue

		var door_x := door.global_position.x
		if door_x <= player_x:
			if door_x > room_left:
				room_left = door_x
				has_left_door = true
		else:
			if door_x < room_right:
				room_right = door_x
				has_right_door = true

	var camera_room_left := room_left + (
		camera_door_limit_inset if has_left_door else 0.0
	)
	var camera_room_right := room_right - (
		camera_door_limit_inset if has_right_door else 0.0
	)
	var bounds_sample_left := room_left + (
		camera_door_bounds_inset if has_left_door else 0.0
	)
	var bounds_sample_right := room_right - (
		camera_door_bounds_inset if has_right_door else 0.0
	)

	var half_tile := Vector2(layer.tile_set.tile_size) * 0.5
	var half_view_width := get_viewport_rect().size.x / camera.zoom.x * 0.5
	var minimum_center_x := camera_room_left + half_view_width
	var maximum_center_x := camera_room_right - half_view_width
	var camera_center_x := player_x + camera.position.x
	if minimum_center_x <= maximum_center_x:
		camera_center_x = clampf(camera_center_x, minimum_center_x, maximum_center_x)
	else:
		camera_center_x = (camera_room_left + camera_room_right) * 0.5

	var sample_left := maxf(
		bounds_sample_left,
		camera_center_x - half_view_width - camera_bounds_horizontal_padding
	)
	var sample_right := minf(
		bounds_sample_right,
		camera_center_x + half_view_width + camera_bounds_horizontal_padding
	)
	var room_top := INF
	var room_bottom := -INF
	for cell in layer.get_used_cells():
		var cell_center := layer.to_global(layer.map_to_local(cell))
		if cell_center.x < sample_left or cell_center.x > sample_right:
			continue

		room_top = minf(room_top, cell_center.y - half_tile.y)
		room_bottom = maxf(room_bottom, cell_center.y + half_tile.y)

	if is_inf(room_top) or is_inf(room_bottom):
		return world_bounds

	return Rect2(
		Vector2(camera_room_left, room_top),
		Vector2(
			camera_room_right - camera_room_left,
			room_bottom - room_top
		)
	)

func toggle_world() -> void:
	if is_world_transitioning:
		return

	is_world_transitioning = true
	player.prepare_for_world_transition()
	player.set_physics_process(false)
	await world_transition.play(_switch_world)
	player.set_physics_process(true)
	is_world_transitioning = false

func _switch_world() -> void:
	is_otherside = not is_otherside
	_apply_world_state()

func _on_section_door_locked(door: SectionDoor) -> void:
	if not door.creates_room_boundary or is_world_transitioning:
		return

	is_world_transitioning = true
	player.prepare_for_world_transition()
	player.set_physics_process(false)
	camera.position_smoothing_speed = room_camera_smoothing_speed
	_complete_room_transition(door)
	var half_w := get_viewport_rect().size.x / camera.zoom.x / 2.0
	camera.limit_left = maxi(camera.limit_left, floori(camera.get_screen_center_position().x - half_w))
	await get_tree().create_timer(room_camera_transition_time).timeout
	camera.limit_left = floori(room_limit_left)
	camera.position_smoothing_speed = base_camera_smoothing_speed
	player.set_physics_process(true)
	is_world_transitioning = false

func _on_section_door_unlock_failed() -> void:
	hud.shake_keys()

func _complete_room_transition(door: SectionDoor) -> void:
	var crossing_direction := door.get_crossing_direction()
	if crossing_direction > 0.0:
		has_room_limit_left = true
		room_limit_left = door.global_position.x - camera_door_back_reveal
	else:
		has_room_limit_right = true
		room_limit_right = door.global_position.x + camera_door_back_reveal

	var active_tile_map := otherside_tile_map if is_otherside else regular_tile_map
	_update_camera_limits(active_tile_map, false)
	var checkpoint_position := door.get_checkpoint_position(player.global_position.y)
	player.set_checkpoint(checkpoint_position)
	CheckpointManager.save_checkpoint(
		scene_file_path,
		get_path_to(door),
		checkpoint_position,
		is_otherside,
		points,
		player.key_count
	)

func _restore_checkpoint() -> void:
	if not CheckpointManager.has_checkpoint_for(scene_file_path):
		return

	var checkpoint_door := get_node_or_null(CheckpointManager.door_path) as SectionDoor
	if checkpoint_door != null:
		checkpoint_door.restore_locked_after_crossing()
		if checkpoint_door.get_crossing_direction() > 0.0:
			has_room_limit_left = true
			room_limit_left = checkpoint_door.global_position.x - camera_door_back_reveal
		else:
			has_room_limit_right = true
			room_limit_right = checkpoint_door.global_position.x + camera_door_back_reveal

	is_otherside = CheckpointManager.is_otherside
	points = CheckpointManager.score
	player.restore_from_checkpoint(
		CheckpointManager.spawn_position,
		CheckpointManager.key_count
	)

func show_level_clear() -> void:
	hud.show_message("LEVEL CLEAR")

func add_points(amount: int) -> void:
	points += max(amount, 0)
	_update_points_label()

func award_points(amount: int, world_position: Vector2) -> void:
	if amount <= 0:
		return

	add_points(amount)
	var floating_score := FLOATING_SCORE_SCENE.instantiate()
	floating_score.setup(amount)
	floating_score.position = to_local(world_position)
	add_child(floating_score)

func _update_points_label() -> void:
	hud.update_score(points)

func _apply_world_state() -> void:
	var is_regular := not is_otherside
	regular_world.set_world_active(is_regular)
	otherside_world.set_world_active(is_otherside)
	_update_camera_limits(otherside_tile_map if is_otherside else regular_tile_map)

	player.set_day_state(is_regular)
	_update_shared_world_reactive_nodes(is_regular)
	world_changed.emit(is_otherside)

func _update_shared_world_reactive_nodes(is_regular: bool) -> void:
	for node in get_tree().get_nodes_in_group("day_night_reactive"):
		if regular_world.is_ancestor_of(node) or otherside_world.is_ancestor_of(node):
			continue
		if node.has_method("set_day_state"):
			node.set_day_state(is_regular)

func _on_player_lives_changed(lives: int, _max_lives: int) -> void:
	hud.update_lives(lives)
	if lives > 0:
		hud.show_message("")

func _on_player_game_over() -> void:
	if is_game_over:
		return

	is_game_over = true
	game_over_screen.show_menu()
	get_tree().paused = true

func _on_continue_selected() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_selected() -> void:
	get_tree().paused = false
	CheckpointManager.clear()
	get_tree().change_scene_to_file("res://scenes/Levels/MainMenu.tscn")

func _on_player_keys_changed(key_count: int, _max_keys: int) -> void:
	hud.update_keys(key_count)
