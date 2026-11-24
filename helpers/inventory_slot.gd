class_name InventorySlot
extends RefCounted
## One runtime slot inside an InventoryComponent.
## (ItemSlot is the *design-time* Resource you fill in the inspector;
##  InventorySlot is the *runtime* object that actually holds Item nodes.)

var cell: Vector2i
var filter: ItemResource ## null or a wildcard item = accepts anything
var capacity: int
var items: Array[Item] = []

func _init(slotCell: Vector2i = Vector2i.ZERO, slotFilter: ItemResource = null, slotCapacity: int = 10) -> void:
	cell = slotCell
	filter = slotFilter
	capacity = slotCapacity

func accepts(res: ItemResource) -> bool:
	if res == null or items.size() >= capacity:
		return false
	if filter == null or filter.is_wildcard():
		return true
	return res == filter

func prune_invalid() -> void:
	for i in range(items.size() - 1, -1, -1):
		if not is_instance_valid(items[i]):
			items.remove_at(i)
