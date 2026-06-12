extends StaticBody2D

@onready var prompt_label: Label = $PromptLabel

var player: Node = null
var is_unlocked := false

func _ready() -> void:
	$UnlockArea.body_entered.connect(_on_body_entered)
	$UnlockArea.body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if is_unlocked or player == null:
		return

	prompt_label.text = "UP: OPEN" if player.has_key else "LOCKED"
	if player.has_key and Input.is_action_just_pressed("interact") and player.use_key():
		_unlock()

func _unlock() -> void:
	is_unlocked = true
	collision_layer = 0
	visible = false
	prompt_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		prompt_label.visible = false
