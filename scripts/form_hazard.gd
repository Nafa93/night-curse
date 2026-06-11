extends Area2D

@export var damages_day_form := true
@export var damages_night_form := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return

	if body.is_day_form == damages_day_form or (not body.is_day_form and damages_night_form):
		body.take_damage()
