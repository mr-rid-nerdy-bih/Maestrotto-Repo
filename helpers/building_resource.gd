class_name BuildingResource
extends Resource

@export_group("Identity")
@export var buildingName: String
@export var buildingType: BuildingTypes.Type

@export_group("Visual")
@export var texture: Texture
@export var isAnimated: bool
@export var hframes: int = 1
@export var offset: Vector2
@export var frameTime: float

@export_group("Inventory Settings")
@export var maxInput: int = 10
@export var maxOutput: int = 10
@export var inputCells: Array[Dictionary]
@export var outputCells: Array[Dictionary]

@export_group("Transport Settings")
@export var validOutputBuildings: Array[BuildingTypes.Type] = []
@export var passThroughInput: bool = false

@export_group("Can Generate")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var canGenerate: bool = false
@export var item: ItemResource
@export var cooldown: float
@export_subgroup("Recipes")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var hasRecipes: bool = false
@export var itemRecipes: Array[RecipeResource]

@export_group("Custom Behavior")
@export var customBehavior: Script
@export var customBehaviorUsesProcess: bool = false

func custom_behavior(building: Building) -> void:
	var instance = building.behaviorInstance
	if not instance and customBehavior:
		instance = customBehavior.new()
		building.behaviorInstance = instance
	
	if instance and instance.has_method("custom_behavior"):
		instance.custom_behavior(building)
