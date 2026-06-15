class_name GameHUD
extends CanvasLayer

@onready var message_label: Label = $Panel/MessageLabel
@onready var score_label: Label = $Panel/PointsBox/PointsValue
@onready var life_icons: Array[TextureRect] = [
	$Panel/LivesBox/Life1/Full,
	$Panel/LivesBox/Life2/Full,
	$Panel/LivesBox/Life3/Full,
]
@onready var key_icons: Array[TextureRect] = [
	$Panel/KeysBox/Key1/Full,
	$Panel/KeysBox/Key2/Full,
]
@onready var key_slots: Array[Control] = [
	$Panel/KeysBox/Key1,
	$Panel/KeysBox/Key2,
]

var _key_slot_start_positions: Array[Vector2] = []
var _key_shake_time := 0.0

func _ready() -> void:
	for slot in key_slots:
		_key_slot_start_positions.append(slot.position)
	set_process(false)

func _process(delta: float) -> void:
	_key_shake_time = maxf(_key_shake_time - delta, 0.0)
	if _key_shake_time <= 0.0:
		_reset_key_slot_positions()
		set_process(false)
		return

	var offset := roundf(sin(_key_shake_time * TAU * 18.0) * 2.0)
	for index in key_slots.size():
		key_slots[index].position = (
			_key_slot_start_positions[index] + Vector2(offset, 0.0)
		)

func update_lives(lives: int) -> void:
	for index in life_icons.size():
		life_icons[index].visible = index < lives

func update_keys(key_count: int) -> void:
	for index in key_icons.size():
		key_icons[index].visible = index < key_count

func update_score(score: int) -> void:
	score_label.text = "%06d" % score

func show_message(message: String) -> void:
	message_label.text = message

func shake_keys() -> void:
	_key_shake_time = 0.35
	_reset_key_slot_positions()
	set_process(true)

func _reset_key_slot_positions() -> void:
	for index in key_slots.size():
		key_slots[index].position = _key_slot_start_positions[index]
