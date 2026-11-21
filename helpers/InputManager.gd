extends Node

var worldMousePos
var cell
var hasBuilding
var hasBelt
var buildingAtCell: Building
var beltAtCell: Belt
var buildStart: Vector2i
var isBuildingDragged: bool = false

var linkingBuilding
var beltStart: Vector2i
var empty = Vector2i(197256439047,71209164509346)
var isDraggingBelt: bool = false

@onready var preview: Node2D = get_tree().current_scene.get_node("Preview")
@onready var toolBox: Control = get_tree().current_scene.get_node("CanvasLayer/Control/HBoxContainer")

var unselectedColor = Color(0.278, 0.278, 0.278, 0.671)
var selectedColor = Color(0.121, 0.81, 0.121, 0.8)
var currentMode = 0

func _process(delta: float) -> void:
	if currentMode != 0:
		GridManager.highlight = true
	else:
		GridManager.highlight = false

func _unhandled_input(event: InputEvent) -> void:
	worldMousePos = GridManager.cam.get_global_mouse_position()
	cell = GridManager.get_coords_at(worldMousePos)
	hasBuilding = GridManager.has_machine_at(cell)
	if hasBuilding: buildingAtCell = GridManager.get_building_at(cell)
	
	if event.is_action_pressed("build"):
		if currentMode == 1:
			currentMode = 0
		else: currentMode = 1
	
	if event.is_action_pressed("erase"):
		if currentMode == 2:
			currentMode = 0
		else: currentMode = 2
	
	if event.is_action_pressed("link"):
		if currentMode == 3:
			currentMode = 0
		else: currentMode = 3
	
	setSelected()
	
	match currentMode:
		1: buildFunc(event)
		2: eraseFunc(event)
		3: linkFunc(event)

	
	if event.is_action_pressed("cycleUp") or event.is_action_pressed("cycleDown"):
		preview.changePreview(event, false)
		print("Cycling.. current building number is ", preview.cycleNum)
	
	if event.is_action_pressed("flip"):
		if currentMode == 1 and not hasBuilding:
			preview.changePreview(event, false)
		elif hasBuilding:
			buildingAtCell.visualComponent.dir = !buildingAtCell.visualComponent.dir
			buildingAtCell.visualComponent.set_sprite()
	
	if event.is_action_pressed("debug"):
		if hasBuilding:
			print("Building type: ", buildingAtCell.type, ", input inventory: ", buildingAtCell.inventoryComponent.inputInventory," output inventory: ", buildingAtCell.inventoryComponent.outputInventory)

func calculateBeltPath(start: Vector2i, end: Vector2i) -> Dictionary:
	var isStraight = (start.x == end.x or start.y == end.y)
	
	if isStraight:
		var beltCells = []
		var current = start
		beltCells.append([current, 0.0])
		
		while current != end:
			if current.x != end.x:
				current.x += sign(end.x - current.x)
			elif current.y != end.y:
				current.y += sign(end.y - current.y)
			beltCells.append([current, 0.0])
			
		# Calculate rotations for straight path
		for i in range(beltCells.size()):
			var c = beltCells[i][0]
			var dir = 0.0
			if i < beltCells.size() - 1:
				var nextCell = beltCells[i + 1][0]
				dir = getRotationFromVector(nextCell - c)
			else:
				if beltCells.size() > 1:
					var prevCell = beltCells[i - 1][0]
					dir = getRotationFromVector(c - prevCell)
			beltCells[i][1] = dir
			
		return {
			"pathCells": [beltCells],
			"cornerCell": null
		}
	else:
		var cornerCell = Vector2i(end.x, start.y)
		
		# First segment: start to cornerCell
		var beltCells = []
		var current = start
		beltCells.append([current, 0.0])
		while current != cornerCell:
			if current.x != cornerCell.x:
				current.x += sign(cornerCell.x - current.x)
			elif current.y != cornerCell.y:
				current.y += sign(cornerCell.y - current.y)
			beltCells.append([current, 0.0])
			
		# Second segment: cornerCell to end
		var beltCells1 = []
		current = cornerCell
		beltCells1.append([current, 0.0])
		while current != end:
			if current.x != end.x:
				current.x += sign(end.x - current.x)
			elif current.y != end.y:
				current.y += sign(end.y - current.y)
			beltCells1.append([current, 0.0])
			
		# Calculate rotations for first segment
		for i in range(beltCells.size()):
			var c = beltCells[i][0]
			var dir = 0.0
			if i < beltCells.size() - 1:
				var nextCell = beltCells[i + 1][0]
				dir = getRotationFromVector(nextCell - c)
			else:
				if beltCells1.size() > 0:
					dir = getRotationFromVector(beltCells1[0][0] - c)
			beltCells[i][1] = dir
			
		# Calculate rotations for second segment
		for i in range(beltCells1.size()):
			var c = beltCells1[i][0]
			var dir = 0.0
			if i < beltCells1.size() - 1:
				var nextCell = beltCells1[i + 1][0]
				dir = getRotationFromVector(nextCell - c)
			else:
				if beltCells1.size() > 1:
					var prevCell = beltCells1[i - 1][0]
					dir = getRotationFromVector(c - prevCell)
				elif beltCells.size() > 0:
					var prevCell = beltCells[beltCells.size() - 1][0]
					dir = getRotationFromVector(c - prevCell)
			beltCells1[i][1] = dir
		beltCells1.erase(0)
		
		return {
			"pathCells": [beltCells, beltCells1],
			"cornerCell": cornerCell
		}

