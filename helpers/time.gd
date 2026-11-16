extends Timer

@onready var game = get_tree().current_scene
@onready var timer = game.get_node("Timer")

var tick = 0
signal ticked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.timeout.connect(_on_timeout)

func _on_timeout():
	tick += 1
	ticked.emit()
