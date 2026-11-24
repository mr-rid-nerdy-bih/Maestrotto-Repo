class_name VisualComponent
extends Node2D
## Draws a building: sprite, facing direction, animation and position.

var buildingResource: BuildingResource

var sprite: Sprite2D = Sprite2D.new()
var animFrame: float = 0
var cell: Vector2i
var stopAnim: bool = false
## True for the build preview ghost; it isn't animated or faded.
var isPreview: bool = false
## Facing direction.
var dir: Vector2 = Vector2.RIGHT
## Sprite sheet row for the current direction.
var currentVFrame: int = 0

## Fades buildings near the mouse (except the hovered one) while a tool is active.
func preview_loop() -> void:
	modulate = Color(1, 1, 1, 1)
	var mousePos: Vector2 = GridManager.cam.get_global_mouse_position()
	if get_parent().global_position.distance_to(mousePos) > GridManager.mouseRange: return
	
	if GridManager.highlight and !isPreview:
		if GridManager.get_coords_at(GridManager.cam.get_global_mouse_position()) != cell: modulate = Color(1, 1, 1, 0.5)

## Applies the texture and facing direction from the resource.
func set_sprite() -> void:
	sprite.texture = buildingResource.texture
	sprite.hframes = buildingResource.hframes
	apply_direction()
	sprite.frame = currentVFrame * buildingResource.hframes
	
	if not sprite.get_parent():
		add_child(sprite)

## Moves the building to its cell.
func set_pos() -> void:
	var pos := Vector2(cell) * GridManager.CELL_SIZE
	get_parent().global_position = pos

## Advances the animation by one tick.
func animate() -> void:
	if isPreview:
		return
	
	var rowStart := currentVFrame * buildingResource.hframes
	if buildingResource.isAnimated and not stopAnim:
		var ft := buildingResource.frameTime if buildingResource.frameTime != 0.0 else 1.0
		animFrame = fmod(animFrame + 1.0 / ft, float(buildingResource.hframes))
	else:
		animFrame = 0.0
	
	sprite.frame = rowStart + int(animFrame)

## Picks the sprite row / flip for the facing direction.
## Four-direction sheets: row 0 = side, 1 = down, 2 = up.
func apply_direction() -> void:
	sprite.vframes = 1
	currentVFrame = 0
	sprite.flip_h = false
	
	var cellCenter := Vector2.ONE
	cellCenter *= (GridManager.CELL_SIZE * 0.5)
	sprite.centered = true
	sprite.offset = cellCenter + buildingResource.offset
	if buildingResource.fourDirections:
		sprite.vframes = 3
		sprite.flip_h = dir == Vector2.RIGHT
		match dir:
			Vector2.DOWN:
				currentVFrame = 1
			Vector2.UP:
				currentVFrame = 2
	else:
		sprite.flip_h = dir == Vector2.UP or dir == Vector2.DOWN
