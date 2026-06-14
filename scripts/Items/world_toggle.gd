extends Area2D

@onready var prompt_label: Label = $PromptLabel
@onready var visual: AnimatedSprite2D = $Visual

var player_is_near := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("day_night_reactive")
	prompt_label.visible = false

func set_day_state(is_regular: bool) -> void:
	visual.play(&"regular" if is_regular else &"otherside")

func _process(_delta: float) -> void:
	if player_is_near and Input.is_action_just_pressed("interact"):
		var level := get_tree().current_scene
		if level.has_method("toggle_world"):
			level.toggle_world()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_near = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_near = false
		prompt_label.visible = false
