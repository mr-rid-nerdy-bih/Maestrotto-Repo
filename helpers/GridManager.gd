extends Node

const CELL_SIZE: float = 16.0

@onready var game = get_tree().current_scene
@onready var cam = game.get_node("Camera2D")
@onready var beltLayer = game.get_node("TileMapLayer")

var grid = {}
var belt_nodes: Array = [] # Stores references to active Line2D Belt nodes
var scenes = {
	"NoteDrill": preload("uid://noy2ufrybire"),
	"Packager": preload("uid://dfh8b07mvb7o3"),
	"Chute": preload("uid://cg55wwh43ukct"),
	"CopperCanister": preload("uid://bnyw62cylevfh"),
}
var beltScene = preload("uid://dccu7jyorgrny")

func _ready() -> void:
	TimeGlobal.ticked.connect(_on_tick)

func get_new_building(building):
	if not scenes.has(building):
		print("No building named ", building)
		return null
	return scenes.get(building).instantiate()

func get_coords_at(pos):
	var localPos = beltLayer.to_local(pos)
	return beltLayer.local_to_map(localPos)

func get_global_at(cell):
	return cell * CELL_SIZE

func get_building_at(cell):
	if not grid.has(cell):
		return null
	var machine = grid[cell]
	if not is_instance_valid(machine):
		grid.erase(cell)
		return null
	return machine

func get_belt_at(cell):
	for belt in belt_nodes:
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

func place_building_at(building, cell):
	if not scenes.has(building):
		print("No building named ", building)
		return
	if grid.has(cell) and is_instance_valid(grid[cell]):
		grid[cell].queue_free()
	var newBuilding = scenes.get(building).instantiate()
	newBuilding.cell = cell
	newBuilding.tickBirth = TimeGlobal.tick
	newBuilding.global_position = Vector2(cell) * CELL_SIZE
	game.add_child(newBuilding)
	grid[cell] = newBuilding

func erase_building_at(cell):
	if grid.has(cell) and is_instance_valid(grid[cell]):
		grid[cell].queue_free()
		grid.erase(cell)

func place_belt_at(cell, cell1):
	if has_belt_at(cell): 
		var belt = get_belt_at(cell)
		if is_instance_valid(belt): belt.queue_free()
	if has_belt_at(cell1): 
		var belt = get_belt_at(cell1)
		if is_instance_valid(belt): belt.queue_free()
		
	var newBelt = beltScene.instantiate()
	newBelt.cell = cell
	newBelt.cell1 = cell1
	
	game.add_child(newBelt)
	belt_nodes.append(newBelt)
	print("Placed belt spanning from ", cell, " to ", cell1)

func erase_belt_at(cell):
	var belt = get_belt_at(cell)
	if belt and is_instance_valid(belt):
		# Clear tiles from the tilemap layer before freeing
		for entry in belt.belts:
			beltLayer.erase_cell(entry["cell"])
		belt_nodes.erase(belt)
		belt.queue_free()
		print("Erased belt containing cell: ", cell)

func _on_tick():
	belt_nodes = belt_nodes.filter(func(b): return is_instance_valid(b))
