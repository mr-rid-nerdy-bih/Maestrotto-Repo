class_name ItemResource
extends Resource
## Data for one item type: name, description and sprite frame.

@export var itemName: String
@export_multiline var description: String
## Frame on the items sprite sheet.
@export var frame: int
## Specific = this exact item. Any = wildcard (slot/recipe accepts anything).
## None = placeholder meaning "no item".
@export_enum("Specific", "Any", "None") var any: String = "Specific"

## True for the "Any" item used as an accept-anything filter.
func is_wildcard() -> bool:
	return any == "Any"

## True for placeholder "no item" entries, which recipes ignore.
func is_nothing() -> bool:
	return any == "None" or itemName.to_lower() == "none"
