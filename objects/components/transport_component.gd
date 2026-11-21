class_name TransportComponent
extends Node2D

@export var inventoryComponent: InventoryComponent
@export var visualComponent: VisualComponent
var buildingResource: BuildingResource

var toTransport: Building

func transport_to() -> void:
	if !toTransport or not is_instance_valid(toTransport):
		toTransport = null
		return
	
	var input := inventoryComponent.inputInventory
	var output := inventoryComponent.outputInventory
	
	if buildingResource.passThroughInput:
		while input.size() > 0 and output.size() < buildingResource.maxOutput:
			var item: Item = input[0]
			input.erase(item)
			output.append(item)
	
	var toTransportInventory: InventoryComponent = toTransport.inventoryComponent
	var isBelt: bool = toTransport.type == BuildingTypes.Type.BELT
	
	if !toTransportInventory:
		return
	if toTransportInventory.inputInventory.size() >= toTransport.buildingResource.maxInput:
		return
	
	if output.size() > 0:
		if isBelt and !toTransport.canInput: return
		
		var item: Item = output[0]
		toTransportInventory.inputInventory.append(item)
		output.erase(item)

func receive(item: Item, cell: Vector2i, dir: bool) -> bool:
	var itemResource: ItemResource = item.itemResource
	var selfDir: bool = visualComponent.dir
	var selfCell: Vector2i = visualComponent.cell
	
	for i: Dictionary in inventoryComponent.inputCells:
		if i.inventory.size() >= buildingResource.maxInput:
			continue
		
		if cell.distance_to(selfCell) > 1:
			continue
		
		if dir != selfDir:
			continue
		
		if i.itemResource == item.itemResource:
			i.inventory.append(item)
			return true
	
	return false
