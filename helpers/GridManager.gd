extends Node

const CELL_SIZE: float = 16.0

@onready var game := get_tree().current_scene
@onready var cam := game.get_node("Camera2D")
@onready var beltLayer := game.get_node("TileMapLayer")

var grid := {}
var beltNodes: Array = []
var buildingScene := preload("uid://b3y5h2c174ykj")
var beltScene := preload("uid://dccu7jyorgrny")
var buildingResources: Dictionary[int, BuildingResource] = {}

var highlight := false
var hoveredCell: Vector2i = Vector2i(-1, -1)
var mouseRange := 50

func _ready() -> void:
	TimeGlobal.ticked.connect(_on_tick)
	
	var path := "res://objects/machines/"
	if DirAccess.dir_exists_absolute(path):
		for file in DirAccess.get_files_at(path):
			var cleanFile := file.trim_suffix(".remap").trim_suffix(".import")
			if not (cleanFile.ends_with(".tres") or cleanFile.ends_with(".res")):
				continue
			var loaded := load(path.path_join(cleanFile))
			if loaded is BuildingResource:
				buildingResources[loaded.buildingType] = loaded

func get_new_building(building: BuildingTypes.Type) -> Building:
	if building == BuildingTypes.Type.NONE:
		return null
	if not buildingResources.has(building):
		push_warning("BuildingResource not found in buildingResources for type: %s" % building)
		return null
	var newBuilding: Building = buildingScene.instantiate()
	newBuilding.buildingResource = buildingResources[building]
	return newBuilding

func get_coords_at(pos: Vector2) -> Vector2i:
	var localPos: Vector2 = beltLayer.to_local(pos)
	return beltLayer.local_to_map(localPos)

func get_global_at(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE

func get_building_at(cell: Vector2i) -> Building:
	if not grid.has(cell):
		return null
	
	var obj: Building = grid[cell]
	if not is_instance_valid(obj):
		grid.erase(cell)
		return null
	
	if obj is Building:
		return obj
	
	return null

func get_belt_at(cell: Vector2i) -> Building:
	for obj: Building in grid.values():
		if not is_instance_valid(obj) or !(obj.type and obj.type == BuildingTypes.Type.BELT):
			continue
		for entry: Dictionary in obj.belts:
			if entry.cell == cell:
				return obj
	
	return null

func has_building_at(cell: Vector2i) -> bool:
	return get_building_at(cell) != null

func has_machine_at(cell: Vector2i) -> bool:
	return has_building_at(cell)

func has_belt_at(cell: Vector2i) -> bool:
	return get_belt_at(cell) != null

func place_building_at(building_data, cell: Vector2i, dir: Vector2 = Vector2.RIGHT) -> void:
	var buildingType: BuildingTypes.Type
	var facingDir: Vector2 = dir
	
	if building_data is Dictionary:
		buildingType = building_data.get("type", BuildingTypes.Type.NONE)
		facingDir = building_data.get("dir", dir)
	elif building_data is BuildingTypes.Type or typeof(building_data) == TYPE_INT:
		buildingType = building_data as BuildingTypes.Type
	else:
		push_error("Invalid building argument passed to place_building_at: %s" % [building_data])
		return
	
	if buildingType == BuildingTypes.Type.NONE:
		push_warning("Attempted to place BuildingTypes.Type.NONE at %s" % [cell])
		return
	
	if not buildingResources.has(buildingType):
		push_error("Missing BuildingResource for type: %s" % [buildingType])
		return
	
	erase_building_at(cell)
	erase_belt_at(cell)
	
	var newBuilding: Building = buildingScene.instantiate()
	newBuilding.buildingResource = buildingResources[buildingType]
	if "type" in newBuilding:
		newBuilding.type = buildingType
	if "cell" in newBuilding:
		newBuilding.cell = cell
	if "tickBirth" in newBuilding:
		newBuilding.tickBirth = TimeGlobal.tick
	
	if "visualComponent" in newBuilding and newBuilding.visualComponent:
		newBuilding.visualComponent.cell = cell
		newBuilding.visualComponent.dir = facingDir
		newBuilding.visualComponent.isPreview = false
		newBuilding.visualComponent.set_sprite()
		newBuilding.visualComponent.set_pos()
	
	game.add_child(newBuilding)
	grid[cell] = newBuilding

func erase_building_at(cell: Vector2i) -> void:
	if grid.has(cell):
		var obj = grid[cell]
		if is_instance_valid(obj) and obj is Building:
			if not ("type" in obj and obj.type == BuildingTypes.Type.BELT):
				obj.queue_free()
		grid.erase(cell)

func place_belt_at(cell: Vector2i, cell1: Vector2i) -> void:
	erase_building_at(cell)
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
	grid[cell] = newBelt
	print("Placed belt spanning from ", cell, " to ", cell1)

func erase_belt_at(cell: Vector2i) -> void:
	var belt = get_belt_at(cell)
	if belt and is_instance_valid(belt):
		var cellsToRemove: Array[Vector2i] = []
		
		if "belts" in belt and belt.belts is Array:
			for entry in belt.belts:
				if entry is Dictionary and entry.has("cell"):
					var beltCell := Vector2i(entry["cell"])
					cellsToRemove.append(beltCell)
					beltLayer.erase_cell(beltCell)
		
		if "cell" in belt and belt.cell is Vector2i and not cellsToRemove.has(belt.cell):
			cellsToRemove.append(belt.cell)
		
		for key: Vector2i in grid.keys():
			if grid[key] == belt or cellsToRemove.has(key):
				grid.erase(key)
		
		belt.queue_free()
		print("Erased belt containing cell: ", cell)

func is_straight(cellA: Vector2i, cellB: Vector2i) -> bool:
	var diff := cellB - cellA
	return diff.x == 0 or diff.y == 0

func _on_tick() -> void:
	var invalidKeys: Array = []
	for key in grid.keys():
		if not is_instance_valid(grid[key]):
			invalidKeys.append(key)
	for key in invalidKeys:
		grid.erase(key)
