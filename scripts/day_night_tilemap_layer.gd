@tool
extends TileMapLayer

@export var active_during_day := true
@export var active_during_night := true
@export var inactive_alpha := 0.18

func _ready() -> void:
	add_to_group("day_night_reactive")

func set_day_state(is_day: bool) -> void:
	var is_active := active_during_day if is_day else active_during_night
	enabled = is_active
	collision_enabled = is_active
	visible = true
	modulate.a = 1.0 if is_active else inactive_alpha
