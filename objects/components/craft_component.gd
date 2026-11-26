class_name CraftComponent
extends Node2D
## Picks which recipe a building can craft right now.

@export var inventoryComponent: InventoryComponent
@export var generateItemComponent: GenerateItemComponent
var buildingResource: BuildingResource

<<<<<<< Updated upstream
## Additional Recipes
var additionalRecipes: Array[RecipeResource]
=======
# Additional Recipes
var additionalRecipes: Array = []
>>>>>>> Stashed changes

## First recipe whose inputs are available, or null.
## A recipe with no required items is always craftable (e.g. a drill).
func find_craftable_recipe() -> RecipeResource:
	var recipes: Array = []
<<<<<<< Updated upstream
	recipes.append(additionalRecipes)
	recipes.append(buildingResource.itemRecipes)
=======
	recipes.append_array(additionalRecipes)
	recipes.append_array(buildingResource.itemRecipes)
>>>>>>> Stashed changes
	
	if inventoryComponent == null or buildingResource == null:
		return null
	for recipe: RecipeResource in recipes:
		if recipe and inventoryComponent.has_items(recipe.requiredItems):
			return recipe
	return null
