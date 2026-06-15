extends "res://scripts/Items/gravity_pickup.gd"

enum KeyVariant {
	RED,
	GOLD,
}

@export var score_value := 300
@export var key_variant: KeyVariant = KeyVariant.RED

@onready var prompt_label: Label = $PromptLabel
@onready var visual: Sprite2D = $Sprite2D

var player: Node = null
var is_taken := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false
	visual.frame = key_variant * 2

func _process(_delta: float) -> void:
	if is_taken or player == null:
		return

	prompt_label.text = "UP: TAKE"
	if Input.is_action_just_pressed("interact"):
		if player.collect_key():
			is_taken = true
			SoundManager.play_pickup()
			_award_points()
			queue_free()
		else:
			prompt_label.text = "KEYS FULL"

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		prompt_label.visible = false

func _award_points() -> void:
	var level := get_tree().current_scene
	if level.has_method("award_points"):
		level.award_points(score_value, global_position)
	elif level.has_method("add_points"):
		level.add_points(score_value)
