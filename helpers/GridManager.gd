extends Node

const CELL_SIZE: float = 16.0

@onready var game := get_tree().current_scene
@onready var cam := game.get_node("Camera2D")
@onready var beltLayer := game.get_node("TileMapLayer")

var grid :=  {}
var beltNodes: Array = []
var buildingScene := preload("uid://b3y5h2c174ykj")
var beltScene := preload("uid://dccu7jyorgrny")
var buildingResources: Dictionary[int, BuildingResource] = {}

var highlight := false
var mouseRange := 50

func _ready() -> void:
	TimeGlobal.ticked.connect(_on_tick)
	
	var path := "res://objects/machines/"
	if DirAccess.dir_exists_absolute(path):
		for file in DirAccess.get_files_at(path):
			var clean_file := file.trim_suffix(".remap").trim_suffix(".import")
			if not (clean_file.ends_with(".tres") or clean_file.ends_with(".res")):
				continue
			var loaded := load(path.path_join(clean_file))
			if loaded is BuildingResource:
				buildingResources[loaded.buildingType] = loaded

func get_new_building(building: BuildingTypes.Type):
	if building == BuildingTypes.Type.NONE:
		return null
	if not buildingResources.has(building):
		push_warning("BuildingResource not found in buildingResources for type: %s" % building)
		return null
	var newBuilding := buildingScene.instantiate()
	newBuilding.buildingResource = buildingResources[building]
	
	return newBuilding

func get_coords_at(pos):
	var localPos := beltLayer.to_local(pos)
	return beltLayer.local_to_map(localPos)

func get_global_at(cell: Vector2i):
	return Vector2(cell * CELL_SIZE)

func get_building_at(cell: Vector2i):
	if not grid.has(cell):
		return null
	
	var building := grid[cell]
	if not is_instance_valid(building):
		grid.erase(cell)
		return null
	
	return building

func get_belt_at(cell: Vector2i):
	for belt in grid.values():
		if !is_instance_valid(belt):
			continue
		if belt.type != BuildingTypes.Type.BELT:
			continue
	
		for entry in belt.belts:
			if Vector2i(entry["cell"]) == cell:
				return belt
	
	return null

func has_building_at(cell: Vector2i):
	if not grid.has(cell):
		return false
	if not is_instance_valid(grid[cell]):
		grid.erase(cell)
		return false
	return true

func has_belt_at(cell: Vector2i):
	return get_belt_at(cell) != null

func place_building_at(building: BuildingTypes.Type, cell, dir: bool = false) -> void:
	if !building:
		push_error("Building null")
		return
	erase_building_at(cell)
	
	var newBuilding: Building = buildingScene.instantiate()
	newBuilding.buildingResource = buildingResources[building]
	newBuilding.visualComponent.cell = cell
	newBuilding.visualComponent.dir = dir
	newBuilding.tickBirth = TimeGlobal.tick
	newBuilding.visualComponent.set_pos()
	game.add_child(newBuilding)
	grid[cell] = newBuilding

func erase_building_at(cell: Vector2i) -> void:
	if grid.has(cell) and is_instance_valid(grid[cell]):
		grid[cell].queue_free()
		grid.erase(cell)

func place_belt_at(cell: Vector2i, cell1: Vector2i) -> void:
	erase_belt_at(cell)
	erase_belt_at(cell1)
	
	var newBelt := beltScene.instantiate()
	if "cell" in newBelt:
		newBelt.cell = cell
	if "cell1" in newBelt:
		newBelt.cell1 = cell1
	if "buildingResource" in newBelt and buildingResources.has(BuildingTypes.Type.BELT):
		newBelt.buildingResource = buildingResources[BuildingTypes.Type.BELT]
	
	game.add_child(newBelt)
	grid[cell] = (newBelt)
	print("Placed belt spanning from ", cell, " to ", cell1)

func erase_belt_at(cell: Vector2i) -> void:
	var belt := get_belt_at(cell)
	if belt and is_instance_valid(belt):
		for entry in belt.belts:
			beltLayer.erase_cell(entry.cell)
		grid.erase(belt)
		belt.queue_free()
		print("Erased belt containing cell: ", cell)

func is_straight(cellA: Vector2i, cellB: Vector2i) -> bool:
	var diff := cellB - cellA
	
	var isStraight := (diff.x == 0 or diff.y == 0)
	
	return isStraight

func _on_tick() -> void:
	beltNodes = beltNodes.filter(func(b): return is_instance_valid(b))
