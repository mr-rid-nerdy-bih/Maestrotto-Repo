class_name VisualComponent
extends Node2D

var buildingResource: BuildingResource

var sprite: Sprite2D = Sprite2D.new()
var animFrame: float = 0
var cell: Vector2i
var stopAnim: bool = false
var isPreview: bool = false
var dir: Vector2 = Vector2.RIGHT
var currentVFrame: int = 0

func preview_loop() -> void:
	modulate = Color(1, 1, 1, 1)
	var mousePos: Vector2 = GridManager.cam.get_global_mouse_position()
	if get_parent().global_position.distance_to(mousePos) > GridManager.mouseRange: return
	
	if GridManager.highlight and !isPreview:
		if GridManager.get_coords_at(GridManager.cam.get_global_mouse_position()) != cell: modulate = Color(1, 1, 1, 0.5)

func set_sprite() -> void:
	sprite.texture = buildingResource.texture
	sprite.hframes = buildingResource.hframes
	setRotation()
	sprite.frame = currentVFrame * buildingResource.hframes
	
	if not sprite.get_parent():
		add_child(sprite)

func set_pos() -> void:
	var pos := Vector2(cell) * GridManager.CELL_SIZE
	get_parent().global_position = pos

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

func setRotation() -> void:
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
