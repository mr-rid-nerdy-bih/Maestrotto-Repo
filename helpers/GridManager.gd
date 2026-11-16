extends Node

const CELL_SIZE: float = 16.0

@onready var game = get_tree().current_scene
@onready var cam = game.get_node("Camera2D")
@onready var beltLayer = game.get_node("TileMapLayer")

var grid = {}
var belts = {}
var scenes = {"NoteDrill": preload("uid://noy2ufrybire"),
			  "Packager":  preload("uid://dfh8b07mvb7o3")}
var beltScene = preload("uid://b77a1shbdt0jj")

func _ready() -> void:
	TimeGlobal.ticked.connect(_on_tick)

func get_coords_at(pos):
	var localPos = beltLayer.to_local(pos)
	return beltLayer.local_to_map(localPos)

func get_building_at(cell):
	if not grid.has(cell):
		print("Cell at grid is unoccupied")
		return
	var machine = grid[cell]
	if not is_instance_valid(machine):
		grid.erase(cell)
		return
	return machine

func get_belt_at(cell):
	if not belts.has(cell):
		print("Cell has no belt.")
		return
	var belt = belts[cell]
	return belt

func get_new_building(building):
	return scenes.get(building).instantiate()

func has_machine_at(cell):
	if not grid.has(cell):
		return false
	if not is_instance_valid(grid[cell]):
		grid.erase(cell)
		return false
	return true

func has_belt_at(cell):
	if not belts.has(cell):
		return false
	return true

func place_machine_at(building, cell):
	if not scenes.has(building):
		print("Oi bruv theres no building named ", building)
		return
	if grid.has(cell) and is_instance_valid(grid[cell]):
		grid[cell].queue_free()
	var newBuilding = scenes.get(building).instantiate()
	newBuilding.cell = cell
	newBuilding.tickBirth = TimeGlobal.tick
	newBuilding.global_position = Vector2(cell) * GridManager.CELL_SIZE
	game.add_child(newBuilding)
	grid[cell] = newBuilding

func place_belt_at(cell, dir):
	if belts.has(cell) and is_instance_valid(belts[cell]):
		belts[cell].queue_free()
		
	var newBelt = beltScene.instantiate()
	newBelt.cell = cell
	newBelt.rotation_degrees = dir
	newBelt.global_position = Vector2(cell) * GridManager.CELL_SIZE
	
	belts[cell] = newBelt
	print("Placed belt at ", cell)

func _on_tick():
	var keysToRemove = []
	for cell in belts.keys():
		var belt = belts[cell]
		if not is_instance_valid(belt):
			keysToRemove.append(cell)
			continue
		if beltLayer.get_cell_source_id(belt.cell) == -1:
			beltLayer.set_cell(belt.cell, 1, belt.get_coords())
			game.add_child(belt)
			print("Belt placed at ", belt.cell)
	for cell in keysToRemove:
		belts.erase(cell)
