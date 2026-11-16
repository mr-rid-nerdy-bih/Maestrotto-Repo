class_name Item
extends Node2D

@export var itemName: String
@export_multiline var description: String
@export var frame: int

var sprite: Sprite2D = Sprite2D.new()
var texture: Texture

func _ready() -> void:
	texture = preload("uid://bgvgptnotkii0")
	
	sprite.texture = texture
	sprite.hframes = texture.get_width() / 10
	sprite.vframes = texture.get_height() / 13
	sprite.frame = frame
	
	add_child(sprite)
