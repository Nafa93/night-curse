extends Node2D

signal world_changed(is_otherside: bool)

@export var camera_vertical_offset := -24.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var hud: GameHUD = $HUD
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var regular_world: TileMapLayer = $Worlds/Regular
@onready var otherside_world: TileMapLayer = $Worlds/Otherside
@onready var world_transition: WorldTransition = $WorldTransition

var is_otherside := false
var is_world_transitioning := false
var is_game_over := false
var points := 0
var base_camera_zoom := Vector2.ONE

func _ready() -> void:
	_configure_camera()
	player.lives_changed.connect(_on_player_lives_changed)
	player.keys_changed.connect(_on_player_keys_changed)
	player.game_over.connect(_on_player_game_over)
	_on_player_lives_changed(player.lives, player.max_lives)
	_on_player_keys_changed(player.key_count, player.max_keys)
	_update_points_label()
	_apply_world_state()

func _configure_camera() -> void:
	base_camera_zoom = camera.zoom
	camera.position.y = camera_vertical_offset
	_update_camera_limits(regular_world)

func _update_camera_limits(world: TileMapLayer) -> void:
	var world_bounds: Rect2 = _get_tilemap_bounds(world)
	var viewport_size: Vector2 = get_viewport_rect().size
	var minimum_zoom: float = maxf(
		viewport_size.x / world_bounds.size.x,
		viewport_size.y / world_bounds.size.y
	)
	var target_zoom: float = maxf(base_camera_zoom.x, minimum_zoom)
	camera.zoom = Vector2(target_zoom, target_zoom)
	camera.limit_left = floori(world_bounds.position.x)
	camera.limit_top = floori(world_bounds.position.y)
	camera.limit_right = ceili(world_bounds.end.x)
	camera.limit_bottom = ceili(world_bounds.end.y)
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

func toggle_world() -> void:
	if is_world_transitioning:
		return

	is_world_transitioning = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	await world_transition.play(_switch_world)
	player.set_physics_process(true)
	is_world_transitioning = false

func _switch_world() -> void:
	is_otherside = not is_otherside
	_apply_world_state()

func show_level_clear() -> void:
	hud.show_message("LEVEL CLEAR")

func add_points(amount: int) -> void:
	points += max(amount, 0)
	_update_points_label()

func _update_points_label() -> void:
	hud.update_score(points)

func _apply_world_state() -> void:
	regular_world.visible = not is_otherside
	regular_world.enabled = not is_otherside
	regular_world.collision_enabled = not is_otherside
	otherside_world.visible = is_otherside
	otherside_world.enabled = is_otherside
	otherside_world.collision_enabled = is_otherside
	_update_camera_limits(otherside_world if is_otherside else regular_world)

	var is_regular := not is_otherside
	player.set_day_state(is_regular)
	get_tree().call_group("day_night_reactive", "set_day_state", is_regular)
	world_changed.emit(is_otherside)

func _on_player_lives_changed(lives: int, _max_lives: int) -> void:
	hud.update_lives(lives)
	if lives > 0:
		hud.show_message("")

func _on_player_game_over() -> void:
	if is_game_over:
		return

	is_game_over = true
	game_over_screen.visible = true
	get_tree().paused = true
	await get_tree().create_timer(2.5, true, false, true).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Levels/MainMenu.tscn")

func _on_player_keys_changed(key_count: int, _max_keys: int) -> void:
	hud.update_keys(key_count)
