extends Node2D

@export var rise_distance := 20.0
@export var duration := 0.7

@onready var label: Label = $Label

var _points := 0

func setup(points: int) -> void:
	_points = max(points, 0)

func _ready() -> void:
	label.text = "+%d" % _points

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise_distance, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_delay(duration * 0.45)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
