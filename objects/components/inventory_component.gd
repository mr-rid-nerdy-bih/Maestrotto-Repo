class_name InventoryComponent
extends Node2D
## Owns every item a building holds. Nothing else should touch the slot
## arrays directly — go through insert / remove / get_items / consume.

enum Side { INPUT, OUTPUT }

var buildingResource: BuildingResource

var inputSlots: Array[InventorySlot] = []
var outputSlots: Array[InventorySlot] = []

## Builds the runtime slots from the BuildingResource. Safe to call again.
## A building with no slots configured gets one "accept anything" slot per side,
## so simple pass-through buildings (chute, canister, belt) work with zero setup.
func setup() -> void:
	var maxIn := buildingResource.maxInput if buildingResource else 10
	var maxOut := buildingResource.maxOutput if buildingResource else 10
	var inDefs: Array[ItemSlot] = buildingResource.inputCells if buildingResource else ([] as Array[ItemSlot])
	var outDefs: Array[ItemSlot] = buildingResource.outputCells if buildingResource else ([] as Array[ItemSlot])
	inputSlots = _make_slots(inDefs, maxIn)
	outputSlots = _make_slots(outDefs, maxOut)

func _make_slots(defs: Array[ItemSlot], capacity: int) -> Array[InventorySlot]:
	var result: Array[InventorySlot] = []
	for def: ItemSlot in defs:
		if def != null:
			result.append(InventorySlot.new(def.cell, def.item, capacity))
	if result.is_empty():
		result.append(InventorySlot.new(Vector2i.ZERO, null, capacity))
	return result

func _slots(side: int) -> Array[InventorySlot]:
	return inputSlots if side == Side.INPUT else outputSlots

# --- Insert / remove -------------------------------------------------------

func can_insert(res: ItemResource, side: int) -> bool:
	for slot: InventorySlot in _slots(side):
		if slot.accepts(res):
			return true
	return false

func insert(item: Item, side: int) -> bool:
	if not is_instance_valid(item):
		return false
	for slot: InventorySlot in _slots(side):
		if slot.accepts(item.itemResource):
			slot.items.append(item)
			return true
	return false

func remove(item: Item, side: int) -> bool:
	for slot: InventorySlot in _slots(side):
		var idx := slot.items.find(item)
		if idx != -1:
			slot.items.remove_at(idx)
			return true
	return false

## Returns a *copy* (oldest first), so callers can remove items while looping.
func get_items(side: int) -> Array[Item]:
	var result: Array[Item] = []
	for slot: InventorySlot in _slots(side):
		slot.prune_invalid()
		result.append_array(slot.items)
	return result

func is_empty(side: int) -> bool:
	return get_items(side).is_empty()

# --- Recipe helpers (input side) ------------------------------------------

func count(res: ItemResource) -> int:
	var total := 0
	for item: Item in get_items(Side.INPUT):
		if res == null or res.is_wildcard() or item.itemResource == res:
			total += 1
	return total

## True if the input side can satisfy a recipe's requirement list.
## "Nothing" entries are ignored, wildcard entries take any leftover item.
func has_items(required: Array[ItemResource]) -> bool:
	var specific: Dictionary[ItemResource, int] = {}
	var wildcards := 0
	for res: ItemResource in required:
		if res == null or res.is_nothing():
			continue
		if res.is_wildcard():
			wildcards += 1
		else:
			specific[res] = specific.get(res, 0) + 1

	var specificTotal := 0
	for res: ItemResource in specific:
		if count(res) < specific[res]:
			return false
		specificTotal += specific[res]
	return get_items(Side.INPUT).size() >= specificTotal + wildcards

## Removes and frees the required items. Call has_items() first.
func consume(required: Array[ItemResource]) -> void:
	var wildcards := 0
	for res: ItemResource in required:
		if res == null or res.is_nothing():
			continue
		if res.is_wildcard():
			wildcards += 1
			continue
		for item: Item in get_items(Side.INPUT):
			if item.itemResource == res:
				_destroy(item)
				break
	for i in wildcards:
		var left := get_items(Side.INPUT)
		if left.is_empty():
			break
		_destroy(left[0])

func _destroy(item: Item) -> void:
	remove(item, Side.INPUT)
	item.queue_free()

# --- Cleanup / debug -------------------------------------------------------

## Items sitting inside a machine are not in the scene tree, so Godot would
## never free them. Free them ourselves when the building is deleted.
func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	for slot: InventorySlot in inputSlots + outputSlots:
		for item: Item in slot.items:
			if is_instance_valid(item) and item.get_parent() == null:
				item.free()

func debug_string() -> String:
	return "in: %d %s | out: %d %s" % [
		get_items(Side.INPUT).size(), _names(Side.INPUT),
		get_items(Side.OUTPUT).size(), _names(Side.OUTPUT),
	]

func _names(side: int) -> Array[String]:
	var names: Array[String] = []
	for item: Item in get_items(side):
		names.append(item.itemResource.itemName if item.itemResource else "?")
	return names
