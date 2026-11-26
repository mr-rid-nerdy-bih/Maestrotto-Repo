extends Node

func custom_behavior(building: Building) -> void:
	if !building: return
	
	var firstChar: String = building.buildingResource.buildingName[0]
	var secondChar: String = ""
	if building.buildingResource.buildingName[1] == "#": secondChar = building.buildingResource.buildingName[1]
	
	if secondChar != "":
		Pitches.get
