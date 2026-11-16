extends Node2D

var cycleNum = 0
var isBelting = false

@onready var beltGroup: Node2D = $Belt
@onready var machinesGroup: Node2D = $Machines

func _ready() -> void:
	beltGroup.top_level = true
	changePreview(0, true)

func _process(delta: float) -> void:
	var pos = GridManager.get_coords_at(GridManager.cam.get_global_mouse_position())
	global_position = pos * GridManager.CELL_SIZE
	
	if isBelting:
		machinesGroup.visible = false
		beltGroup.visible = true
	else:
		machinesGroup.visible = true
		beltGroup.visible = false

func changePreview(event, skipEventCheck) -> void:
	if !skipEventCheck:
		if event.is_action_pressed("cycleUp"):
			cycleNum = (cycleNum - 1) % GridManager.scenes.size()
		else:
			cycleNum = (cycleNum + 1) % GridManager.scenes.size()
	
	var currentBuilding = GridManager.get_new_building(GridManager.scenes.keys()[cycleNum])
	currentBuilding.isPreview = true
	for i in machinesGroup.get_children():
		i.queue_free()
	machinesGroup.add_child(currentBuilding)

func getCurrentBuilding() -> String:
	return GridManager.scenes.keys()[cycleNum]

func belt(cells: Array, sets: bool) -> void:
	isBelting = sets
	for i in beltGroup.get_children():
		i.queue_free()
	if isBelting:
		for i in cells:
			var c = i[0]
			var dir = i[1]
			var beltPreview = GridManager.beltScene.instantiate()
			beltPreview.isPreview = true
			beltPreview.global_position = Vector2(c) * GridManager.CELL_SIZE
			beltPreview.rotation_degrees = dir
			beltPreview.modulate = Color(1, 1, 1, 0.5)
			beltGroup.add_child(beltPreview)
