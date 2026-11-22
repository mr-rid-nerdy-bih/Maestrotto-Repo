class_name CraftComponent
extends Node2D

@export var inventoryComponent: InventoryComponent
@export var generateItemComponent: GenerateItemComponent
var buildingResource: BuildingResource

func check_crafts() -> Dictionary:
	if inventoryComponent == null or generateItemComponent == null or buildingResource == null:
		return {"requiredItems": null, "outputItems": null}
	
	var availableCounts: Dictionary = {}
	for slot: Dictionary in inventoryComponent.inputCells:
		if slot == null or slot.item == null:
			continue
		availableCounts[slot.item] = availableCounts.get(slot.item, 0) + slot.inventory.size()
	
	for recipe: RecipeResource in buildingResource.itemRecipes:
		if recipe == null:
			continue
		
		var requiredMaterials: Array = recipe.requiredItems
		var neededCounts: Dictionary = {}
		for reqItem: ItemResource in requiredMaterials:
			if reqItem.any == "None":
				return {"requiredItems": [], "outputItems": recipe.outputItems}
			neededCounts[reqItem] = neededCounts.get(reqItem, 0) + 1
		
		var hasAll := true
		for reqItem: ItemResource in neededCounts.keys():
			if availableCounts.get(reqItem, 0) < neededCounts[reqItem]:
				hasAll = false
				break
		
		if hasAll:
			var requiredItems: Array[ItemResource] = recipe.requiredItems
			var outputItems: Array[ItemResource] = recipe.outputItems
			return {
				"requiredItems": requiredItems,
				"outputItems": outputItems
			}
	
	return {"requiredItems": null, "outputItems": null}

func build_recipe_map(recipe: RecipeResource) -> Dictionary[ItemResource, int]:
	var map: Dictionary[ItemResource, int] = {}
	if recipe == null:
		return map
	for item in recipe.requiredItems:
		if item is ItemResource and item.itemName != "none":
			map[item] = map.get(item, 0) + 1
	return map
