extends TileMapLayer

@export var source_id := 0
@export var atlas_coords := Vector2i(1, 1)
@export var backdrop_size := Vector2i(1, 3)

func _ready() -> void:
	for y in range(backdrop_size.y):
		for x in range(backdrop_size.x):
			set_cell(Vector2i(x, y), source_id, atlas_coords)
