class_name GenerateItemComponent
extends Node2D
## Crafts items: waits out the cooldown, consumes the recipe's inputs and
## puts the outputs into the output slots.

const Side := InventoryComponent.Side

@onready var itemScene: PackedScene = preload("uid://cydebobvt4np8")

@export var inventoryComponent: InventoryComponent
@export var transportComponent: TransportComponent
@export var craftComponent: CraftComponent
var buildingResource: BuildingResource

## Ticks waited since the last craft.
var currentCooldown: float = 0.0

## Called every tick. Crafts once the cooldown is done and there's room.
func generate() -> void:
	if buildingResource == null or not buildingResource.canGenerate:
		return
	if craftComponent == null or inventoryComponent == null:
		return

	var recipe := craftComponent.find_craftable_recipe()
	if recipe == null:
		return

	if currentCooldown < buildingResource.cooldown * recipe.cooldownMult:
		currentCooldown += 1.0
		return

	# Check for room BEFORE consuming, so a full machine never eats its inputs.
	if not has_room_for(recipe.outputItems):
		return

	inventoryComponent.consume(recipe.requiredItems)
	for res: ItemResource in recipe.outputItems:
		if res == null or res.is_nothing():
			continue
		var newItem := make_item(res)
		apply_notation(newItem, recipe.outputNotation)
		# has_room_for() checks each output on its own, so a recipe with
		# several outputs can still overflow a slot. The item was never added
		# to the tree, so free it here or it leaks.
		if not inventoryComponent.insert(newItem, Side.OUTPUT):
			newItem.free()

	currentCooldown = 0.0

## True if every output item fits in the output slots.
func has_room_for(outputs: Array[ItemResource]) -> bool:
	# Checks each output on its own, so several outputs sharing one slot can
	# still overflow it. generate() frees any item that doesn't fit.
	for res: ItemResource in outputs:
		if res and not res.is_nothing() and not inventoryComponent.can_insert(res, Side.OUTPUT):
			return false
	return true

## Copies [param notation] onto [param item]'s data. Resources are duplicated
## so changing one item's notation later never changes the recipe or other items.
func apply_notation(item: Item, notation: Dictionary[String, Resource]) -> void:
	for key: String in notation:
		var value: Resource = notation[key]
		item.data[key] = value.duplicate() if value else null

## Creates a new Item node of type [param res] (not added to the tree).
func make_item(res: ItemResource) -> Item:
	var newItem: Item = itemScene.instantiate()
	newItem.itemResource = res
	return newItem
