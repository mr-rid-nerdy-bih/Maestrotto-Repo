class_name GenerateItemComponent
extends Node2D

@onready var buildingResource: BuildingResource = get_parent().buildingResource
@onready var itemScene: PackedScene = preload("uid://cydebobvt4np8")

@export var inventoryComponent: InventoryComponent
var currentCooldown = 0

func generate():
	if !buildingResource.canGenerate:
		return
	
	var inactive: bool = false
	if currentCooldown < buildingResource.cooldown:
		currentCooldown += 1
	else:
		if inventoryComponent.outputInventory.size() < buildingResource.maxOutput:
			var newItem: Item = itemScene.instantiate()
			newItem.itemResource = buildingResource.item
			inventoryComponent.outputInventory.append(newItem)
			print("yesboi")
			
			currentCooldown = 0
		else:
			inactive = true
	return inactive
