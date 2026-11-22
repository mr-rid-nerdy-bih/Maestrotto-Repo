class_name GenerateItemComponent
extends Node2D

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
	
	var recipeResults: Dictionary = craftComponent.check_crafts()
	var required: Array = recipeResults.get("requiredItems", [])
	var output: Array = recipeResults.get("outputItems", [])
	if required == null:
		required = []
	if output == null or output.is_empty():
		return
	
	if currentCooldown < buildingResource.cooldown:
		currentCooldown += 1.0
		return
	
	if not inventoryComponent.has_items(required):
		return
	
	if not _consume_required_items(required):
		return
	
	var newItems: Array[Item] = makeItem(output)
	for newItem: Item in newItems:
		var accepted: bool = transportComponent.move_into_inventory(newItem, true)
		print(accepted)
		if !accepted: newItem.queue_free()
	
	currentCooldown = 0.0

func _consume_required_items(required: Array) -> bool:
	for req: ItemResource in required:
		var item_res := req as ItemResource
		if item_res.any == "None" or item_res.itemName.to_lower() == "none":
			continue
		if not inventoryComponent.consume_item_resource(item_res, 1):
			return false
	return true

func makeItem(items: Array) -> Array[Item]:
	var returnItems: Array[Item] = []
	for entry: ItemResource in items:
		var item_res := entry as ItemResource
		if item_res.any == "None" or item_res.itemName.to_lower() == "none":
			continue
		var newItem: Item = itemScene.instantiate()
		newItem.itemResource = item_res
		returnItems.append(newItem)
	return returnItems
