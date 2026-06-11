@tool
extends SceneTree

func _initialize() -> void:
	var image := Image.load_from_file("res://assets/castlevania_tileset.png")
	var background := image.get_pixel(0, 0)
	print("background=", background)

	for y in range(0, 80):
		var count := 0
		for x in range(0, 300):
			if image.get_pixel(x, y) != background:
				count += 1
		if count > 20:
			print("row ", y, " non-bg count ", count)

	print("column counts around left edge")
	for x in range(0, 40):
		var count := 0
		for y in range(0, 260):
			if image.get_pixel(x, y) != background:
				count += 1
		if count > 20:
			print("col ", x, " non-bg count ", count)

	quit()
