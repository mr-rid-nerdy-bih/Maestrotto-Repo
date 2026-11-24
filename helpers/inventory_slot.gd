class_name InventorySlot
extends RefCounted
## One runtime slot inside an InventoryComponent.
## (ItemSlot is the *design-time* Resource you fill in the inspector;
##  InventorySlot is the *runtime* object that actually holds Item nodes.)

## Where on the building this slot sits (not used for logic yet).
var cell: Vector2i
var filter: ItemResource ## null or a wildcard item = accepts anything
## Max number of items this slot holds.
var capacity: int
## Items in the slot, oldest first.
var items: Array[Item] = []

func _init(slotCell: Vector2i = Vector2i.ZERO, slotFilter: ItemResource = null, slotCapacity: int = 10) -> void:
	cell = slotCell
	filter = slotFilter
	capacity = slotCapacity

## True if an item of type [param res] fits here (filter matches and not full).
func accepts(res: ItemResource) -> bool:
	if res == null or items.size() >= capacity:
		return false
	if filter == null or filter.is_wildcard():
		return true
	return res == filter

## Removes references to items that have been freed.
func prune_invalid() -> void:
	for i in range(items.size() - 1, -1, -1):
		if not is_instance_valid(items[i]):
			items.remove_at(i)
