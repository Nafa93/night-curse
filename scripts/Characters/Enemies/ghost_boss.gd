extends CharacterBody2D

signal defeated

@export var health := 10
@export var hit_flash_time := 0.12
@export var score_value := 5000
@export var bob_amplitude := 4.0
@export var bob_speed := 1.5
@export var attack_interval := 2.5
@export var active_in_corporeal_world := false
@export var active_in_spectral_world := true

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var activation_notifier: VisibleOnScreenNotifier2D = $ActivationNotifier
@onready var right_hand: CharacterBody2D = $RightHandMelee
@onready var left_hand: CharacterBody2D = $LeftHandEnemy

var is_world_enabled := true
var is_near_screen := false
var is_taking_hit := false
var bob_elapsed := 0.0
var attack_timer := 0.0
var left_attacks_next := false
var base_collision_layer := 8

func _ready() -> void:
	base_collision_layer = collision_layer
	add_to_group("day_night_reactive")
	add_to_group("final_boss")
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	activation_notifier.screen_entered.connect(_on_screen_entered)
	activation_notifier.screen_exited.connect(_on_screen_exited)
	visual.play(&"idle")
	refresh_activation_state()

func _process(delta: float) -> void:
	if not is_world_enabled or not is_near_screen:
		return

	bob_elapsed += delta
	visual.position.y = sin(bob_elapsed * bob_speed) * bob_amplitude

	var player := _find_player()
	if is_instance_valid(player):
		var dir := signf(player.global_position.x - global_position.x)
		if dir != 0.0:
			visual.flip_h = dir > 0.0

	attack_timer += delta
	if attack_timer >= attack_interval:
		attack_timer = 0.0
		_trigger_next_attack()

func set_day_state(is_corporeal: bool) -> void:
	is_world_enabled = active_in_corporeal_world if is_corporeal else active_in_spectral_world
	visible = is_world_enabled
	refresh_activation_state()

func refresh_activation_state() -> void:
	var active := is_world_enabled and is_near_screen and is_visible_in_tree()
	set_deferred("collision_layer", base_collision_layer if active else 0)
	damage_area.set_deferred("monitoring", active)

func take_hit() -> void:
	if is_taking_hit or health <= 0:
		return

	SoundManager.play_impact()
	health -= 1
	if health <= 0:
		var level := get_tree().current_scene
		if level.has_method("award_points"):
			level.award_points(score_value, global_position)
		elif level.has_method("add_points"):
			level.add_points(score_value)
		defeated.emit()
		queue_free()
		return

	_flash_hit()

func _flash_hit() -> void:
	is_taking_hit = true
	visual.modulate = Color(1.0, 1.0, 1.0, 0.25)
	await get_tree().create_timer(hit_flash_time).timeout
	visual.modulate = Color.WHITE
	is_taking_hit = false

func _trigger_next_attack() -> void:
	var player := _find_player()
	if not is_instance_valid(player):
		return

	left_attacks_next = not left_attacks_next
	if left_attacks_next:
		if left_hand.has_method("trigger_shoot"):
			left_hand.trigger_shoot()
	else:
		if right_hand.has_method("trigger_attack"):
			right_hand.trigger_attack(player.global_position)

func _find_player() -> CharacterBody2D:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var candidate := scene.find_child("Player", true, false)
	if candidate is CharacterBody2D and candidate.has_method("take_damage"):
		return candidate as CharacterBody2D
	return null

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(global_position)

func _on_screen_entered() -> void:
	is_near_screen = true
	refresh_activation_state()

func _on_screen_exited() -> void:
	is_near_screen = false
	refresh_activation_state()
