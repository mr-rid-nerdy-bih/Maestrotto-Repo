class_name Belt
extends Line2D

var belts = []

var inputInventory = []
var maxInput = 999
var outputInventory = []
var maxOutput = 1
var validOutputBuildings = [Chute]
var toTransport

@export var speed: float = 20

var cell: Vector2i
var cell1: Vector2i

var itemSpacing = 10
var canInput: bool = true
var isPreview: bool = false
var previewTexture = preload("uid://bnd0nas1gxf3s")

@onready var game = get_tree().current_scene

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
		var start_pos = Vector2(cell) * GridManager.CELL_SIZE + Vector2(8, 8)
		var end_pos = Vector2(cell1) * GridManager.CELL_SIZE + Vector2(8, 8)
		if start_pos == end_pos:
			end_pos += Vector2(GridManager.CELL_SIZE, 0)
		add_point(start_pos)
		add_point(end_pos)
	
	set_inbetweens()
	draw_on_grid()

func _process(delta: float) -> void:
	if isPreview:
		return
	
	child_items()
	
	canInput = true
	if inputInventory.size() != 0:
		if get_point_position(0).distance_to(inputInventory[inputInventory.size() - 1].global_position) < itemSpacing:
			canInput = false
	
	var distanceDivision = get_point_position(0).distance_to(get_point_position(1))
	if distanceDivision <= 0.0:
		distanceDivision = GridManager.CELL_SIZE
	
	for i in range(inputInventory.size() - 1, -1, -1):
		var currentItem = inputInventory[i]
		if not is_instance_valid(currentItem):
			inputInventory.remove_at(i)
			continue
			
		if i != 0 and is_instance_valid(inputInventory[i - 1]):
			var distanceToNext = currentItem.global_position.distance_to(inputInventory[i - 1].global_position)
			if distanceToNext < itemSpacing:
				continue
		
		currentItem.global_position = lerp(get_point_position(0), get_point_position(1), clampf(currentItem.currentLerp, 0.0, 1.0))
		
		if currentItem.currentLerp < 1.0:
			currentItem.currentLerp += (speed * delta) / distanceDivision
		else:
			if is_instance_valid(toTransport) and toTransport.inputInventory.size() < toTransport.maxInput:
				if toTransport is Belt and not toTransport.canInput:
					continue
				
				if not (toTransport is Belt) and currentItem.get_parent() != null:
					currentItem.get_parent().remove_child(currentItem)
					
				outputInventory.append(currentItem)
				inputInventory.remove_at(i)
				transport_to(toTransport is Belt, false)

func get_rot():
	return get_point_position(0).angle_to_point(get_point_position(1))

func get_coords():
	var rot_deg = rad_to_deg(get_rot())
	var normalized_rot = int(round(fposmod(rot_deg, 360.0))) % 360
	var y = 0
	
	match normalized_rot:
		0: y = 0
		90: y = 2
		180: y = 1
		270: y = 3
	
	return Vector2i(0, y)

func set_inbetweens():
	belts.clear()
	var rot_deg = rad_to_deg(get_rot())
	var normalized_rot = int(round(fposmod(rot_deg, 360.0))) % 360
	var dir = Vector2i.ZERO
	
	match normalized_rot:
		0: dir.x = 1
		90: dir.y = 1
		180: dir.x = -1
		270: dir.y = -1
	
	var count: int = abs(cell1.x - cell.x) + abs(cell1.y - cell.y)
	var atlas_coords = get_coords()
	
	for i in range(count + 1):
		belts.append({"cell": cell + dir * i, "rotation": atlas_coords})

func draw_on_grid():
	for i in belts:
		GridManager.beltLayer.set_cell(i.cell, 1, i.rotation)

func child_items():
	for i in inputInventory:
		if is_instance_valid(i) and i.get_parent() == null:
			i.global_position = get_point_position(0)
			i.z_index = 10
			game.add_child(i)

func transport_to(belt: bool = false, passThroughInput: bool = false):
	if not is_instance_valid(toTransport):
		return
	if toTransport.inputInventory.size() >= toTransport.maxInput:
		return
	if belt and not toTransport.canInput:
		return
	
	if outputInventory.size() > 0:
		var item = outputInventory[0]
		item.currentLerp = 0.0
		toTransport.inputInventory.append(item)
		outputInventory.remove_at(0)
