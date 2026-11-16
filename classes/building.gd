class_name Building
extends Node2D

@export var texture: Texture
@export var isAnimated: bool
@export var hframes: int = 1
@export var offset: Vector2
@export var frameTime: float

var sprite: Sprite2D = Sprite2D.new()
var frame: float = 0
var cell: Vector2i
var tickBirth: int
var isActive: bool = false
var stopAnim: bool = false
var isPreview: bool = false

var toTransport

var inputInventory = []
var maxInput = 10

var outputInventory = []
var maxOutput = 10

var validOutputBuildings = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	offset += Vector2(8.0, 8.0)
	
	sprite.texture = texture
	sprite.offset = offset
	sprite.hframes = hframes
	add_child(sprite)
	
	if isPreview:
		modulate = Color(1, 1, 1, 0.5) # Makes the preview 50% transparent
		return
	
	TimeGlobal.ticked.connect(_on_tick)
	
	var pos = Vector2(cell) * GridManager.CELL_SIZE
	global_position = pos

func _on_tick():
	if isPreview:
		return
	
	if isActive:
		animate()

func animate():
	if isAnimated and not stopAnim:
		frame = fmod(frame + 1.0 / frameTime, float(hframes))
	
	sprite.frame = int(frame)

func link_to_building(buildingCell):
	var buildingOnGrid = GridManager.get_building_at(buildingCell)
	
	if not buildingOnGrid:
		print("Cell error.")
		return
	
	toTransport = buildingOnGrid

func transport_to(passThroughInput: bool = false):
	if !toTransport:
		return
	if toTransport.inputInventory.size() >= toTransport.maxInput:
		return
	if passThroughInput:
		outputInventory = inputInventory
		inputInventory = []
	if toTransport is Belt:
		if !toTransport.canInput: return
	
	if outputInventory.size() > 0:
		var item = outputInventory[0]
		toTransport.inputInventory.append(item)
		outputInventory.erase(item)
