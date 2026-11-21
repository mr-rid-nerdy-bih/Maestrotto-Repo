class_name LinkingComponent
extends Node2D

@export var visualComponent: VisualComponent
@export var transportComponent: TransportComponent
var buildingResource: BuildingResource

@onready var links := get_tree().current_scene.get_node("Links")

func setLinkAtLinkGroup() -> void:
	if !transportComponent.toTransport:
		if links.links.has(visualComponent.cell):
			links.links.erase(visualComponent.cell)
		return
	
	if !links.links.has(visualComponent.cell):
		links.links.set(visualComponent.cell, {"endBuildingType": transportComponent.toTransport.type, "startBuildingType": buildingResource.buildingType, "from": visualComponent.cell, "to": transportComponent.toTransport.visualComponent.cell})
