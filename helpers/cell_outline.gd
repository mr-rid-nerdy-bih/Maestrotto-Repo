extends Node2D
## Highlights what the mouse is pointing at; the colour shows the active mode.
## Machines get a shader outline around their sprite. Belts have no sprite
## (they're tiles), so they get a box around every cell they cover.
## In build mode the preview ghost outlines itself instead (see test.gd).

@onready var top: Line2D = $Top
@onready var bottom: Line2D = $Bottom
@onready var left: Line2D = $Left
@onready var right: Line2D = $Right

## The machine currently outlined, so its outline can be removed when the mouse leaves.
var outlinedBuilding: Building

func _ready() -> void:
	for line in [top, bottom, left, right]:
		line.width = 2.0
		line.z_index = ZLayers.CELL_OUTLINE

func _process(_delta: float) -> void:
	var mode: int = InputManager.currentMode
	var cell := GridManager.get_coords_at(GridManager.cam.get_global_mouse_position())

	var hoveredMachine: Building = null
	var hoveredBelt: Building = null
	if mode == 2 or mode == 3:
		var building := GridManager.get_building_at(cell)
		if building and building.type != BuildingTypes.Type.BELT:
			hoveredMachine = building
		else:
			hoveredBelt = GridManager.get_belt_at(cell)

	set_outlined_building(hoveredMachine, mode_color(mode))

	visible = hoveredBelt != null
	if hoveredBelt:
		set_line_color(mode_color(mode))
		draw_box(hoveredBelt.cell, hoveredBelt.cell1)

## Moves the shader outline to [param building] (or removes it when null).
func set_outlined_building(building: Building, color: Color) -> void:
	if outlinedBuilding != building and is_instance_valid(outlinedBuilding):
		outlinedBuilding.visualComponent.set_outline(false)
	outlinedBuilding = building
	if building:
		building.visualComponent.set_outline(true, color)

## Outline colour for each tool mode.
func mode_color(mode: int) -> Color:
	match mode:
		1: return Color.GREEN
		2: return Color.RED
		3: return Color.ORANGE
	return Color.WHITE

func set_line_color(color: Color) -> void:
	for line: Line2D in [top, bottom, left, right]:
		line.default_color = color

## Draws the box around every cell between [param cellA] and [param cellB].
func draw_box(cellA: Vector2i, cellB: Vector2i) -> void:
	var size := GridManager.CELL_SIZE
	var p0 := Vector2(mini(cellA.x, cellB.x), mini(cellA.y, cellB.y)) * size # top-left
	var p3 := Vector2(maxi(cellA.x, cellB.x) + 1, maxi(cellA.y, cellB.y) + 1) * size # bottom-right
	var p1 := Vector2(p3.x, p0.y) # top-right
	var p2 := Vector2(p0.x, p3.y) # bottom-left

	for pair: Array in [[top, p0, p1], [bottom, p2, p3], [left, p0, p2], [right, p1, p3]]:
		var line: Line2D = pair[0]
		line.clear_points()
		line.add_point(pair[1])
		line.add_point(pair[2])
