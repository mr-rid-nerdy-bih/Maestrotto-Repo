class_name CraftComponent
extends Node2D

@export var inventoryComponent: InventoryComponent
@export var generateItemComponent: GenerateItemComponent
var buildingResource: BuildingResource

## First recipe whose inputs are available, or null.
## A recipe with no required items is always craftable (e.g. a drill).
func find_craftable_recipe() -> RecipeResource:
	if inventoryComponent == null or buildingResource == null:
		return null
	for recipe: RecipeResource in buildingResource.itemRecipes:
		if recipe and inventoryComponent.has_items(recipe.requiredItems):
			return recipe
	return null
