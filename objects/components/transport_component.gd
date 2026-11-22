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

func trans_to(outCell, ) -> void:
	if !toTransport or not is_instance_valid(toTransport):
		toTransport = null
		return
	
	if buildingResource.passThroughInput:
		for i in inventoryComponent.inputCells:
			if i.inventory.size() < 1: continue
			var item: Item = i.inventory[0]
			
			var accepted: bool = move_into_inventory(item, true)
			if accepted:
				i.inventory.erase(item)
	
	var isBelt: bool = toTransport.type == BuildingTypes.Type.BELT
	
	

func receive(item: Item, cell: Vector2i, dir: Vector2) -> bool:
	var selfDir: Vector2 = visualComponent.dir
	var selfCell: Vector2i = visualComponent.cell
	
	for i: Dictionary in inventoryComponent.inputCells:
		if i.inventory.size() >= buildingResource.maxInput:
			continue
		
		if cell.distance_to(selfCell) > 1:
			continue
		
		if dir != selfDir:
			continue
		
		move_into_inventory(item)
	
	return false

func move_into_inventory(item: Item, output: bool = false) -> bool:
	if output:
		@warning_ignore("untyped_declaration")
		for i in inventoryComponent.outputCells:
			if i.inventory.size() >= buildingResource.maxInput:
				print("ItemSlot at ", visualComponent.cell, " filled. Move attempt failed")
				return false
			
			if i.item.any:
				i.inventory.append(item)
				i.item = item.itemResource
				return true
			
			if i.item.itemName != item.itemResource.itemName:
				i.inventory.append(item)
				return true
			return false
	@warning_ignore("untyped_declaration")
	for i in inventoryComponent.inputCells:
		if i.inventory.size() >= buildingResource.maxInput:
			print("ItemSlot at ", visualComponent.cell, " filled. Move attempt failed")
			return false
		
		if i.item.any:
			i.inventory.append(item)
			i.item = item.itemResource
			return true
		
		if i.item.itemName != item.itemResource.itemName:
			i.inventory.append(item)
			return true
	return false
