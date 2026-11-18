class_name Item
extends Node2D

@export var itemResource: ItemResource

var sprite: Sprite2D = Sprite2D.new()
var texture: Texture

var currentLerp = 0
var canOutput = false

func _ready() -> void:
	texture = preload("uid://bgvgptnotkii0")
	
	sprite.texture = texture
	sprite.hframes = texture.get_width() / 10
	sprite.vframes = texture.get_height() / 13
	sprite.offset = Vector2(0, 0)
	sprite.frame = itemResource.frame
	
	add_child(sprite)
