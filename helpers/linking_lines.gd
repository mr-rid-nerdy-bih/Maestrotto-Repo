extends Node2D
## Draws one Line2D per link. `links` is filled by LinkingComponent:
## key = source building's cell, value = {source, target, from, to, endBuildingType, ...}

var links := {}
var linkLines := {}

func _process(_delta: float) -> void:
	var halfCell := Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE) / 2.0

	# 1. Drop links whose buildings are gone or no longer linked to each other.
	for key in links.keys():
		var link: Dictionary = links[key]
		var source = link.get("source")
		var target = link.get("target")
		if not (is_instance_valid(source) and is_instance_valid(target)) \
				or source.transportComponent.toTransport != target:
			links.erase(key)

	# 2. Remove lines that no longer have a link.
	for key in linkLines.keys():
		if not links.has(key):
			linkLines[key].queue_free()
			linkLines.erase(key)

	# 3. Create / update a line for every link.
	for key in links:
		var link: Dictionary = links[key]
		var line: Line2D = linkLines.get(key)
		if line == null:
			line = Line2D.new()
			line.width = 2.0
			line.z_index = ZLayers.LINK_LINE
			line.add_point(Vector2.ZERO)
			line.add_point(Vector2.ZERO)
			add_child(line)
			linkLines[key] = line
		line.default_color = _color_for(link["endBuildingType"])
		line.set_point_position(0, GridManager.get_global_at(link["from"]) + halfCell)
		line.set_point_position(1, GridManager.get_global_at(link["to"]) + halfCell)

func _color_for(type: BuildingTypes.Type) -> Color:
	match type:
		BuildingTypes.Type.PACKAGER: return Color.GREEN
		BuildingTypes.Type.CHUTE: return Color.ORANGE
	return Color.RED
