class_name CopperCanister
extends Building


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	maxInput = 40
	validOutputBuildings = [Packager]


func _on_tick():
	super()
	
	transport_to(true)