func getRotationFromVector(v: Vector2i) -> float:
	if v == Vector2i(1, 0): return 0.0
	elif v == Vector2i(0, 1): return 90.0
	elif v == Vector2i(-1, 0): return 180.0
	elif v == Vector2i(0, -1): return 270.0
	return 0.0

func setSelected():
	for i in range(toolBox.get_child_count()):
		var panel = toolBox.get_child(i)
		
		if currentMode == i + 1:
			panel.get_theme_stylebox("panel").bg_color = selectedColor
		else:
			panel.get_theme_stylebox("panel").bg_color = unselectedColor

func buildFunc(event):
	if event.is_shift_pressed():
		var pathCells = calculateBeltPath(beltStart, cell)
		if event.is_action_pressed("confirmTile") and event.is_pressed():
			beltStart = cell
			isDraggingBelt = true
			preview.belt(pathCells["pathCells"], true)
			print("STARTED DRAG at cell: ", beltStart)
			return
		
		if event is InputEventMouseMotion and isDraggingBelt:
			if beltStart:
				preview.belt(pathCells["pathCells"], true)
		
		if event.is_action_released("confirmTile") and isDraggingBelt:
			isDraggingBelt = false
			preview.belt([], false)
			if beltStart:
				if pathCells["cornerCell"]:
					GridManager.place_belt_at(beltStart, cell)
				else:
					GridManager.place_belt_at(beltStart, cell)
			beltStart = empty
			return
		return
	
	if event.is_action_pressed("confirmTile") and event.is_pressed():
		isBuildingDragged = true
		placeBuildingAtCurrentCell()
		return
		
	if event.is_action_released("confirmTile"):
		isBuildingDragged = false
		return
		
	# When the mouse moves while holding down the mouse button
	if event is InputEventMouseMotion and isBuildingDragged:
		placeBuildingAtCurrentCell()

func placeBuildingAtCurrentCell():
	var currentBuilding = preview.getCurrentBuilding()
	var currentBuildingType = currentBuilding.class
	var currentBuildingDir = currentBuilding.dir
	if currentBuildingType and not GridManager.has_machine_at(cell):
		GridManager.place_building_at(currentBuildingType, cell, currentBuildingDir)
		print("Placed building (", currentBuildingType, ") at ", cell)

func eraseFunc(event):
	if event.is_action_pressed("confirmTile") and event.is_pressed():
		isBuildingDragged = true
		GridManager.erase_building_at(cell)
		GridManager.erase_belt_at(cell)
		return
		
	if event.is_action_released("confirmTile"):
		isBuildingDragged = false
		return
		
	# When the mouse moves while holding down the mouse button
	if event is InputEventMouseMotion and isBuildingDragged:
		GridManager.erase_building_at(cell)
		GridManager.erase_belt_at(cell)

func linkFunc(event):
	if !event.is_pressed() or !event.is_action("confirmTile"):
		return
	
	if linkingBuilding:
		if hasBuilding:
			if linkingBuilding is Building:
				if linkingBuilding.transportComponent.toTransport == buildingAtCell:
					linkingBuilding.link_to_building(null)
					linkingBuilding = null
					print("unlink")
					return
				
				if buildingAtCell.buildingResource.buildingType in linkingBuilding.buildingResource.validOutputBuildings:
					linkingBuilding.link_to_building(buildingAtCell)
					print("Linked building ", linkingBuilding, " with building ", buildingAtCell, " at ", cell)
					linkingBuilding = null
					return
		if linkingBuilding: print("Not able to link this building.")
		linkingBuilding = null
	else:
		if hasBuilding:
			linkingBuilding = buildingAtCell
			print("Linking object ", buildingAtCell, " at ", cell)
