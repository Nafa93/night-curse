extends Node2D

signal day_changed(is_day: bool)

@onready var player: CharacterBody2D = $Player
@onready var lives_label: Label = $HUD/Panel/LivesLabel
@onready var form_label: Label = $HUD/Panel/FormLabel
@onready var key_label: Label = $HUD/Panel/KeyLabel
@onready var message_label: Label = $HUD/Panel/MessageLabel

var is_day := false

func _ready() -> void:
	player.lives_changed.connect(_on_player_lives_changed)
	player.key_changed.connect(_on_player_key_changed)
	player.game_over.connect(_on_player_game_over)
	_on_player_lives_changed(player.lives, player.max_lives)
	_on_player_key_changed(player.has_key)
	_apply_day_state()

func toggle_day() -> void:
	is_day = not is_day
	_apply_day_state()

func show_level_clear() -> void:
	message_label.text = "LEVEL CLEAR"

func _apply_day_state() -> void:
	form_label.text = "DAY  BODY" if is_day else "NIGHT  GHOST"
	player.set_day_state(is_day)
	get_tree().call_group("day_night_reactive", "set_day_state", is_day)
	day_changed.emit(is_day)

func _on_player_lives_changed(lives: int, max_lives: int) -> void:
	var marks := ""
	for index in max_lives:
		marks += "I" if index < lives else "-"

	lives_label.text = "LIVES  " + marks
	if lives > 0:
		message_label.text = ""

func _on_player_game_over() -> void:
	message_label.text = "GAME OVER"

func _on_player_key_changed(has_key: bool) -> void:
	key_label.text = "KEY  I" if has_key else "KEY  -"
