class_name Chute
extends Building

func _ready() -> void:
	super()
	
	validOutputBuildings = [CopperCanister]


func _on_tick():
	super()
	
	transport_to(true)
