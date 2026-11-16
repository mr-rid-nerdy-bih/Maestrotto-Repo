extends Node2D

var cell: Vector2i
var currentLerp: float = 0.0
var isPreview: bool = false
var previewTexture = preload("uid://bnd0nas1gxf3s")


@onready var game = get_tree().current_scene

@export_range(0.0, 20.0) var speed: float = 20.0
@export var item: Item

func _ready() -> void:
	if isPreview:
		var sprite = Sprite2D.new()
		sprite.texture = previewTexture
		sprite.centered = true
		global_position += Vector2(8, 8)
		
		add_child(sprite)
		
		return
	
	TimeGlobal.ticked.connect(_on_tick)
	
	prep_belt()

func _process(delta: float) -> void:
	if isPreview or not item:
		currentLerp = 0.0
		return
		
	var forwardDir = get_delta(rotation_degrees)
	var startPos = global_position + Vector2(8, 8)
	var endPos = startPos + forwardDir * GridManager.CELL_SIZE
	var gridFront = cell + Vector2i(forwardDir)
	
	# Check if there is a valid, empty belt in front ready to accept the item
	var canMoveForward: bool = false
	if GridManager.has_belt_at(gridFront):
		var nextBelt = GridManager.belts[gridFront]
		if nextBelt.rotation_degrees == rotation_degrees and nextBelt.item == null:
			canMoveForward = true
	
	if not canMoveForward and currentLerp == 0.0:
		item.global_position = startPos
		item.rotation_degrees = 0
		return
	
	currentLerp += speed * delta
	if currentLerp >= 1.0:
		var nextBelt = GridManager.belts[gridFront]
		nextBelt.give_item(item)
		item = null
		currentLerp = 0.0
		return
	
	item.global_position = startPos.lerp(endPos, currentLerp)
	item.rotation_degrees = 0


func get_delta(rot: float) -> Vector2:
	var r = round(fposmod(rot, 360.0) / 90.0) * 90.0
	
	if abs(r - 180.0) < 1.0:
		return Vector2(-1, 0)
	elif abs(r - 0.0) < 1.0 or abs(r - 360.0) < 1.0:
		return Vector2(1, 0)
	elif abs(r - 90.0) < 1.0:
		return Vector2(0, 1)
	elif abs(r - 270.0) < 1.0:
		return Vector2(0, -1)
	
	return Vector2.ZERO

func prep_belt():
	if item:
		var forwardDir = get_delta(rotation_degrees)
		var startPos = global_position + Vector2(8, 8)
		var endPos = startPos + forwardDir * GridManager.CELL_SIZE
		item.global_position = startPos.lerp(endPos, currentLerp)
		item.rotation_degrees = 0
		if not item.is_inside_tree():
			game.add_child(item)
		print(global_position)
	
	if GridManager and not GridManager.belts.has(cell):
		GridManager.belts[cell] = self

func _on_tick():
	if GridManager and not GridManager.belts.has(cell):
		GridManager.belts[cell] = self
	
	pass

func get_coords():
	var rot = int(round(rotation_degrees)) % 360
	var y = 0
	
	match rot:
		0: y = 0
		90: y = 2
		180: y = 1
		270: y = 3
	
	return Vector2(0, y)

func give_item(newItem):
	item = newItem
	currentLerp = 0.0
	prep_belt()
