class_name TransportComponent
extends Node2D

@export var inventoryComponent: InventoryComponent

var toTransport

func transport_to():
	if !toTransport or not is_instance_valid(toTransport):
		toTransport = null
		return
	
	var parentBuilding = get_parent()
	if not parentBuilding or not "buildingResource" in parentBuilding:
		return
		
	var buildingResource: BuildingResource = parentBuilding.buildingResource
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
	var isTargetBelt = false
	if "type" in toTransport and toTransport.type == BuildingTypes.Type.BELT:
		isTargetBelt = true

	if isTargetBelt:
		if "canInput" in toTransport and not toTransport.canInput:
			return
	else:
		if "buildingResource" in toTransport and toTransport.buildingResource:
			var maxInput = toTransport.buildingResource.maxInput
			if toTransportInventory.inputInventory.size() >= maxInput:
				return

	# Transfer the first output item to the target inventory
	if inventoryComponent.outputInventory.size() > 0:
		var item = inventoryComponent.outputInventory[0]
		toTransportInventory.inputInventory.append(item)
		inventoryComponent.outputInventory.erase(item)

func receive(item: Item, cell: Vector2i, dir: bool):
	pass
	#var validIntakeCell = 
