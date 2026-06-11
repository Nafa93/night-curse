@tool
extends SceneTree

func _initialize() -> void:
	var source := TileSetAtlasSource.new()
	for property in source.get_property_list():
		var name := str(property.name)
		if "margin" in name or "separation" in name or "region" in name:
			print(name)
	quit()
