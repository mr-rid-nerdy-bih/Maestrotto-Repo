class_name VisualComponent
extends Node2D

var buildingResource: BuildingResource

var sprite: Sprite2D = Sprite2D.new()
var frame: float = 0
var cell: Vector2i
var stopAnim: bool = false
var isPreview: bool = false
var dir: bool = false

func preview_loop() -> void:
	modulate = Color(1, 1, 1, 1)
	var mousePos: Vector2 = GridManager.cam.get_global_mouse_position()
	if get_parent().global_position.distance_to(mousePos) > GridManager.mouseRange: return
	
	if GridManager.highlight and !isPreview:
		if GridManager.get_coords_at(GridManager.cam.get_global_mouse_position()) != cell: modulate = Color(1, 1, 1, 0.5)

func set_sprite() -> void:
	sprite.texture = buildingResource.texture
	sprite.offset = Vector2(buildingResource.offset.x * (-1.0 if dir else 1.0), buildingResource.offset.y) + Vector2(8.0, 8.0)
	sprite.hframes = buildingResource.hframes
	sprite.flip_h = dir
	
	if not sprite.get_parent():
		add_child(sprite)

func set_pos() -> void:
	var pos := Vector2(cell) * GridManager.CELL_SIZE
	get_parent().global_position = pos

func animate() -> void:
	if isPreview:
		return
	
	if buildingResource.isAnimated and not stopAnim:
		frame = fmod(frame + 1.0 / buildingResource.frameTime, float(buildingResource.hframes))
	
	sprite.frame = int(frame)
