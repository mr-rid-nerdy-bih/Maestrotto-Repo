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
## This building's type, read from its resource so it can never be out of sync.
## Read-only: change the type by changing buildingResource.
var type: BuildingTypes.Type:
	get:
		return buildingResource.buildingType if buildingResource else BuildingTypes.Type.NONE

## Instance of BuildingResource.customBehavior, if the building has one.
var behaviorInstance: Script

## Custom building data
var data: Dictionary

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
	
	if inventoryComponent:
		inventoryComponent.setup()
	
	TimeGlobal.ticked.connect(on_tick)

## Runs once per global tick: animate, craft, transport, custom behaviour.
func on_tick() -> void:
	if not isActive or not buildingResource:
		return
	
<<<<<<< Updated upstream
	if buildingResource.customBehavior:
=======
	if not buildingResource.customBehaviorUsesProcess:
>>>>>>> Stashed changes
		buildingResource.custom_behavior(self)
	
	if visualComponent:
		visualComponent.animate()
	if buildingResource.canGenerate and generateComponent:
		generateComponent.generate()
	if transportComponent:
		transportComponent.transport_to()

## Sends the output of [param outputCell] to [param building]. Pass null to unlink that cell.
func link_to_building(building: Building, outputCell: Vector2i = Vector2i.ZERO) -> void:
	transportComponent.set_target(outputCell, building)
	linkingComponent.set_link_at_link_group()

# --- Link range ------------------------------------------------------------

## Top-left cell of this building on the grid.
func get_origin() -> Vector2i:
	return visualComponent.cell if visualComponent else Vector2i.ZERO

## Every grid cell this building covers.
func get_footprint() -> Array[Vector2i]:
	return GridManager.get_footprint_cells(get_origin(), buildingResource.size)

## Grid cells that accept items. With no input slots set up, the whole footprint does.
func get_input_world_cells() -> Array[Vector2i]:
	if buildingResource.inputCells.is_empty():
		return get_footprint()
	var cells: Array[Vector2i] = []
	for slot: ItemSlot in buildingResource.inputCells:
		if not cells.has(get_origin() + slot.cell):
			cells.append(get_origin() + slot.cell)
	return cells

## Grid cells items leave from for [param outputCell]. With no output slots
## set up, the whole footprint does.
func get_output_world_cells(outputCell: Vector2i = Vector2i.ZERO) -> Array[Vector2i]:
	if buildingResource.outputCells.is_empty():
		return get_footprint()
	return [get_origin() + outputCell]

## Shortest distance in cells from [param outputCell] to any input cell of
## [param target]. Diagonal neighbours count as 1.
func link_distance_to(target: Building, outputCell: Vector2i = Vector2i.ZERO) -> int:
	var best := 999999
	for from: Vector2i in get_output_world_cells(outputCell):
		for to: Vector2i in target.get_input_world_cells():
			var diff := (to - from).abs()
			best = mini(best, maxi(diff.x, diff.y))
	return best

## True if [param target] is within maxLinkDistance of [param outputCell].
func can_link_to(target: Building, outputCell: Vector2i = Vector2i.ZERO) -> bool:
	var inRange: bool = link_distance_to(target, outputCell) <= target.buildingResource.maxLinkDistance
	var belowMaxInputBuildings: bool = (target.transportComponent.inputs + 1)  <= target.buildingResource.maxLinkInputs
	print(target.transportComponent.inputs, ",", target.buildingResource.maxLinkInputs)
	
	return inRange and belowMaxInputBuildings

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
