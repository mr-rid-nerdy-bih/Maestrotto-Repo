class_name Building
extends Node2D

@export var buildingResource: BuildingResource:
	set(value):
		buildingResource = value
		_sync_resource()

@export var generateComponent: GenerateItemComponent
@export var transportComponent: TransportComponent
@export var inventoryComponent: InventoryComponent
@export var linkingComponent: LinkingComponent
@export var visualComponent: VisualComponent
@export var craftComponent: CraftComponent

var tickBirth: int
var isActive: bool = true
var type: BuildingTypes.Type

var behaviorInstance: Script

func _process(delta: float) -> void:
	if visualComponent:
		visualComponent.preview_loop()

func _ready() -> void:
	if visualComponent:
		if buildingResource.texture:
			visualComponent.set_sprite()
		visualComponent.set_pos()
		if visualComponent.isPreview:
			return
	
	if buildingResource:
		type = buildingResource.buildingType
		if buildingResource.customBehavior:
			behaviorInstance = buildingResource.customBehavior.new()
			if behaviorInstance and "building" in behaviorInstance:
				behaviorInstance.building = self
	
	if inventoryComponent:
		inventoryComponent.ready_input_cells()
	if craftComponent:
		craftComponent.check_crafts()
	
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

func link_to_building(building: Building) -> void:
	transportComponent.toTransport = building
	linkingComponent.setLinkAtLinkGroup()

func _sync_resource() -> void:
	for i in get_children():
		if "buildingResource" in i:
			i.buildingResource = buildingResource
