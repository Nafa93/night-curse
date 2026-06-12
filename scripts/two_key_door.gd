extends StaticBody2D

@export var required_keys := 2
@export var clear_level_on_open := true

@onready var prompt_label: Label = $PromptLabel
@onready var unlock_area: Area2D = $UnlockArea

var player: Node = null
var is_unlocked := false

func _ready() -> void:
	unlock_area.body_entered.connect(_on_body_entered)
	unlock_area.body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if is_unlocked or player == null:
		return

	var missing_keys: int = max(required_keys - player.key_count, 0)
	prompt_label.text = "UP: OPEN" if missing_keys == 0 else "NEED %d KEYS" % missing_keys
	if missing_keys == 0 and Input.is_action_just_pressed("interact"):
		for _index in required_keys:
			player.use_key()
		_unlock()

func _unlock() -> void:
	is_unlocked = true
	collision_layer = 0
	$CollisionShape2D.set_deferred("disabled", true)
	prompt_label.visible = false
	$Sprite2D.modulate = Color(0.55, 0.55, 0.55, 1)
	var tween := create_tween()
	tween.tween_property($Sprite2D, "position:y", -72.0, 0.7)
	await tween.finished
	visible = false
	if clear_level_on_open and get_tree().current_scene.has_method("show_level_clear"):
		get_tree().current_scene.show_level_clear()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		prompt_label.visible = false

