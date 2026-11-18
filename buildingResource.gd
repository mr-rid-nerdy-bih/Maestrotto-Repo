class_name BuildingResource
extends Resource

@export_group("Identity")
@export var building_name: String
@export var building_type: BuildingTypes.Type

@export var texture: Texture
@export var isAnimated: bool
@export var hframes: int = 1
@export var offset: Vector2
@export var frameTime: float

@export_group("Inventory Settings")
@export var maxInput: int = 10
@export var maxOutput: int = 10

@export_group("Transport Settings")
@export var validOutputBuildings: Array[BuildingTypes.Type] = []
@export var canUseBelt: bool = false
@export var passThroughInput: bool = false

@export_group("Can Generate")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var canGenerate: bool = false
@export var item: ItemResource
@export var inputItems: Array[ItemResource]
@export var needsInput: bool = false
@export var cooldown: float

func customBehavior(building: Building) -> void:
	pass
