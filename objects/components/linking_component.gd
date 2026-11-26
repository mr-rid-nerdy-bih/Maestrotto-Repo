class_name LinkingComponent
extends Node2D
## Registers this building's links with the Links node so lines get drawn.
## One entry per linked output cell.

@export var visualComponent: VisualComponent
@export var transportComponent: TransportComponent
var buildingResource: BuildingResource

@onready var links := get_tree().current_scene.get_node("Links")

## Rebuilds every entry for this building in Links.links from toTransport.
func set_link_at_link_group() -> void:
	var source := get_parent() as Building

	# Drop this building's old entries, then add one per current link, so
	# unlinking or re-linking an output cell moves or removes its line.
	for key in links.links.keys():
		if links.links[key].get("source") == source:
			links.links.erase(key)

	for outputCell: Vector2i in transportComponent.toTransport:
		var target := transportComponent.get_target(outputCell)
		if target == null:
			continue

		# Line goes FROM where items leave this building TO the target.
		var fromCell: Vector2i = visualComponent.cell + outputCell
		if buildingResource.buildingType == BuildingTypes.Type.BELT:
			fromCell = source.cell1 # items leave a belt at its end
		var toCell: Vector2i = target.visualComponent.cell

		links.links[link_key(outputCell)] = {
			"source": source,
			"target": target,
			"outputCell": outputCell,
			"from": fromCell,
			"to": toCell,
			"endBuildingType": target.type,
			"startBuildingType": buildingResource.buildingType,
		}

## Unique key in Links.links for this building's [param outputCell].
func link_key(outputCell: Vector2i) -> String:
	return "%s|%s" % [visualComponent.cell, outputCell]
