class_name Belt
extends Building

@export var line2D: Line2D
@export var speed: float = 20.0
@export var itemSpacing: float = 10.0
@export var previewTexture: Texture2D = preload("uid://bnd0nas1gxf3s")

var belts: Array[Dictionary] = []
var cell: Vector2i
var cell1: Vector2i
var canInput: bool = true
var isPreview: bool = false

@onready var game = get_tree().current_scene

func _ready() -> void:
	if not line2D:
		line2D = get_node_or_null("line2D")
	
	if visualComponent:
		visualComponent.cell = cell1
		if visualComponent.isPreview or isPreview:
			_setup_preview()
			return
	
	if buildingResource:
		type = buildingResource.buildingType
	
	TimeGlobal.ticked.connect(_on_tick)
	
	_setup_points()
	set_inbetweens()
	draw_on_grid()

func _setup_preview() -> void:
	var sprite = Sprite2D.new()
	sprite.texture = previewTexture
	sprite.centered = true
	global_position += Vector2(8, 8)
	add_child(sprite)

func _setup_points() -> void:
	if not line2D or line2D.get_point_count() >= 2:
		return
	line2D.clear_points()
	var startPos = Vector2(cell) * GridManager.CELL_SIZE + Vector2(8, 8)
	var endPos = Vector2(cell1) * GridManager.CELL_SIZE + Vector2(8, 8)
	if startPos == endPos:
		endPos += Vector2(GridManager.CELL_SIZE, 0)
	line2D.add_point(startPos)
	line2D.add_point(endPos)

func get_rot() -> float:
	if not line2D or line2D.get_point_count() < 2:
		return 0.0
	return line2D.get_point_position(0).angle_to_point(line2D.get_point_position(1))

func get_coords() -> Vector2i:
	var rotDeg = rad_to_deg(get_rot())
	var normalizedRot = int(round(fposmod(rotDeg, 360.0))) % 360
	var y = 0
	
	match normalizedRot:
		0: y = 0
		90: y = 2
		180: y = 1
		270: y = 3
	
	return Vector2i(0, y)

func set_inbetweens() -> void:
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

func draw_on_grid() -> void:
	for b in belts:
		GridManager.beltLayer.set_cell(b.cell, 1, b.rotation)

func child_items() -> void:
	if not inventoryComponent or not line2D or line2D.get_point_count() < 2:
		return
	for item in inventoryComponent.inputInventory:
		if is_instance_valid(item) and item.get_parent() == null:
			item.global_position = line2D.get_point_position(0)
			item.z_index = 10
			game.add_child(item)
