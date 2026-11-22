class_name InventoryComponent
extends Node2D

var inputInventory: Array = []
var outputInventory: Array = []

var inputCells: Array = []
var outputCells: Array = []
var additionalInputCells: Array = []
var additionalOutputCells: Array = []

var buildingResource: BuildingResource

func ready_input_cells() -> void:
	var inputs: Array[ItemSlot] = []
	var outputs: Array[ItemSlot] = []
	
	inputs.append_array(buildingResource.inputCells)
	inputs.append_array(additionalInputCells)
	outputs.append_array(buildingResource.outputCells)
	outputs.append_array(additionalOutputCells)
	
	for i: ItemSlot in inputs:
		var itemPos: Vector2i = i.cell
		var item: ItemResource = i.item
		
		inputCells.append({"cell": itemPos, "item": item, "inventory": []})
	
	for i: ItemSlot in outputs:
		var itemPos: Vector2i = i.cell
		var item: ItemResource = i.item
		
		outputCells.append({"cell": itemPos, "item": item, "inventory": []})

func add_input_cell(cell: Vector2i, item: ItemResource) -> void:
	var newSlot: ItemSlot = ItemSlot.new()
	newSlot.cell = cell
	newSlot.item = item
	
	additionalInputCells.append(newSlot)

func add_output_cell(cell: Vector2i, item: ItemResource) -> void:
	var newSlot: ItemSlot = ItemSlot.new()
	newSlot.cell = cell
	newSlot.item = item
	
	additionalOutputCells.append(newSlot)

func has_items(requiredItems: Array) -> bool:
	if requiredItems.size() == 0:
		return true
	
	var availableCounts: Dictionary = {}
	for slot: Dictionary in inputCells:
		if slot == null or slot.item == null or slot.inventory <= 0:
			continue
		if slot.item.itemName == "none":
			continue
		availableCounts[slot.item] = availableCounts.get(slot.item, 0) + slot.inventory
	
	# 2. Tally required quantities (handles duplicate items in requiredItems)
	var neededCounts: Dictionary = {}
	for req_item: ItemResource in requiredItems:
		if req_item == null or req_item.itemName == "none":
			continue
		neededCounts[req_item] = neededCounts.get(req_item, 0) + 1
	
	# 3. Verify every required item has enough stock
	for req_item: ItemResource in neededCounts.keys():
		if availableCounts.get(req_item, 0) < neededCounts[req_item]:
			return false
	
	return true
