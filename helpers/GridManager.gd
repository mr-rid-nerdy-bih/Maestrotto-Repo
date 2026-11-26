extends Node
## Autoload that owns the grid: which building sits on which cell,
## plus placing, erasing and looking up buildings and belts.

## Size of one grid cell in pixels.
const CELL_SIZE: float = 16.0

@onready var game := get_tree().current_scene
@onready var player: CharacterBody2D = game.find_child("Player")
@onready var cam: Camera2D = player.get_node("Camera2D")
@onready var beltLayer: TileMapLayer = game.get_node("TileMapLayer")

## Cell -> Building. Machines are stored on every cell they cover;
## belts only at their start cell.
var grid := {}
var beltNodes: Array = []
var buildingScene := preload("uid://b3y5h2c174ykj")
var beltScene := preload("uid://dccu7jyorgrny")
## Every BuildingResource in res://objects/machines/, keyed by building type.
var buildingResources: Dictionary[int, BuildingResource] = {}

## True while a tool mode is active; buildings near the mouse fade out.
var highlight := false
var hoveredCell: Vector2i = Vector2i(-1, -1)
## Pixel radius around the mouse where buildings fade while highlighting.
var mouseRange := 25

## Y-sorted container for machines: they draw above belts/items (z band),
## and lower rows draw in front of higher rows (y-sort).
var buildingsNode: Node2D

## Creates the Buildings container and loads every BuildingResource.
func _ready() -> void:
	cam = player.get_node("Camera2D")
	
	TimeGlobal.ticked.connect(on_tick)

	buildingsNode = game.get_node_or_null("Buildings")
	if buildingsNode == null:
		buildingsNode = Node2D.new()
		buildingsNode.name = "Buildings"
		game.add_child.call_deferred(buildingsNode)
	buildingsNode.y_sort_enabled = true
	buildingsNode.z_index = ZLayers.MACHINE
	
	var path := "res://objects/machines/"
	if DirAccess.dir_exists_absolute(path):
		for file in DirAccess.get_files_at(path):
			var cleanFile := file.trim_suffix(".remap").trim_suffix(".import")
			if not (cleanFile.ends_with(".tres") or cleanFile.ends_with(".res")):
				continue
			var loaded := load(path.path_join(cleanFile))
			if loaded is BuildingResource:
				buildingResources[loaded.buildingType] = loaded

## Makes a building of [param building] type without placing it (used by the preview).
func get_new_building(building: BuildingTypes.Type) -> Building:
	if building == BuildingTypes.Type.NONE:
		return null
	if not buildingResources.has(building):
		push_warning("BuildingResource not found in buildingResources for type: %s" % building)
		return null
	var newBuilding: Building = buildingScene.instantiate()
	newBuilding.buildingResource = buildingResources[building]
	return newBuilding

## World position -> grid cell.
func get_coords_at(pos: Vector2) -> Vector2i:
	var localPos: Vector2 = beltLayer.to_local(pos)
	return beltLayer.local_to_map(localPos)

