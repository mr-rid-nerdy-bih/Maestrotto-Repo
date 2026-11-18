class_name TransportComponent
extends Node2D

@export var inventoryComponent: InventoryComponent

var toTransport

func transport_to():
	if !toTransport or not is_instance_valid(toTransport):
		toTransport = null
		return
	
	var parent_building = get_parent()
	if not parent_building or not "buildingResource" in parent_building:
		return
		
	var buildingResource: BuildingResource = parent_building.buildingResource
	if !buildingResource:
		return

	if not inventoryComponent:
		return

	# If passthrough is enabled, automatically feed input items straight into output inventory
	if buildingResource.passThroughInput:
		while inventoryComponent.inputInventory.size() > 0 and inventoryComponent.outputInventory.size() < buildingResource.maxOutput:
			var item = inventoryComponent.inputInventory[0]
			inventoryComponent.inputInventory.erase(item)
			inventoryComponent.outputInventory.append(item)

	# If there's nothing in output to transport, stop here
	if inventoryComponent.outputInventory.is_empty():
		return

	var toTransportInventory: InventoryComponent = null
	if toTransport.has_node("InventoryComponent"):
		toTransportInventory = toTransport.get_node("InventoryComponent")
	
	if !toTransportInventory:
		return

	# Check if target is a belt or building and verify capacity
	var is_target_belt = false
	if "type" in toTransport and toTransport.type == BuildingTypes.Type.BELT:
		is_target_belt = true

	if is_target_belt:
		if "canInput" in toTransport and not toTransport.canInput:
			return
	else:
		if "buildingResource" in toTransport and toTransport.buildingResource:
			var max_input = toTransport.buildingResource.maxInput
			if toTransportInventory.inputInventory.size() >= max_input:
				return

	# Transfer the first output item to the target inventory
	if inventoryComponent.outputInventory.size() > 0:
		var item = inventoryComponent.outputInventory[0]
		toTransportInventory.inputInventory.append(item)
		inventoryComponent.outputInventory.erase(item)
