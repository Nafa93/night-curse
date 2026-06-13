extends Node2D

signal world_changed(is_otherside: bool)

@onready var player: CharacterBody2D = $Player
@onready var hud: GameHUD = $HUD
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var regular_world: TileMapLayer = $Worlds/Regular
@onready var otherside_world: TileMapLayer = $Worlds/Otherside
@onready var world_transition: WorldTransition = $WorldTransition

var is_otherside := false
var is_world_transitioning := false
var is_game_over := false
var points := 0

func _ready() -> void:
	player.lives_changed.connect(_on_player_lives_changed)
	player.keys_changed.connect(_on_player_keys_changed)
	player.game_over.connect(_on_player_game_over)
	_on_player_lives_changed(player.lives, player.max_lives)
	_on_player_keys_changed(player.key_count, player.max_keys)
	_update_points_label()
	_apply_world_state()

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
