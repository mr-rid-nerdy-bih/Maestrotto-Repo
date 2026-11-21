class_name GenerateItemComponent
extends Node2D

@onready var itemScene: PackedScene = preload("uid://cydebobvt4np8")

@export var inventoryComponent: InventoryComponent
var buildingResource: BuildingResource

var generateThis: Array[ItemResource]
var currentCooldown: float = 0

func generate() -> void:
	if !buildingResource.canGenerate:
		return
	
	if currentCooldown < buildingResource.cooldown:
		currentCooldown += 1
	else:
		if inventoryComponent.outputInventory.size() < buildingResource.maxOutput:
			var newItems: Array = makeItem(generateThis)
			
			for newItem: Item in newItems:
				inventoryComponent.outputInventory.append(newItem)
			
			currentCooldown = 0

func makeItem(items: Array) -> Array:
	var returnItems: Array = []
	for i: ItemResource in items:
		var newItem: Item = itemScene.instantiate()
		newItem.itemResource = buildingResource.item
		returnItems.append(newItem)
	
	return returnItems
