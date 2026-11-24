class_name LinkingComponent
extends Node2D

@export var visualComponent: VisualComponent
@export var transportComponent: TransportComponent
var buildingResource: BuildingResource

@onready var links := get_tree().current_scene.get_node("Links")

func setLinkAtLinkGroup() -> void:
	var source := get_parent() as Building
	var target := transportComponent.toTransport
	if not target:
		links.links.erase(visualComponent.cell)
		return

	# Line goes FROM where items leave this building TO the target.
	var fromCell: Vector2i = visualComponent.cell
	if buildingResource.buildingType == BuildingTypes.Type.BELT:
		fromCell = source.cell1 # items leave a belt at its end
	var toCell: Vector2i = target.visualComponent.cell

	# Always overwrite, so re-linking to a different building moves the line.
	links.links[visualComponent.cell] = {
		"source": source,
		"target": target,
		"from": fromCell,
		"to": toCell,
		"endBuildingType": target.type,
		"startBuildingType": buildingResource.buildingType,
	}
