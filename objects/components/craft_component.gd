class_name CraftComponent
extends Node2D
## Picks which recipe a building can craft right now.

@export var inventoryComponent: InventoryComponent
@export var generateItemComponent: GenerateItemComponent
var buildingResource: BuildingResource

## Additional Recipes
var additionalRecipes: Array[RecipeResource]

## First recipe whose inputs are available, or null.
## A recipe with no required items is always craftable (e.g. a drill).
func find_craftable_recipe() -> RecipeResource:
	var recipes: Array = []
	recipes.append(additionalRecipes)
	recipes.append(buildingResource.itemRecipes)
	
	if inventoryComponent == null or buildingResource == null:
		return null
	for recipe: RecipeResource in recipes:
		if recipe and inventoryComponent.has_items(recipe.requiredItems):
			return recipe
	return null
