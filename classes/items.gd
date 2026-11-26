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
## This item's notation, e.g. "pitch" -> PitchNotation. Filled in by the
## recipe that crafted it (see GenerateItemComponent.apply_notation).
var data: Dictionary

## The notation stored under [param key], or null if this item doesn't have it.
func get_notation(key: String) -> Resource:
	return data.get(key)

## Sets up the sprite from the shared items sheet (10 x 13 frames).
func _ready() -> void:
	texture = preload("uid://bgvgptnotkii0")
	
	sprite.texture = texture
	sprite.hframes = texture.get_width() / 10
	sprite.vframes = texture.get_height() / 13
	sprite.offset = Vector2(0, 0)
	sprite.frame = itemResource.frame
	
	add_child(sprite)
