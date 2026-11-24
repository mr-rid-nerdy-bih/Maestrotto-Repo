class_name GenerateItemComponent
extends Node2D

const Side := InventoryComponent.Side

@onready var itemScene: PackedScene = preload("uid://cydebobvt4np8")

@export var inventoryComponent: InventoryComponent
@export var transportComponent: TransportComponent
@export var craftComponent: CraftComponent
var buildingResource: BuildingResource

var currentCooldown: float = 0.0

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
	if not _has_room_for(recipe.outputItems):
		return

	inventoryComponent.consume(recipe.requiredItems)
	for res: ItemResource in recipe.outputItems:
		if res == null or res.is_nothing():
			continue
		inventoryComponent.insert(make_item(res), Side.OUTPUT)

	currentCooldown = 0.0

func _has_room_for(outputs: Array[ItemResource]) -> bool:
	# Good enough for 1-item outputs; multi-output recipes into one slot
	# would need a proper "free space" count.
	for res: ItemResource in outputs:
		if res and not res.is_nothing() and not inventoryComponent.can_insert(res, Side.OUTPUT):
			return false
	return true

func make_item(res: ItemResource) -> Item:
	var newItem: Item = itemScene.instantiate()
	newItem.itemResource = res
	return newItem
