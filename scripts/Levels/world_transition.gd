class_name WorldTransition
extends CanvasLayer

@export var step_duration := 0.055
@export var blackout_hold := 0.12

@onready var blackout: ColorRect = $Blackout

var is_playing := false

func _ready() -> void:
	visible = false
	blackout.modulate.a = 0.0

func play(switch_world: Callable) -> void:
	if is_playing:
		return

	is_playing = true
	visible = true

	var lights_off: Array[float] = [0.18, 0.08, 0.36, 0.27, 0.58, 0.48, 0.78, 1.0]
	for darkness in lights_off:
		blackout.modulate.a = darkness
		await get_tree().create_timer(step_duration).timeout

	switch_world.call()
	await get_tree().create_timer(blackout_hold).timeout

	var lights_on: Array[float] = [0.78, 0.86, 0.55, 0.64, 0.32, 0.4, 0.12, 0.0]
	for darkness in lights_on:
		blackout.modulate.a = darkness
		await get_tree().create_timer(step_duration).timeout

	visible = false
	is_playing = false
