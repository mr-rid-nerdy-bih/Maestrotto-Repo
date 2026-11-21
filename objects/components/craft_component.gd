class_name CraftComponent
extends Node2D

@export var inventoryComponent: InventoryComponent
@export var generateItemComponent: GenerateItemComponent
var buildingResource: BuildingResource

func check_crafts():
	var accessibleMaterials :=  []
	for i: Item in inventoryComponent.inputInventory:
		var item := i.itemResource
		accessibleMaterials.append(item.itemName)

	for recipe: RecipeResource in buildingResource.itemRecipes:
		var requiredMaterials: Array = recipe.requiredItems
		var hasAll: bool = requiredMaterials.all(func(item):
			var reqName := item.itemName if item is ItemResource else str(item)
			return accessibleMaterials.count(reqName) >= requiredMaterials.count(item))

		if hasAll:
			generateItemComponent.itemConsumed = recipe.requiredItems
			generateItemComponent.generateThis = recipe.outputItems
			return
