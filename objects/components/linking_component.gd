class_name LinkingComponent
extends Node2D

@export var visualComponent: VisualComponent
@export var transportComponent: TransportComponent
@onready var buildingResource: BuildingResource = get_parent().buildingResource
@onready var links = get_tree().current_scene.get_node("Links")

func setLinkAtLinkGroup():
	if !transportComponent.toTransport:
		if links.links.has(visualComponent.cell):
			links.links.erase(visualComponent.cell)
		return
	
	if transportComponent.toTransport.type == BuildingTypes.Type.BELT:
		links.links.set(visualComponent.cell, {"endBuildingType": transportComponent.toTransport.type, "startBuildingType": buildingResource.building_type, "from": visualComponent.cell, "to": transportComponent.toTransport.cell})
	
	if !links.links.has(visualComponent.cell):
		links.links.set(visualComponent.cell, {"endBuildingType": transportComponent.toTransport.type, "startBuildingType": buildingResource.building_type, "from": visualComponent.cell, "to": transportComponent.toTransport.visualComponent.cell})
