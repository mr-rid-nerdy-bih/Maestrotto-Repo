extends Node2D

var links :=  {}
var linkLines :=  {}

func _process(_delta: float) -> void:
	var halfCell := Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE) / 2.0
	
	for cell: Vector2i in links:
		var cell1: Vector2i = links[cell]["to"]
		var fromPos := GridManager.get_global_at(cell) + halfCell
		var toPos := GridManager.get_global_at(cell1) + halfCell
		var type: BuildingTypes.Type = links[cell]["endBuildingType"]
		
		if not linkLines.has(cell):
			var line := Line2D.new()
			line.width = 2.0
			
			line.default_color = Color.RED
			match type:
				BuildingTypes.Type.PACKAGER: line.default_color = Color.GREEN
				BuildingTypes.Type.CHUTE: line.default_color = Color.ORANGE
			
			line.z_index = 20
			line.add_point(fromPos)
			line.add_point(toPos)
			add_child(line)
			linkLines[cell] = line
		else:
			var line: Line2D = linkLines[cell]
			line.set_point_position(0, fromPos)
			line.set_point_position(1, toPos)
	
	for cell: Vector2i in linkLines.keys():
		if not links.has(cell):
			linkLines[cell].queue_free()
			linkLines.erase(cell)
			return
		
		var cell1: Vector2i = links[cell]["to"]
		var fromBuilding: Building
		var toBuilding: Building
		
		fromBuilding = GridManager.get_building_at(cell)
		toBuilding = GridManager.get_building_at(cell1)
		
		if not (fromBuilding and toBuilding):
			links.erase(cell)
