class_name ItemResource
extends Resource

@export var itemName: String
@export_multiline var description: String
@export var frame: int
## Specific = this exact item. Any = wildcard (slot/recipe accepts anything).
## None = placeholder meaning "no item".
@export_enum("Specific", "Any", "None") var any: String = "Specific"

func is_wildcard() -> bool:
	return any == "Any"

func is_nothing() -> bool:
	return any == "None" or itemName.to_lower() == "none"
