extends Node2D
## Draws one Line2D per link. `links` is filled by LinkingComponent:
## key = "sourceCell|outputCell", value = {source, target, outputCell, from, to, endBuildingType, ...}

var links := {}
var linkLines := {}

## Keeps one Line2D per link in sync. Only visible in link mode.
func _process(_delta: float) -> void:
	var halfCell := Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE) / 2.0
	
	if InputManager.currentMode == 3:
		visible = true
	else:
		visible = false
	
	# Drop links whose buildings are gone or no longer linked to each other.
	@warning_ignore("untyped_declaration")
	for key in links.keys():
		var link: Dictionary = links[key]
		@warning_ignore("untyped_declaration")
		var source = link.get("source")
		@warning_ignore("untyped_declaration")
		var target = link.get("target")
		if not (is_instance_valid(source) and is_instance_valid(target)) \
				or source.transportComponent.get_target(link["outputCell"]) != target:
			links.erase(key)

	# Remove lines that no longer have a link.
	@warning_ignore("untyped_declaration")
	for key in linkLines.keys():
		if not links.has(key):
			linkLines[key].queue_free()
			linkLines.erase(key)

	# Create or update a line for every link.
	@warning_ignore("untyped_declaration")
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
		line.default_color = color_for(link["endBuildingType"])
		line.set_point_position(0, GridManager.get_global_at(link["from"]) + halfCell)
		line.set_point_position(1, GridManager.get_global_at(link["to"]) + halfCell)

## Line colour based on the type of building being linked to.
func color_for(type: BuildingTypes.Type) -> Color:
	match type:
		BuildingTypes.Type.PACKAGER: return Color.GREEN
		BuildingTypes.Type.CHUTE: return Color.ORANGE
	return Color.RED
