class_name InventoryComponent
extends Node2D

var inputInventory: Array[Item] = []
var outputInventory: Array[Item] = []

var inputCells: Array[Dictionary] = []
var outputCells: Array[Dictionary] = []
var additionalInputCells: Array[ItemSlot] = []
var additionalOutputCells: Array[ItemSlot] = []

var buildingResource: BuildingResource

func ready_input_cells() -> void:
	push_warning("ready_input_cells called on ", get_parent(), " with existing inputCells: ", inputCells)
	inputCells.clear()
	outputCells.clear()
	
	var inputs: Array[ItemSlot] = []
	var outputs: Array[ItemSlot] = []
	
	if buildingResource:
		inputs.append_array(buildingResource.inputCells)
		outputs.append_array(buildingResource.outputCells)
	inputs.append_array(additionalInputCells)
	outputs.append_array(additionalOutputCells)
	
	for slot: ItemSlot in inputs:
		if slot == null:
			continue
		inputCells.append({
			"cell": slot.cell,
			"item": slot.item,
			"inventory": [] as Array[Item],
		})
	
	for slot: ItemSlot in outputs:
		if slot == null:
			continue
		outputCells.append({
			"cell": slot.cell,
			"item": slot.item,
			"inventory": [] as Array[Item],
		})

func add_input_cell(cell: Vector2i, item: ItemResource) -> void:
	var newSlot: ItemSlot = ItemSlot.new()
	newSlot.cell = cell
	newSlot.item = item
	additionalInputCells.append(newSlot)
	
	ready_input_cells()

func add_output_cell(cell: Vector2i, item: ItemResource) -> void:
	var newSlot: ItemSlot = ItemSlot.new()
	newSlot.cell = cell
	newSlot.item = item
	additionalOutputCells.append(newSlot)

func get_total_count(target: ItemResource) -> int:
	if target == null:
		return 0
	var total := 0
	for slot: Dictionary in inputCells:
		var slot_inv: Array = slot.get("inventory", [])
		for item: Item in slot_inv:
			if item.itemResource == target:
				total += 1
	for item in inputInventory:
		if item.itemResource == target:
			total += 1
	return total

func consume_item_resource(target: ItemResource, amount: int = 1) -> bool:
	if target == null or amount <= 0:
		return true
	if get_total_count(target) < amount:
		return false
	
	var remaining := amount
	for slot: Dictionary in inputCells:
		var slot_inv: Array = slot.get("inventory", [])
		for i in range(slot_inv.size() - 1, -1, -1):
			if remaining <= 0:
				break
			var item: Item = slot_inv[i]
			if item.itemResource == target:
				slot_inv.remove_at(i)
				item.queue_free()
				remaining -= 1
	
	for i in range(inputInventory.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var item: Item = inputInventory[i]
		if item.itemResource == target:
			inputInventory.remove_at(i)
			item.queue_free()
			remaining -= 1
	
	return remaining == 0

func has_items(requiredItems: Array) -> bool:
	if requiredItems.is_empty():
		return true
	
	var neededCounts: Dictionary = {}
	for entry: ItemResource in requiredItems:
		if entry.any == "None" or entry.itemName.to_lower() == "none":
			continue
		neededCounts[entry] = neededCounts.get(entry, 0) + 1
	
	if neededCounts.is_empty():
		return true
	
	for item: ItemResource in neededCounts.keys():
		if get_total_count(item) < neededCounts[item]:
			return false
	
	return true
