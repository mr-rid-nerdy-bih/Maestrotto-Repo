class_name Building
extends Node2D

@export var buildingResource: BuildingResource

@export var generateComponent: GenerateItemComponent
@export var transportComponent: TransportComponent
@export var inventoryComponent: InventoryComponent
@export var linkingComponent: LinkingComponent
@export var visualComponent: VisualComponent

var tickBirth: int
var isActive: bool = true
var type

var inputCells: Array[Vector2i]
var outputCells: Array[Vector2i]

var behaviorInstance

func _process(delta: float) -> void:
	if visualComponent:
		visualComponent.preview_loop()
	
	if buildingResource:
		type = buildingResource.buildingType
		if buildingResource.customBehavior:
			behaviorInstance = buildingResource.customBehavior.new()
			if behaviorInstance and "building" in behaviorInstance:
				behaviorInstance.building = self

func _ready() -> void:
	if visualComponent:
		visualComponent.set_sprite()
		visualComponent.set_pos()
		if visualComponent.isPreview:
			return
	
	if buildingResource:
		type = buildingResource.buildingType
		inputCells = buildingResource.inputCells
		outputCells = buildingResource.outputCells
	
	TimeGlobal.ticked.connect(_on_tick)

func _on_tick() -> void:
	if not isActive or not buildingResource:
		return
	
	if visualComponent:
		visualComponent.animate()
	if buildingResource.canGenerate and generateComponent:
		generateComponent.generate()
	if transportComponent:
		transportComponent.transport_to()
	
	if not buildingResource.customBehaviorUsesProcess:
		buildingResource.custom_behavior(self)
