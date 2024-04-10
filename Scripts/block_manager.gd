@tool
extends Node

var air: Block = load("res://Blocks/air.tres")
var stone: Block = load("res://Blocks/stone.tres")
var dirt: Block = load("res://Blocks/dirt.tres")
var grass: Block = load("res://Blocks/grass.tres")

var _atlas_lookup: Dictionary = {}

const _grid_width := 4
var _grid_height: int

const block_texture_size := Vector2i(16, 16)

var texture_atlas_size: Vector2

var chunk_material: StandardMaterial3D

func _ready() -> void:
	var block_textures: Array = [air, stone, dirt, grass] \
		.map(func(block: Block) -> Array[Texture2D]: return block.get_textures())
	var unique_block_textures: Array[Texture2D] = []
	for textures: Array[Texture2D] in block_textures:
		for texture in textures:
			if texture != null and !unique_block_textures.has(texture):
				unique_block_textures.append(texture)
	
	for i in unique_block_textures.size():
		var texture := unique_block_textures[i]
		var x: int = i % _grid_width
		var y: int = floori(i / _grid_width)
		_atlas_lookup[texture] = Vector2i(x, y)
	
	_grid_height = ceili(unique_block_textures.size() / _grid_width as float)
	
	var image := Image.create(_grid_width * block_texture_size.x, _grid_height * block_texture_size.y, false, Image.FORMAT_RGB8)
	for x in _grid_width:
		for y in _grid_height:
			var img_index := x + y * _grid_width
			
			if img_index >= unique_block_textures.size(): continue
			
			var current_image := unique_block_textures[img_index].get_image()
			current_image.convert(Image.FORMAT_RGB8)
			image.blit_rect(current_image, Rect2i(Vector2i.ZERO, block_texture_size), Vector2i(x,y) * block_texture_size)
	
	var texture_atlas := ImageTexture.create_from_image(image)
	
	chunk_material = StandardMaterial3D.new()
	chunk_material.albedo_texture = texture_atlas
	chunk_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	texture_atlas_size = Vector2i(_grid_width, _grid_height)
	
	print("Done loading %s images to make %s x %s atlas" % [unique_block_textures.size(), _grid_width, _grid_height])

func get_texture_atlas_position(texture: Texture2D) -> Vector2i:
	if texture == null:
		return Vector2.ZERO
	return _atlas_lookup[texture]
