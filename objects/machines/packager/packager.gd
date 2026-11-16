class_name Packager
extends Building

func _ready() -> void:
	super()
	
	validOutputBuildings = [Belt]


func _on_tick():
	super()
	
	if toTransport is Belt and inputInventory.size() > 0:
		if toTransport.item == null:
			var item = inputInventory[0]
			toTransport.give_item(item)
			inputInventory.erase(item)
