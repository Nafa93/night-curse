extends Node

const _ATTACK_SFX := preload("res://assets/Sounds/attack.wav")
const _PICKUP_SFX := preload("res://assets/Sounds/pickup.wav")
const _IMPACT_SFX := preload("res://assets/Sounds/enemy-impact.wav")

var _attack_player: AudioStreamPlayer
var _pickup_player: AudioStreamPlayer
var _impact_player: AudioStreamPlayer

func _ready() -> void:
	_attack_player = _make_player(_ATTACK_SFX)
	_pickup_player = _make_player(_PICKUP_SFX)
	_impact_player = _make_player(_IMPACT_SFX)

func play_attack() -> void:
	_attack_player.play()

func play_pickup() -> void:
	_pickup_player.play()

func play_impact() -> void:
	_impact_player.play()

func _make_player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p
