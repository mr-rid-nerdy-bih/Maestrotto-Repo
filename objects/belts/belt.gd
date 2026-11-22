extends Building

@export var line2D: Line2D
@export var speed: float = 20.0
@export var itemSpacing: float = 10.0
@export var previewTexture: Texture2D = preload("uid://bnd0nas1gxf3s")

@export var anyItemResource: ItemResource

var belts: Array[Dictionary] = []
var cell: Vector2i
var cell1: Vector2i
var canInput: bool = true
var isPreview: bool = false

@onready var game: Node = get_tree().current_scene
@onready var beltLayer: TileMapLayer = game.get_node("TileMapLayer")

func _ready() -> void:
	if not line2D:
		line2D = get_node_or_null("line2D")
	
	if visualComponent:
		visualComponent.cell = cell
		if visualComponent.isPreview or isPreview:
			_setup_preview()
			return
	
	type = buildingResource.buildingType
	
	inventoryComponent.add_input_cell(Vector2i(0, 0), anyItemResource)
	inventoryComponent.add_output_cell(cell1 - cell, anyItemResource)
	
	_setup_points()
	set_inbetweens()
	draw_on_grid()

func _setup_preview() -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = previewTexture
	sprite.centered = true
	global_position += Vector2(8, 8)
	add_child(sprite)

func _setup_points() -> void:
	if not line2D or line2D.get_point_count() >= 2:
		return
	line2D.clear_points()
	var startPos: Vector2 = Vector2(cell) * GridManager.CELL_SIZE + Vector2(8, 8)
	var endPos: Vector2 = Vector2(cell1) * GridManager.CELL_SIZE + Vector2(8, 8)
	if startPos == endPos:
		endPos += Vector2(GridManager.CELL_SIZE, 0)
	line2D.add_point(startPos)
	line2D.add_point(endPos)

func get_rot() -> float:
	if not line2D or line2D.get_point_count() < 2:
		return 0.0
	return line2D.get_point_position(0).angle_to_point(line2D.get_point_position(1))

func get_coords() -> Vector2i:
	var rotDeg := rad_to_deg(get_rot())
	var normalizedRot := int(round(fposmod(rotDeg, 360.0))) % 360
	var y := 0
	
	match normalizedRot:
		0: y = 0
		90: y = 2
		180: y = 1
		270: y = 3
	
	return Vector2i(0, y)

func set_inbetweens() -> void:
	belts.clear()
	if !cell or !cell1:
		for entry in belts:
			beltLayer.erase_cell(entry["cell"])
		GridManager.beltNodes.erase(self)
		print("Erased belt containing cell: ", cell, ". Cell or Cell1 was null.")
		queue_free()
	
	var rotDeg := rad_to_deg(get_rot())
	var normalizedRot := int(round(fposmod(rotDeg, 360.0))) % 360
	var dir := Vector2i.ZERO
	
	match normalizedRot:
		0: dir.x = 1
		90: dir.y = 1
		180: dir.x = -1
		270: dir.y = -1
	
	var count: int = abs(cell1.x - cell.x) + abs(cell1.y - cell.y)
	var atlasCoords := get_coords()
	
	for i in range(count + 1):
		belts.append({"cell": cell + dir * i, "rotation": atlasCoords})

func draw_on_grid() -> void:
	for b in belts:
		GridManager.beltLayer.set_cell(b.cell, 1, b.rotation)

func child_items() -> void:
	if not inventoryComponent or not line2D or line2D.get_point_count() < 2:
		return
	if inventoryComponent.inputCells.size() == 0: add_slots()
	for item: Item in inventoryComponent.inputCells[0].inventory:
		if is_instance_valid(item) and item.get_parent() == null:
			item.global_position = line2D.get_point_position(0)
			item.z_index = 10
			game.add_child(item)

func _on_tick() -> void:
	pass

func _process(delta: float) -> void:
	if isPreview: return
	
	var input: Array = inventoryComponent.inputInventory
	var pos0: Vector2 = line2D.get_point_position(0)
	var pos1: Vector2 = line2D.get_point_position(1)
	
	child_items()
	
	canInput = true
	if input.size() != 0:
		if pos0.distance_to(input[input.size() - 1].global_position) < itemSpacing:
			canInput = false
	
	var distanceDivision: float = pos0.distance_to(pos1)
	if distanceDivision <= 0.0:
		distanceDivision = GridManager.CELL_SIZE
	
	for i in range(input.size() - 1, -1, -1):
		var currentItem: Item = input[i]
		if not is_instance_valid(currentItem):
			input.remove_at(i)
			continue
			
		if i != 0 and is_instance_valid(input[i - 1]):
			var distanceToNext := currentItem.global_position.distance_to(input[i - 1].global_position)
			if distanceToNext < itemSpacing:
				continue
		
		currentItem.global_position = lerp(pos0, pos1, clampf(currentItem.currentLerp, 0.0, 1.0))
		
		if currentItem.currentLerp < 1.0:
			@warning_ignore("narrowing_conversion")
			currentItem.currentLerp += (speed * delta) / distanceDivision
		else:
			if is_instance_valid(transportComponent.toTransport) and transportComponent.toTransport.inventoryComponent.inputInventory.size() < transportComponent.toTransport.buildingResource.maxInput:
				if currentItem.get_parent() != null:
					currentItem.get_parent().remove_child(currentItem)
				
				currentItem.currentLerp = 0
				inventoryComponent.outputCells[0].outputInventory.append(currentItem)
				inventoryComponent.inputCells[0].inputInventory.remove_at(i)
				transportComponent.transport_to()

func add_slots() -> void:
	inventoryComponent.add_input_cell(Vector2i(0, 0), anyItemResource)
	inventoryComponent.add_output_cell(cell1 - cell, anyItemResource)
