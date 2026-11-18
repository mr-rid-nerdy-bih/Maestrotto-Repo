extends Node

const CELL_SIZE: float = 16.0

@onready var game = get_tree().current_scene
@onready var cam = game.get_node("Camera2D")
@onready var beltLayer = game.get_node("TileMapLayer")

var grid = {}
var beltNodes: Array = []
var buildingScene = preload("uid://b3y5h2c174ykj")
var beltScene = preload("uid://dccu7jyorgrny")
var buildingResources: Dictionary[BuildingTypes.Type, BuildingResource] = {}

var highlight = false

func _ready() -> void:
	TimeGlobal.ticked.connect(_on_tick)
	
	var path = "res://objects/machines/"
	for file in DirAccess.get_files_at(path):
		file = file.trim_suffix(".remap").trim_suffix(".import")
		var resource: BuildingResource = load(path.path_join(file))
		var type = resource.building_type
		buildingResources[type] = resource

func get_new_building(building: BuildingTypes.Type):
	if !building:
		print("Sum happened")
		return null
	var newBuilding = buildingScene.instantiate()
	newBuilding.buildingResource = buildingResources[building]
	
	return newBuilding

func get_coords_at(pos):
	var localPos = beltLayer.to_local(pos)
	return beltLayer.local_to_map(localPos)

func get_global_at(cell):
	return Vector2(cell * CELL_SIZE)

func get_building_at(cell):
	if not grid.has(cell):
		return null
	var machine = grid[cell]
	if not is_instance_valid(machine):
		grid.erase(cell)
		return null
	return machine

func get_belt_at(cell):
	for belt in beltNodes:
		if not is_instance_valid(belt):
			continue
		for entry in belt.belts:
			if Vector2i(entry["cell"]) == cell:
				return belt
	return null

func has_machine_at(cell):
	if not grid.has(cell):
		return false
	if not is_instance_valid(grid[cell]):
		grid.erase(cell)
		return false
	return true

func has_belt_at(cell):
	return get_belt_at(cell) != null

func place_building_at(building: BuildingTypes.Type, cell, dir: bool = false):
	if !building:
		push_error("Building null")
		return
	if grid.has(cell) and is_instance_valid(grid[cell]):
		grid[cell].queue_free()
		
	var newBuilding: Building = buildingScene.instantiate()
	newBuilding.buildingResource = buildingResources[building]
	newBuilding.visualComponent.cell = cell
	newBuilding.visualComponent.dir = dir
	newBuilding.tickBirth = TimeGlobal.tick
	newBuilding.visualComponent.set_pos()
	game.add_child(newBuilding)
	grid[cell] = newBuilding

func erase_building_at(cell):
	if grid.has(cell) and is_instance_valid(grid[cell]):
		grid[cell].queue_free()
		grid.erase(cell)

func place_belt_at(cell, cell1):
	for i in range(1): pass
	if has_belt_at(cell): 
		var belt = get_belt_at(cell)
		if is_instance_valid(belt): belt.queue_free()
	if has_belt_at(cell1): 
		var belt = get_belt_at(cell1)
		if is_instance_valid(belt): belt.queue_free()
	
	if !cell1: print("boi")
	var newBelt = beltScene.instantiate()
	newBelt.cell = cell
	newBelt.cell1 = cell1
	
	game.add_child(newBelt)
	beltNodes.append(newBelt)
	print("Placed belt spanning from ", cell, " to ", cell1)

func erase_belt_at(cell):
	var belt = get_belt_at(cell)
	if belt and is_instance_valid(belt):
		# Clear tiles from the tilemap layer before freeing
		for entry in belt.belts:
			beltLayer.erase_cell(entry["cell"])
		beltNodes.erase(belt)
		belt.queue_free()
		print("Erased belt containing cell: ", cell)

func is_straight(cellA: Vector2i, cellB: Vector2i) -> bool:
	var diff = cellB - cellA
	
	var isStraight = (diff.x == 0 or diff.y == 0)
	
	return isStraight

func _on_tick():
	beltNodes = beltNodes.filter(func(b): return is_instance_valid(b))
