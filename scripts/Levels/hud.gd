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
