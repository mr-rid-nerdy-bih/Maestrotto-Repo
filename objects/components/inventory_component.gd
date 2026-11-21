class_name InventoryComponent
extends Node2D

var inputInventory: Array = []
var outputInventory: Array = []

var inputCells: Array = []
var outputCells: Array = []

var buildingResource: BuildingResource

func ready_input_cells() -> void:
	for i in buildingResource.inputCells:
		var itemPos: Vector2i = i.keys()[0]
		var itemSlot: ItemResource = i.values()[0]
		
		inputCells.append({"cell": itemPos, "itemResource": itemSlot, "inventory": []})
	
	for i in buildingResource.outputCells:
		var itemPos: Vector2i = i.keys()[0]
		var itemSlot: ItemResource = i.values()[0]
		
		outputCells.append({"cell": itemPos, "itemResource": itemSlot, "inventory": []})
