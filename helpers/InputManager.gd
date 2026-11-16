extends Node

var linkingBuilding
var beltStart: Vector2i = Vector2i(-1, -1)
var isDraggingBelt: bool = false

@onready var preview: Node2D = get_tree().current_scene.get_node("Preview")

func _unhandled_input(event: InputEvent) -> void:
	var worldMousePos = GridManager.cam.get_global_mouse_position()
	var cell = GridManager.get_coords_at(worldMousePos)
	var hasBuilding = GridManager.has_machine_at(cell)
	var hasBelt = GridManager.has_belt_at(cell)
	var buildingAtCell: Building
	var beltAtCell: Belt
	if hasBuilding: buildingAtCell = GridManager.get_building_at(cell)
	if hasBelt: beltAtCell = GridManager.get_belt_at(cell)
	
	if event.is_action("build"):
		if isDraggingBelt and event.is_released():
			isDraggingBelt = false
			
			preview.belt([], false)
			
			if !(beltStart == Vector2i(-1, -1)):
				GridManager.place_belt_at(beltStart, cell)
			beltStart = Vector2i(-1, -1)
			
			return
		
		if event.is_shift_pressed():
			if event.is_pressed():
				beltStart = cell
				isDraggingBelt = true
				print("STARTED DRAG at cell: ", beltStart)
				return
		
		elif event.is_pressed():
			GridManager.place_building_at(preview.getCurrentBuilding(), cell)
			print("Placed building (", preview.getCurrentBuilding(), ") at ", cell)
				
	elif event is InputEventMouseMotion and isDraggingBelt:
		if beltStart != Vector2i(-1, -1):
			var pathCells = calculateBeltPath(beltStart, cell)
			preview.belt(pathCells, true)
	
	if event.is_action_pressed("erase"):
		GridManager.erase_building_at(cell)
		GridManager.erase_belt_at(cell)
	
	if event.is_action_pressed("link"):
		if linkingBuilding:
			if hasBuilding:
				if linkingBuilding is Building:
					if buildingAtCell.get_script() in linkingBuilding.validOutputBuildings:
						linkingBuilding.toTransport = buildingAtCell
						print("Linked building ", linkingBuilding, " with building ", buildingAtCell, " at ", cell)
						linkingBuilding = null
						return
				elif linkingBuilding is Belt:
					if buildingAtCell.get_script() in linkingBuilding.validOutputBuildings:
						linkingBuilding.toTransport = buildingAtCell
						print("Linked belt ", linkingBuilding, " with building ", buildingAtCell, " at ", cell)
						linkingBuilding = null
						return
			if hasBelt:
				if Belt in linkingBuilding.validOutputBuildings:
					linkingBuilding.toTransport = beltAtCell
					print("Linked building ", linkingBuilding, " with belt ", beltAtCell)
					linkingBuilding = null
			if linkingBuilding: print("Not able to link this building.")
			linkingBuilding = null
		else:
			if hasBuilding:
				linkingBuilding = buildingAtCell
				print("Linking object ", buildingAtCell, " at ", cell)
			if hasBelt:
				linkingBuilding = beltAtCell
				print("Linking belt ", beltAtCell, " at ", cell)
				
	if event.is_action_pressed("cycleUp") or event.is_action_pressed("cycleDown"):
		preview.changePreview(event, false)
		print("Cycling.. current building number is ", preview.cycleNum)
	
	if event.is_action_pressed("debug"):
		if hasBuilding:
			print("Building type: ", typeof(buildingAtCell), ", input inventory: ", buildingAtCell.inputInventory," output inventory: ", buildingAtCell.outputInventory)

func calculateBeltPath(start: Vector2i, end: Vector2i) -> Array:
	var pathCells = []
	var targetEnd = end
	
	if abs(end.x - start.x) >= abs(end.y - start.y):
		targetEnd.y = start.y
	else:
		targetEnd.x = start.x
		
	var current = start
	pathCells.append([current, 0.0])
	
	while current != targetEnd:
		if current.x != targetEnd.x:
			current.x += sign(targetEnd.x - current.x)
		elif current.y != targetEnd.y:
			current.y += sign(targetEnd.y - current.y)
		pathCells.append([current, 0.0])
		
	for i in range(pathCells.size()):
		var c = pathCells[i][0]
		var dir = 0.0
		if i < pathCells.size() - 1:
			var nextCell = pathCells[i + 1][0]
			dir = getRotationFromVector(nextCell - c)
		else:
			if pathCells.size() > 1:
				var prevCell = pathCells[i - 1][0]
				dir = getRotationFromVector(c - prevCell)
		pathCells[i][1] = dir
		
	return pathCells

func getRotationFromVector(v: Vector2i) -> float:
	if v == Vector2i(1, 0): return 0.0
	elif v == Vector2i(0, 1): return 90.0
	elif v == Vector2i(-1, 0): return 180.0
	elif v == Vector2i(0, -1): return 270.0
	return 0.0
