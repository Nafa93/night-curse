extends Node2D

signal day_changed(is_day: bool)

@onready var player: CharacterBody2D = $Player
@onready var message_label: Label = $HUD/Panel/MessageLabel
@onready var life_icons: Array[TextureRect] = [
	$HUD/Panel/Life1/Full,
	$HUD/Panel/Life2/Full,
	$HUD/Panel/Life3/Full,
]
@onready var key_icons: Array[TextureRect] = [
	$HUD/Panel/Key1/Full,
	$HUD/Panel/Key2/Full,
]

var is_day := false

func _ready() -> void:
	player.lives_changed.connect(_on_player_lives_changed)
	player.keys_changed.connect(_on_player_keys_changed)
	player.game_over.connect(_on_player_game_over)
	_on_player_lives_changed(player.lives, player.max_lives)
	_on_player_keys_changed(player.key_count, player.max_keys)
	_apply_day_state()

func toggle_day() -> void:
	is_day = not is_day
	_apply_day_state()

func show_level_clear() -> void:
	message_label.text = "LEVEL CLEAR"

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
	message_label.text = "GAME OVER"

func _on_player_keys_changed(key_count: int, _max_keys: int) -> void:
	for index in key_icons.size():
		key_icons[index].visible = index < key_count
