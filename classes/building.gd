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

func _process(delta: float) -> void:
	visualComponent.preview_loop()

func _ready() -> void:
	visualComponent.set_sprite()
	visualComponent.set_pos()
	
	if visualComponent.isPreview:
		return
	
	type = buildingResource.building_type
	
	TimeGlobal.ticked.connect(_on_tick)

func _on_tick():
	if isActive:
		visualComponent.animate()
		if buildingResource.canGenerate:
			generateComponent.generate()
		transportComponent.transport_to()
		
		buildingResource.customBehavior(self)

func link_to_building(building):
	transportComponent.toTransport = building
	linkingComponent.setLinkAtLinkGroup()
