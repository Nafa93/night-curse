extends Area2D

@onready var prompt_label: Label = $PromptLabel

var player: Node = null
var is_taken := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if is_taken or player == null:
		return

	prompt_label.text = "UP: TAKE"
	if Input.is_action_just_pressed("interact"):
		if player.collect_key():
			is_taken = true
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