## Grid cell -> world position of its top-left corner.
func get_global_at(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE

## The building registered at [param cell], or null. Cleans up freed entries.
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

## The belt covering [param cell] (any cell along it, not just the start), or null.
func get_belt_at(cell: Vector2i) -> Building:
	for obj in grid.values():
		if not is_instance_valid(obj) or !(obj.type and obj.type == BuildingTypes.Type.BELT):
			continue
		for entry: Dictionary in obj.belts:
			if entry.cell == cell:
				return obj
	
	return null

func has_building_at(cell: Vector2i) -> bool:
	return get_building_at(cell) != null

## Same as has_building_at; kept for readability at call sites.
func has_machine_at(cell: Vector2i) -> bool:
	return has_building_at(cell)

func has_belt_at(cell: Vector2i) -> bool:
	return get_belt_at(cell) != null

## Places a machine. [param buildingData] is a BuildingTypes.Type or a
## {type, dir} Dictionary. Replaces whatever was on the cell.
func place_building_at(buildingData, cell: Vector2i, dir: Vector2 = Vector2.RIGHT) -> void:
	var buildingType: BuildingTypes.Type
	var facingDir: Vector2 = dir
	
	if buildingData is Dictionary:
		buildingType = buildingData.get("type", BuildingTypes.Type.NONE)
		facingDir = buildingData.get("dir", dir)
	elif buildingData is BuildingTypes.Type or typeof(buildingData) == TYPE_INT:
		buildingType = buildingData as BuildingTypes.Type
	else:
		push_error("Invalid building argument passed to place_building_at: %s" % [buildingData])
		return
	
	if buildingType == BuildingTypes.Type.NONE:
		push_warning("Attempted to place BuildingTypes.Type.NONE at %s" % [cell])
		return
	
	if not buildingResources.has(buildingType):
		push_error("Missing BuildingResource for type: %s" % [buildingType])
		return

	# Clear every cell the new building will cover.
	var footprint := get_footprint_cells(cell, buildingResources[buildingType].size)
	for c: Vector2i in footprint:
		erase_belt_at(c)
		erase_building_at(c)

	var newBuilding: Building = buildingScene.instantiate()
	newBuilding.buildingResource = buildingResources[buildingType]
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
	
	buildingsNode.add_child(newBuilding)
	# Register the building on every cell it covers, so clicking any part of it works.
	for c: Vector2i in footprint:
		grid[c] = newBuilding

## Every cell covered by a building of [param size] placed at [param origin].
func get_footprint_cells(origin: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in maxi(size.x, 1):
		for y in maxi(size.y, 1):
			cells.append(origin + Vector2i(x, y))
	return cells

## True if a [param buildingType] building at [param cell] wouldn't overlap
## another machine. Belts don't block; placing over them replaces them.
func can_place_building(buildingType: BuildingTypes.Type, cell: Vector2i) -> bool:
	if not buildingResources.has(buildingType):
		return false
	for c: Vector2i in get_footprint_cells(cell, buildingResources[buildingType].size):
		var obj := get_building_at(c)
		if obj and obj.type != BuildingTypes.Type.BELT:
			return false
	return true

## Removes the machine covering [param cell] (all of its cells).
## Belts are skipped; use erase_belt_at.
func erase_building_at(cell: Vector2i) -> void:
	if not grid.has(cell):
		return
	var obj: Variant = grid[cell]
	if not is_instance_valid(obj) or not obj is Building:
		grid.erase(cell)
		return
	# Leave belts completely alone. Dropping just their grid entry here used
	# to orphan them (still running, but unfindable), so erase_belt_at
	# is the only thing that removes a belt.
	if obj.type == BuildingTypes.Type.BELT:
		return
	for key: Vector2i in grid.keys():
		if grid[key] == obj:
			grid.erase(key)
	obj.queue_free()

## Places a straight belt from [param cell] to [param cell1], clearing
## everything along its path first.
func place_belt_at(cell: Vector2i, cell1: Vector2i) -> void:
	# Clear EVERY cell the belt will cover, not just the ends — otherwise
	# machines under the middle of the belt get orphaned ("ghosts").
	var step := Vector2i(signi(cell1.x - cell.x), signi(cell1.y - cell.y))
	var c := cell
	while true:
		erase_belt_at(c)
		erase_building_at(c)
		if c == cell1 or step == Vector2i.ZERO:
			break
		c += step
	
	var newBelt := beltScene.instantiate()
	if "cell" in newBelt:
		newBelt.cell = cell
	if "cell1" in newBelt:
		newBelt.cell1 = cell1
	if "buildingResource" in newBelt and buildingResources.has(BuildingTypes.Type.BELT):
		newBelt.buildingResource = buildingResources[BuildingTypes.Type.BELT]

	newBelt.z_index = ZLayers.BELT
	game.add_child(newBelt)
	grid[cell] = newBelt
	print("Placed belt spanning from ", cell, " to ", cell1)

## Removes the whole belt that covers [param cell], including its tiles.
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
			# Only remove entries that ARE this belt; never drop another building's entry.
			if grid[key] == belt:
				grid.erase(key)
		
		belt.queue_free()
		print("Erased belt containing cell: ", cell)

## True if the two cells share a row or a column.
func is_straight(cellA: Vector2i, cellB: Vector2i) -> bool:
	var diff := cellB - cellA
	return diff.x == 0 or diff.y == 0

## Drops grid entries whose building has been freed.
func on_tick() -> void:
	var invalidKeys: Array = []
	for key in grid.keys():
		if not is_instance_valid(grid[key]):
			invalidKeys.append(key)
	for key in invalidKeys:
		grid.erase(key)
