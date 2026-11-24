class_name Item
extends Node2D
## A single item instance. Lives inside an inventory (not in the scene tree)
## or rides on a belt (as a child of the belt).

@export var itemResource: ItemResource

var sprite: Sprite2D = Sprite2D.new()
var texture: Texture

## Progress along the current belt, 0 = start, 1 = end.
var currentLerp: float = 0
## Unused for now.
var canOutput := false

## Sets up the sprite from the shared items sheet (10 x 13 frames).
func _ready() -> void:
	texture = preload("uid://bgvgptnotkii0")
	
	sprite.texture = texture
	sprite.hframes = texture.get_width() / 10
	sprite.vframes = texture.get_height() / 13
	sprite.offset = Vector2(0, 0)
	sprite.frame = itemResource.frame
	
	add_child(sprite)
