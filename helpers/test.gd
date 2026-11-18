extends Node2D

var cycleNum = 0
var isBelting = false
var dir: bool = false
var enum_values = BuildingTypes.Type.values()

@onready var beltGroup: Node2D = $Belt
@onready var machinesGroup: Node2D = $Machines

func _ready() -> void:
	beltGroup.top_level = true
	z_index = 41
	changePreview(0, true)

func _process(delta: float) -> void:
	visible = InputManager.currentMode == 1
	
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
		if event.is_action_pressed("flip"):
			dir = !dir
		if event.is_action_pressed("cycleUp"):
			cycleNum = (cycleNum - 1) % enum_values.size()
		if event.is_action_pressed("cycleDown"):
			cycleNum = (cycleNum + 1) % enum_values.size()
	
	var convertedType: BuildingTypes.Type = enum_values[cycleNum]

	while convertedType == BuildingTypes.Type.NONE or convertedType == BuildingTypes.Type.BELT:
		cycleNum = (cycleNum + 1) % enum_values.size()
		convertedType = enum_values[cycleNum]

	var currentBuilding: Building = GridManager.get_new_building(convertedType)

	# Safety check just in case
	if currentBuilding:
		currentBuilding.visualComponent.dir = dir
		currentBuilding.visualComponent.isPreview = true
		for i in machinesGroup.get_children():
			i.queue_free()
		machinesGroup.add_child(currentBuilding)
		
		currentBuilding.position = Vector2.ZERO

func getCurrentBuilding():
	var building = {}
	building.class = enum_values[cycleNum]
	building.dir = machinesGroup.get_child(0).visualComponent.dir
	return building

func belt(cells, sets: bool) -> void:
	isBelting = sets
	
	# Clear old belt previews
	for i in beltGroup.get_children():
		i.queue_free()
		
	if isBelting and cells:
		# Depending on whether 'cells' is an array of arrays or a dictionary structure,
		# ensure we target the correct entry list. If cells is an Array, use cells[0] safely:
		var cell_list = cells[0] if (cells is Array and cells.size() > 0) else cells
		
		for i in cell_list:
			var c = i[0]
			var beltDir = i[1]
			var beltPreview = GridManager.beltScene.instantiate()
			beltPreview.isPreview = true
			beltPreview.global_position = Vector2(c) * GridManager.CELL_SIZE
			beltPreview.rotation_degrees = beltDir
			beltGroup.add_child(beltPreview)
