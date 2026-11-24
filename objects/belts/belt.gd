extends Building
## A belt is just a Building whose input slot is "the items currently riding
## on it". Items move along the line every frame; when the front item reaches
## the end it is handed to the linked building with transportComponent.send().

const Side := InventoryComponent.Side

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
		line2D = get_node_or_null("Line2D")

	if visualComponent:
		visualComponent.cell = cell
		if visualComponent.isPreview or isPreview:
			_setup_preview()
			return

	_sync_resource()
	type = buildingResource.buildingType
	inventoryComponent.setup()

	_setup_points()
	_fit_capacity_to_length()
	set_inbetweens()
	draw_on_grid()

## A belt's capacity is however many items physically fit on it,
## not the generic maxInput (which capped every belt at 10).
func _fit_capacity_to_length() -> void:
	var length := _start_pos().distance_to(_end_pos())
	var fits := int(length / itemSpacing) + 1
	for slot: InventorySlot in inventoryComponent.inputSlots:
		slot.capacity = fits

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

# Belts move items in _process (smooth), not on the tick.
func _on_tick() -> void:
	pass

# --- Transport hooks -------------------------------------------------------

func can_receive_item(_item: Item) -> bool:
	return canInput

func on_item_received(item: Item) -> void:
	item.currentLerp = 0.0
	item.z_index = ZLayers.ITEM
	add_child(item) # child of the belt -> freed automatically when the belt is erased
	item.global_position = _start_pos()

# --- Movement --------------------------------------------------------------

func _start_pos() -> Vector2:
	return line2D.to_global(line2D.get_point_position(0))

func _end_pos() -> Vector2:
	return line2D.to_global(line2D.get_point_position(1))

func _process(_delta: float) -> void:
	if isPreview or not line2D or line2D.get_point_count() < 2:
		return

	var start := _start_pos()
	var end := _end_pos()
	var length := maxf(start.distance_to(end), 1.0)
	var spacing := itemSpacing / length # spacing measured in "lerp units"
	var step := speed * _delta / length

	# Index 0 is the front item (oldest). Each item may move up to the item ahead.
	var items := inventoryComponent.get_items(Side.INPUT)
	for i in items.size():
		var item := items[i]
		var limit := 1.0 if i == 0 else items[i - 1].currentLerp - spacing
		item.currentLerp = clampf(item.currentLerp + step, item.currentLerp, maxf(limit, item.currentLerp))
		item.global_position = start.lerp(end, clampf(item.currentLerp, 0.0, 1.0))

	# Front item at the end -> try to hand it off. If the target is full it
	# just waits there and the items behind it queue up.
	if not items.is_empty() and items[0].currentLerp >= 1.0:
		if transportComponent.send(items[0], Side.INPUT):
			items.remove_at(0)

	# Only accept a new item once the newest one has moved out of the way.
	canInput = items.is_empty() or items[-1].currentLerp >= spacing
