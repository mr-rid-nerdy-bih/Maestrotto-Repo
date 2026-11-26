class_name TransportComponent
extends Node2D
## Moves items between buildings. One rule: the RECEIVER decides whether it
## accepts an item (can_receive). The sender never reaches into the receiver's
## inventory or checks what type of building it is.

const Side := InventoryComponent.Side

@export var inventoryComponent: InventoryComponent
@export var visualComponent: VisualComponent
var buildingResource: BuildingResource

## Where each output cell sends its items: output slot cell -> target Building.
## Buildings with no outputCells configured (and belts) use Vector2i.ZERO.
var toTransport: Dictionary[Vector2i, Building] = {}

## Called once per tick by Building.
func transport_to() -> void:
	prune_targets()
	if buildingResource and buildingResource.passThroughInput:
		pass_through()
	if not toTransport.is_empty():
		push_outputs()

## Drops links to buildings that have been freed.
func prune_targets() -> void:
	for outputCell: Vector2i in toTransport.keys():
		if not is_instance_valid(toTransport[outputCell]):
			toTransport.erase(outputCell)

## The building linked to [param outputCell], or null.
func get_target(outputCell: Vector2i = Vector2i.ZERO) -> Building:
	# Read as Variant first: assigning a freed building to a typed var errors.
	var target: Variant = toTransport.get(outputCell)
	return target if is_instance_valid(target) else null

## Links [param outputCell] to [param building]. Pass null to unlink it.
func set_target(outputCell: Vector2i, building: Building) -> void:
	if building == null:
		toTransport.erase(outputCell)
	else:
		toTransport[outputCell] = building

## Every output cell this building can link from (one per distinct slot cell).
func get_output_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if inventoryComponent == null:
		return cells
	for slot: InventorySlot in inventoryComponent.get_slots(Side.OUTPUT):
		if not cells.has(slot.cell):
			cells.append(slot.cell)
	if cells.is_empty():
		cells.append(Vector2i.ZERO)
	return cells

## Output cells currently linked to [param building].
func get_cells_linked_to(building: Building) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for outputCell: Vector2i in toTransport:
		if toTransport[outputCell] == building:
			cells.append(outputCell)
	return cells

## Input -> output, for buildings that don't craft (chute, canister, packager).
func pass_through() -> void:
	for item: Item in inventoryComponent.get_items(Side.INPUT):
		if not inventoryComponent.can_insert(item.itemResource, Side.OUTPUT):
			break
		inventoryComponent.remove(item, Side.INPUT)
		inventoryComponent.insert(item, Side.OUTPUT)

## Sends each output slot's items, oldest first, to that slot's linked building.
## A refused item is skipped rather than blocking the rest, so one stuck item
## type never holds up the others.
func push_outputs() -> void:
	for slot: InventorySlot in inventoryComponent.get_slots(Side.OUTPUT):
		if get_target(slot.cell) == null:
			continue
		slot.prune_invalid()
		for item: Item in slot.items.duplicate():
			send(item, Side.OUTPUT, slot.cell)

## Hands one item to the building linked to [param outputCell]. Returns false
## (and keeps the item) if there's no target or the target refuses it.
func send(item: Item, fromSide: int = Side.OUTPUT, outputCell: Vector2i = Vector2i.ZERO) -> bool:
	var target := get_target(outputCell)
	if target == null or target.transportComponent == null:
		return false
	var receiver := target.transportComponent
	if not receiver.can_receive(item):
		return false
	inventoryComponent.remove(item, fromSide)
	receiver.receive(item)
	return true

## Asks this building whether it can take [param item] right now.
func can_receive(item: Item) -> bool:
	if not is_instance_valid(item) or inventoryComponent == null:
		return false
	var building := get_parent() as Building
	if building and not building.can_receive_item(item):
		return false
	return inventoryComponent.can_insert(item.itemResource, Side.INPUT)

## Takes [param item] into the input side. Returns false if it can't.
func receive(item: Item) -> bool:
	if not can_receive(item):
		return false
	if item.get_parent():
		item.get_parent().remove_child(item)
	inventoryComponent.insert(item, Side.INPUT)
	var building := get_parent() as Building
	if building:
		building.on_item_received(item)
	return true
