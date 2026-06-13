extends Node2D

signal day_changed(is_day: bool)

@onready var player: CharacterBody2D = $Player
@onready var message_label: Label = $HUD/Panel/MessageLabel
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var points_label: Label = $HUD/Panel/PointsBox/PointsValue
@onready var life_icons: Array[TextureRect] = [
	$HUD/Panel/LivesBox/Life1/Full,
	$HUD/Panel/LivesBox/Life2/Full,
	$HUD/Panel/LivesBox/Life3/Full,
]
@onready var key_icons: Array[TextureRect] = [
	$HUD/Panel/KeysBox/Key1/Full,
	$HUD/Panel/KeysBox/Key2/Full,
]

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
	message_label.text = "LEVEL CLEAR"

func add_points(amount: int) -> void:
	points += max(amount, 0)
	_update_points_label()

func _update_points_label() -> void:
	points_label.text = "%06d" % points

func _apply_day_state() -> void:
	player.set_day_state(is_day)
	get_tree().call_group("day_night_reactive", "set_day_state", is_day)
	day_changed.emit(is_day)

func _on_player_lives_changed(lives: int, max_lives: int) -> void:
	for index in life_icons.size():
		life_icons[index].visible = index < lives
	if lives > 0:
		message_label.text = ""

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
	for index in key_icons.size():
		key_icons[index].visible = index < key_count
