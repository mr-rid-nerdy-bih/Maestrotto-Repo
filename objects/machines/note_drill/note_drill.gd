class_name NoteDrill
extends Building

var note = preload("uid://dpayacqnjuaht")
@export var cooldown: int

var currentCooldown = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	validOutputBuildings = [Packager]
	isActive = true

func _on_tick():
	super()
	
	if isActive:
		if currentCooldown < cooldown:
			currentCooldown += 1
		else:
			if outputInventory.size() < maxOutput:
				stopAnim = false
				
				var newNote = note.instantiate()
				outputInventory.append(newNote)
				
				currentCooldown = 0
				print("Output inventory has ", outputInventory.size(), " notes.")
			else:
				stopAnim = true
		
		if toTransport and outputInventory.size() > 0 and toTransport.inputInventory.size() <= toTransport.maxInput:
			var targetItem = outputInventory[0]
			toTransport.inputInventory.append(targetItem)
			outputInventory.erase(targetItem)
