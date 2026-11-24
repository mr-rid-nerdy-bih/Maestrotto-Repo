class_name BuildingResource
extends Resource
## Everything that defines a building type. Drop a .tres of this into
## res://objects/machines/ and GridManager picks it up automatically.

@export_group("Identity")
@export var buildingName: String
@export var buildingType: BuildingTypes.Type

@export_group("Visual")
@export var texture: Texture
@export var isAnimated: bool
@export var hframes: int = 1
@export var offset: Vector2 = Vector2.ZERO
## Ticks per animation frame.
@export var frameTime: float
@export_subgroup("Four Directions")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var fourDirections: bool = false

@export_group("Inventory Settings")
## Capacity of each input slot.
@export var maxInput: int = 10
## Capacity of each output slot.
@export var maxOutput: int = 10
## Input slots. Leave empty for one slot that accepts anything.
@export var inputCells: Array[ItemSlot]
## Output slots. Leave empty for one slot that accepts anything.
@export var outputCells: Array[ItemSlot]

@export_group("Transport Settings")
## Building types this one is allowed to link to.
@export var validOutputBuildings: Array[BuildingTypes.Type] = []
## Moves inputs straight to outputs every tick. Leave off for crafters.
@export var passThroughInput: bool = false

@export_group("Can Generate")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var canGenerate: bool = false
## Ticks between crafts.
@export var cooldown: float
@export_subgroup("Recipes")
@export var itemRecipes: Array[RecipeResource]

@export_group("Custom Behavior")
## Optional script with a custom_behavior(building) function, run every tick.
@export var customBehavior: Script
@export var customBehaviorUsesProcess: bool = false

## Runs the custom behaviour script for [param building], creating it if needed.
func custom_behavior(building: Building) -> void:
	var instance = building.behaviorInstance
	if not instance and customBehavior:
		instance = customBehavior.new()
		building.behaviorInstance = instance
	
	if instance and instance.has_method("custom_behavior"):
		instance.custom_behavior(building)
