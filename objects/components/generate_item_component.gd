class_name GenerateItemComponent
extends Node2D

@onready var itemScene: PackedScene = preload("uid://cydebobvt4np8")

@export var inventoryComponent: InventoryComponent
@export var transportComponent: TransportComponent
@export var craftComponent: CraftComponent
var buildingResource: BuildingResource

var currentCooldown: float = 0

func generate() -> void:
	if !buildingResource.canGenerate:
		return
	
	var recipeResults: Dictionary = craftComponent.check_crafts()
	var required: Array = recipeResults.requiredItems
	var output: Array = recipeResults.outputItems
	if currentCooldown < buildingResource.cooldown:
		currentCooldown += 1
	else:
		if inventoryComponent.has_items(required):
			var newItems: Array = makeItem(output)
			
			for newItem: Item in newItems:
				transportComponent.move_into_inventory(newItem)
		
		currentCooldown = 0

func makeItem(items: Array) -> Array:
	var returnItems: Array = []
	for i: ItemResource in items:
		var newItem: Item = itemScene.instantiate()
		newItem.itemResource = i
		returnItems.append(newItem)
		print(newItem)
	
	return returnItems
