extends StaticBody2D

@export var active_during_day := true
@export var active_during_night := true
@export var inactive_alpha := 0.18

var base_collision_layer := 1

func _ready() -> void:
	base_collision_layer = collision_layer
	add_to_group("day_night_reactive")

func set_day_state(is_day: bool) -> void:
	var is_active := active_during_day if is_day else active_during_night
	collision_layer = base_collision_layer if is_active else 0
	visible = true
	modulate.a = 1.0 if is_active else inactive_alpha
