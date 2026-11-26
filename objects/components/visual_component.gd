class_name VisualComponent
extends Node2D
## Draws a building: sprite, facing direction, animation, position and outline.

const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")

var buildingResource: BuildingResource

var sprite: Sprite2D = Sprite2D.new()
var animFrame: float = 0
## Top-left cell of the building's footprint.
var cell: Vector2i
var stopAnim: bool = false
## True for the build preview ghost; it isn't animated or faded.
var isPreview: bool = false
## Facing direction.
var dir: Vector2 = Vector2.RIGHT
## Sprite sheet row for the current direction.
var currentVFrame: int = 0
## Outline material, created the first time an outline is shown.
var outlineMaterial: ShaderMaterial

## Fades buildings near the mouse (except the hovered one) while a tool is active.
func preview_loop() -> void:
	modulate = Color(1, 1, 1, 1)
	var mousePos: Vector2 = GridManager.cam.get_global_mouse_position()
	if get_center().distance_to(mousePos) > GridManager.mouseRange: return

	if GridManager.highlight and !isPreview:
		var hovered := GridManager.get_building_at(GridManager.get_coords_at(mousePos))
		if hovered != get_parent(): modulate = Color(1, 1, 1, 0.5)

## Applies the texture and facing direction from the resource.
func set_sprite() -> void:
	sprite.texture = buildingResource.texture
	sprite.hframes = buildingResource.hframes
	apply_direction()
	sprite.frame = currentVFrame * buildingResource.hframes
	update_outline_frame()

	if not sprite.get_parent():
		add_child(sprite)

## Footprint size in cells.
func get_size() -> Vector2i:
	return buildingResource.size if buildingResource else Vector2i.ONE

## Where the building node sits relative to its top-left cell. The node is
## anchored to the bottom row so Y-sort draws big buildings in the right order.
func get_anchor_offset() -> Vector2:
	return Vector2(0.0, (get_size().y - 1) * GridManager.CELL_SIZE)

## World position of the middle of the footprint.
func get_center() -> Vector2:
	return Vector2(cell) * GridManager.CELL_SIZE + Vector2(get_size()) * GridManager.CELL_SIZE * 0.5

## Moves the building to its cell.
func set_pos() -> void:
	get_parent().global_position = Vector2(cell) * GridManager.CELL_SIZE + get_anchor_offset()

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
	update_outline_frame()

## Picks the sprite row / flip for the facing direction.
## Four-direction sheets: row 0 = side, 1 = down, 2 = up.
func apply_direction() -> void:
	sprite.vframes = 1
	currentVFrame = 0
	sprite.flip_h = false

	# Centre the sprite on the whole footprint, measured from the anchor
	# (bottom-left cell), so it's sitting where the grid says it is.
	var size := Vector2(get_size()) * GridManager.CELL_SIZE
	var footprintCenter := Vector2(size.x * 0.5, GridManager.CELL_SIZE - size.y * 0.5)
	sprite.centered = true
	sprite.offset = footprintCenter + buildingResource.offset
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
	update_outline_frame()

# --- Outline ---------------------------------------------------------------

## Shows a [param color] outline around the sprite, or removes it.
func set_outline(enabled: bool, color: Color = Color.WHITE) -> void:
	if not enabled:
		sprite.material = null
		return
	if outlineMaterial == null:
		outlineMaterial = ShaderMaterial.new()
		outlineMaterial.shader = OUTLINE_SHADER
	outlineMaterial.set_shader_parameter("outlineColor", color)
	sprite.material = outlineMaterial
	update_outline_frame()

## Tells the shader which frame of the sheet is showing, so the outline
## follows the current animation frame and flip.
func update_outline_frame() -> void:
	if outlineMaterial == null or sprite.material != outlineMaterial:
		return
	var h := maxi(sprite.hframes, 1)
	var v := maxi(sprite.vframes, 1)
	var frameSize := Vector2(1.0 / h, 1.0 / v)
	var framePos := Vector2(sprite.frame % h, sprite.frame / h) * frameSize
	outlineMaterial.set_shader_parameter("frameRect", Vector4(framePos.x, framePos.y, frameSize.x, frameSize.y))
	outlineMaterial.set_shader_parameter("flipH", sprite.flip_h)
