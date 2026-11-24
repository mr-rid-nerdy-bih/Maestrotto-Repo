class_name TransportComponent
extends Node2D
## Moves items between buildings. One rule: the RECEIVER decides whether it
## accepts an item (can_receive). The sender never reaches into the receiver's
## inventory or checks what type of building it is.

const Side := InventoryComponent.Side

@export var inventoryComponent: InventoryComponent
@export var visualComponent: VisualComponent
var buildingResource: BuildingResource

var toTransport: Building

## Called once per tick by Building.
func transport_to() -> void:
	if not is_instance_valid(toTransport):
		toTransport = null
	if buildingResource and buildingResource.passThroughInput:
		_pass_through()
	if toTransport:
		push_outputs()

## Input -> output, for buildings that don't craft (chute, canister, packager).
func _pass_through() -> void:
	for item: Item in inventoryComponent.get_items(Side.INPUT):
		if not inventoryComponent.can_insert(item.itemResource, Side.OUTPUT):
			break
		inventoryComponent.remove(item, Side.INPUT)
		inventoryComponent.insert(item, Side.OUTPUT)

## Sends output items, oldest first, until the target is full.
func push_outputs() -> void:
	for item: Item in inventoryComponent.get_items(Side.OUTPUT):
		if not send(item, Side.OUTPUT):
			break

## Hands one item to the linked building. Returns false (and keeps the item)
## if there's no target or the target is full.
func send(item: Item, fromSide: int = Side.OUTPUT) -> bool:
	if not is_instance_valid(toTransport) or toTransport.transportComponent == null:
		return false
	var receiver := toTransport.transportComponent
	if not receiver.can_receive(item):
		return false
	inventoryComponent.remove(item, fromSide)
	receiver.receive(item)
	return true

func can_receive(item: Item) -> bool:
	if not is_instance_valid(item) or inventoryComponent == null:
		return false
	var building := get_parent() as Building
	if building and not building.can_receive_item(item):
		return false
	return inventoryComponent.can_insert(item.itemResource, Side.INPUT)

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
