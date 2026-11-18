class_name Belt
extends Line2D

var belts = []

var validOutputBuildings = [BuildingTypes.Type.CHUTE]
var type: BuildingTypes.Type = BuildingTypes.Type.BELT

@export var speed: float = 20

var cell: Vector2i
var cell1: Vector2i

var itemSpacing = 10
var canInput: bool = true
var isPreview: bool = false
var previewTexture = preload("uid://bnd0nas1gxf3s")

@onready var game = get_tree().current_scene
@onready var links = get_tree().current_scene.get_node("Links")

@export var transportComponent: TransportComponent
@export var inventoryComponent: InventoryComponent

func _ready() -> void:
	if isPreview:
		var sprite = Sprite2D.new()
		sprite.texture = previewTexture
		sprite.centered = true
		global_position += Vector2(8, 8)
		add_child(sprite)
		return
	
	if get_point_count() < 2:
		clear_points()
		var startPos = Vector2(cell) * GridManager.CELL_SIZE + Vector2(8, 8)
		var endPos = Vector2(cell1) * GridManager.CELL_SIZE + Vector2(8, 8)
		if startPos == endPos:
			endPos += Vector2(GridManager.CELL_SIZE, 0)
		add_point(startPos)
		add_point(endPos)
	
	set_inbetweens()
	draw_on_grid()

func _process(delta: float) -> void:
	if isPreview:
		return
	
	child_items()
	
	canInput = true
	if inventoryComponent.inputInventory.size() != 0:
		if get_point_position(0).distance_to(inventoryComponent.inputInventory[inventoryComponent.inputInventory.size() - 1].global_position) < itemSpacing:
			canInput = false
	
	var distanceDivision = get_point_position(0).distance_to(get_point_position(1))
	if distanceDivision <= 0.0:
		distanceDivision = GridManager.CELL_SIZE
	
	for i in range(inventoryComponent.inputInventory.size() - 1, -1, -1):
		var currentItem: Item = inventoryComponent.inputInventory[i]
		if not is_instance_valid(currentItem):
			inventoryComponent.inputInventory.remove_at(i)
			continue
			
		if i != 0 and is_instance_valid(inventoryComponent.inputInventory[i - 1]):
			var distanceToNext = currentItem.global_position.distance_to(inventoryComponent.inputInventory[i - 1].global_position)
			if distanceToNext < itemSpacing:
				continue
		
		currentItem.global_position = lerp(get_point_position(0), get_point_position(1), clampf(currentItem.currentLerp, 0.0, 1.0))
		
		if currentItem.currentLerp < 1.0:
			currentItem.currentLerp += (speed * delta) / distanceDivision
		else:
			if is_instance_valid(transportComponent.toTransport) and transportComponent.toTransport.inventoryComponent.inputInventory.size() < transportComponent.toTransport.buildingResource.maxInput:
				if currentItem.get_parent() != null:
					currentItem.get_parent().remove_child(currentItem)
				
				currentItem.currentLerp = 0
				inventoryComponent.outputInventory.append(currentItem)
				inventoryComponent.inputInventory.remove_at(i)
				transport_to()

func get_rot():
	return get_point_position(0).angle_to_point(get_point_position(1))

func get_coords():
	var rotDeg = rad_to_deg(get_rot())
	var normalizedRot = int(round(fposmod(rotDeg, 360.0))) % 360
	var y = 0
	
	match normalizedRot:
		0: y = 0
		90: y = 2
		180: y = 1
		270: y = 3
	
	return Vector2i(0, y)

func set_inbetweens():
	belts.clear()
	var rotDeg = rad_to_deg(get_rot())
	var normalizedRot = int(round(fposmod(rotDeg, 360.0))) % 360
	var dir = Vector2i.ZERO
	
	match normalizedRot:
		0: dir.x = 1
		90: dir.y = 1
		180: dir.x = -1
		270: dir.y = -1
	
	var count: int = abs(cell1.x - cell.x) + abs(cell1.y - cell.y)
	var atlasCoords = get_coords()
	
	for i in range(count + 1):
		belts.append({"cell": cell + dir * i, "rotation": atlasCoords})

func draw_on_grid():
	for i in belts:
		GridManager.beltLayer.set_cell(i.cell, 1, i.rotation)

func child_items():
	for i in inventoryComponent.inputInventory:
		if is_instance_valid(i) and i.get_parent() == null:
			i.global_position = get_point_position(0)
			i.z_index = 10
			game.add_child(i)

func transport_to():
	var toTransportInventory: InventoryComponent = transportComponent.toTransport.get_node("InventoryComponent")
	
	if !transportComponent.toTransport:
		return
	if toTransportInventory.inputInventory.size() >= transportComponent.toTransport.buildingResource.maxInput:
		return
	
	if inventoryComponent.outputInventory.size() > 0:
		var item = inventoryComponent.outputInventory[0]
		toTransportInventory.inputInventory.append(item)
		inventoryComponent.outputInventory.erase(item)

func setLinkAtLinkGroup():
	if !transportComponent.toTransport:
		if links.links.has(cell):
			links.links.erase(cell)
		if links.links.has(cell1):
			links.links.erase(cell1)
		return
	
	if !links.links.has(cell):
		links.links.set(cell1, {"endBuildingType": transportComponent.toTransport.type, "startBuildingType": type, "from": cell1, "to": transportComponent.toTransport.visualComponent.cell})
		print(transportComponent.toTransport.type, ",",type)

func link_to_building(building):
	transportComponent.toTransport = building
	setLinkAtLinkGroup()
