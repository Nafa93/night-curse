@tool
extends Node2D

@export var texture: Texture2D:
	set(value):
		texture = value
		_rebuild()
@export var size := Vector2(64, 16):
	set(value):
		size = value
		_rebuild()
@export var tile_region := Rect2(16, 36, 16, 16):
	set(value):
		tile_region = value
		_rebuild()
@export var tile_size := Vector2(16, 16):
	set(value):
		tile_size = value
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return

	for child in get_children():
		if Engine.is_editor_hint():
			child.free()
		else:
			child.queue_free()

	var placeholder := get_parent().get_node_or_null("Visual")
	if placeholder != null:
		placeholder.visible = false

	if texture == null or tile_size.x <= 0.0 or tile_size.y <= 0.0:
		return

	var columns := int(ceil(size.x / tile_size.x))
	var rows := int(ceil(size.y / tile_size.y))
	var start := -size * 0.5 + tile_size * 0.5

	for y in rows:
		for x in columns:
			var tile := Sprite2D.new()
			tile.texture = texture
			tile.region_enabled = true
			tile.region_rect = tile_region
			tile.position = start + Vector2(x * tile_size.x, y * tile_size.y)
			add_child(tile)
