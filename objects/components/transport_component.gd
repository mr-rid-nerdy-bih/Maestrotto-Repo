class_name TransportComponent
extends Node2D

@export var inventoryComponent: InventoryComponent
@export var visualComponent: VisualComponent
var buildingResource: BuildingResource

var toTransport: Building

func transport_to() -> void:
	if not is_instance_valid(toTransport):
		toTransport = null
		print("is that so packager :", buildingResource.buildingType)
		return
	
	if buildingResource.passThroughInput:
		for in_slot: Dictionary in inventoryComponent.inputCells:
			var in_inv: Array = in_slot.get("inventory", [])
			while in_inv.size() > 0:
				var item: Item = in_inv[0]
				if not is_instance_valid(item):
					in_inv.remove_at(0)
					continue
				if move_into_inventory(item, true):
					in_inv.remove_at(0)
				else:
					break
	
	var isBelt: bool = toTransport.type == BuildingTypes.Type.BELT
	if isBelt and "canInput" in toTransport and not toTransport.canInput:
		return
	
	for out_slot: Dictionary in inventoryComponent.outputCells:
		var out_inv: Array = out_slot.get("inventory", [])
		for i in range(out_inv.size() - 1, -1, -1):
			var item: Item = out_inv[i]
			if not is_instance_valid(item):
				out_inv.remove_at(i)
				continue
			print("reached")
			if toTransport.transportComponent.receive(item, visualComponent.cell, visualComponent.dir):
				out_inv.remove_at(i)

func receive(item: Item, cell: Vector2i, dir: Vector2) -> bool:
	if not is_instance_valid(item) or visualComponent == null or inventoryComponent == null:
		return false
	
	var selfCell: Vector2i = visualComponent.cell
	var selfDir: Vector2 = visualComponent.dir
	if cell.distance_to(selfCell) > 1.0:
		return false
	if dir != selfDir:
		return false
	
	var accepted: bool = move_into_inventory(item, false)
	return accepted

func move_into_inventory(item: Item, output: bool = false) -> bool:
	if not is_instance_valid(item) or inventoryComponent == null or buildingResource == null:
		return false
	
	var target_cells: Array = inventoryComponent.outputCells if output else inventoryComponent.inputCells
	var max_cap: int = buildingResource.maxOutput if output else buildingResource.maxInput
	
	for slot: Dictionary in target_cells:
		if slot == null:
			continue
		var slot_inv: Array = slot.get("inventory", [])
		if slot_inv.size() >= max_cap:
			continue
		
		var expected_item: ItemResource = slot.get("item", null)
		var is_wildcard := expected_item == null or expected_item.any == "Any"
		var matches_item := item.itemResource == expected_item
		
		if is_wildcard or matches_item:
			print("here")
			slot_inv.append(item)
			print(slot_inv)
			return true
	
	# Fallback to flat list if no matching slot accepted it
	var fallback_list: Array = inventoryComponent.outputInventory if output else inventoryComponent.inputInventory
	if fallback_list.size() < max_cap:
		fallback_list.append(item)
		return true
	
	return false
