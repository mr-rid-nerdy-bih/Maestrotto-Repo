class_name Packager
extends Building

func _ready() -> void:
	super()
	
	validOutputBuildings = [Belt,Chute]


func _on_tick():
	super()
	
	transport_to(true)
