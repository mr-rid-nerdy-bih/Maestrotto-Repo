extends Node2D

@onready var top: Line2D = $Top
@onready var bottom: Line2D = $Bottom
@onready var left: Line2D = $Left
@onready var right: Line2D = $Right

func _ready() -> void:
	# Configure default look for all lines
	for line in [top, bottom, left, right]:
		line.width = 2.0
		line.z_index = 30 # Ensure it renders above buildings and belts

func _process(_delta: float) -> void:
	# Only show when in build mode (adjust condition based on your InputManager mode)
	if InputManager.currentMode == 0: # Assuming 1 is build mode
		visible = false
		return
	
	visible = true
	
	for line: Line2D in [top, bottom, left, right]:
		match InputManager.currentMode:
			1: line.default_color = Color.GREEN
			2: line.default_color = Color.RED
			3: line.default_color = Color.ORANGE
	
	# Get current cell and compute world bounds
	var worldMousePos: Vector2 = GridManager.cam.get_global_mouse_position()
	var cell := GridManager.get_coords_at(worldMousePos)
	var size := float(GridManager.CELL_SIZE)
	
	var p0 := Vector2(cell) * size # Top-Left
	var p1 := p0 + Vector2(size, 0.0) # Top-Right
	var p2 := p0 + Vector2(0.0, size) # Bottom-Left
	var p3 := p0 + Vector2(size, size) # Bottom-Right
	
	# Assign points to the 4 lines
	top.clear_points()
	top.add_point(p0)
	top.add_point(p1)
	
	bottom.clear_points()
	bottom.add_point(p2)
	bottom.add_point(p3)
	
	left.clear_points()
	left.add_point(p0)
	left.add_point(p2)
	
	right.clear_points()
	right.add_point(p1)
	right.add_point(p3)
