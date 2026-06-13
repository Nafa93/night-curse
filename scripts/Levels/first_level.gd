extends Node2D

signal day_changed(is_day: bool)

@onready var player: CharacterBody2D = $Player
@onready var hud: GameHUD = $HUD
@onready var game_over_screen: CanvasLayer = $GameOverScreen

var is_day := false
var is_game_over := false
var points := 0

func _ready() -> void:
	player.lives_changed.connect(_on_player_lives_changed)
	player.keys_changed.connect(_on_player_keys_changed)
	player.game_over.connect(_on_player_game_over)
	_on_player_lives_changed(player.lives, player.max_lives)
	_on_player_keys_changed(player.key_count, player.max_keys)
	_update_points_label()
	_apply_day_state()

func toggle_day() -> void:
	is_day = not is_day
	_apply_day_state()

func show_level_clear() -> void:
	hud.show_message("LEVEL CLEAR")

func add_points(amount: int) -> void:
	points += max(amount, 0)
	_update_points_label()

func _update_points_label() -> void:
	hud.update_score(points)

func _apply_day_state() -> void:
	player.set_day_state(is_day)
	get_tree().call_group("day_night_reactive", "set_day_state", is_day)
	day_changed.emit(is_day)

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
