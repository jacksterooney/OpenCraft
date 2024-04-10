@tool
extends Resource

class_name Block

@export var texture: Texture2D
@export var top_texture: Texture2D
@export var bottom_texture: Texture2D

func get_textures() -> Array[Texture2D]:
	return [texture, top_texture, bottom_texture]

