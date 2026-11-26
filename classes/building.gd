class_name Building
extends Node2D
## Base class for everything placeable on the grid (machines and belts).
## A building is a bundle of components; each tick it animates, crafts and
## moves items. Behaviour is configured by its BuildingResource.

## Data asset describing this building. Setting it pushes it to every component.
@export var buildingResource: BuildingResource:
	set(value):
		buildingResource = value
		sync_resource()

@export var generateComponent: GenerateItemComponent
@export var transportComponent: TransportComponent
@export var inventoryComponent: InventoryComponent
@export var linkingComponent: LinkingComponent
@export var visualComponent: VisualComponent
@export var craftComponent: CraftComponent

## Global tick on which this building was placed.
var tickBirth: int
## When false, the building skips its tick (paused).
var isActive: bool = true
var type: BuildingTypes.Type

## Instance of BuildingResource.customBehavior, if the building has one.
var behaviorInstance: Script

func _process(_delta: float) -> void:
	if visualComponent:
		visualComponent.preview_loop()

func _ready() -> void:
	# The setter can run before children exist (during instantiate), so sync
	# again now that every component is guaranteed to be in the tree.
	sync_resource()

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
		inventoryComponent.setup()

	TimeGlobal.ticked.connect(on_tick)

## Runs once per global tick: animate, craft, transport, custom behaviour.
func on_tick() -> void:
	if not isActive or not buildingResource:
		return
	
	if buildingResource.customBehavior:
		buildingResource.custom_behavior(self)
	
	if visualComponent:
		visualComponent.animate()
	if buildingResource.canGenerate and generateComponent:
		generateComponent.generate()
	if transportComponent:
		transportComponent.transport_to()

## Sends this building's output to [param building]. Pass null to unlink.
func link_to_building(building: Building) -> void:
	transportComponent.toTransport = building
	linkingComponent.set_link_at_link_group()

# --- Hooks subclasses can override (see belt.gd) ---------------------------

## Extra acceptance rule on top of "is there inventory space?".
func can_receive_item(_item: Item) -> bool:
	return true

## Called right after an item was added to this building's input.
func on_item_received(_item: Item) -> void:
	pass

## Copies buildingResource onto every child component that has that property.
func sync_resource() -> void:
	for i in get_children():
		if "buildingResource" in i:
			i.buildingResource = buildingResource
