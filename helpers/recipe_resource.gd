class_name RecipeResource
extends Resource
## One crafting recipe: consumes requiredItems, produces outputItems.
## Leave requiredItems empty for a generator (e.g. a drill).

@export var requiredItems: Array[ItemResource]
@export var outputItems: Array[ItemResource]
## Multiplies the building's cooldown for this recipe.
@export var cooldownMult: float = 1.00
