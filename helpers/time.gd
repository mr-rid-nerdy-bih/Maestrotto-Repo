extends Timer
## Autoload game clock. Emits [signal ticked] on every Timer timeout
## (see the Timer node in game.tscn for the tick rate).

@onready var game := get_tree().current_scene
@onready var timer := game.get_node("Timer")

## Number of ticks since the game started.
var tick := 0
signal ticked

func _ready() -> void:
	timer.timeout.connect(on_timeout)

func on_timeout() -> void:
	tick += 1
	ticked.emit()
