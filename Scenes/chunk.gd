@tool
extends StaticBody3D

@export var collision_shape: CollisionShape3D
@export var mesh_instance: MeshInstance3D

@export var noise: FastNoiseLite

const dimensions := Vector3i(16, 64, 16)

const _vertices: Array[Vector3i] = [
	Vector3i(0,0,0),
	Vector3i(1,0,0),
	Vector3i(0,1,0),
	Vector3i(1,1,0),
	Vector3i(0,0,1),
	Vector3i(1,0,1),
	Vector3i(0,1,1),
	Vector3i(1,1,1),
]

const _top: Array[int] = [2,3,7,6]
const _bottom: Array[int] = [0,4,5,1]
const _left: Array[int] = [6,4,0,2]
const _right: Array[int] = [3,1,5,7]
const _back: Array[int] = [7,5,4,6]
const _forward: Array[int] = [2,0,1,3]

var surface_tool := SurfaceTool.new()

var _blocks := []

var chunk_position: Vector2i

func _ready() -> void:
	chunk_position = Vector2i(floori(global_position.x / dimensions.x), floori(global_position.z / dimensions.z))
	generate()
	update()

func generate() -> void:
	for x in dimensions.x:
		var xy_plane := []
		for y in dimensions.y:
			var y_row := []
			for z in dimensions.z:
				var block: Block
				
				var global_block_position := chunk_position * Vector2i(dimensions.x, dimensions.z) + Vector2i(x, z);
				var ground_height := dimensions.y * ((noise.get_noise_2d(global_block_position.x, global_block_position.y) + 1.0) / 2) as int
				if y < ground_height / 2:
					block = BlockManager.stone
				elif y < ground_height:
					block = BlockManager.dirt
				elif y == ground_height:
					block = BlockManager.grass
				else:
					block = BlockManager.air
				
				y_row.append(block)
			xy_plane.append(y_row)
		_blocks.append(xy_plane)
	
func update() -> void:
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in dimensions.x:
		for y in dimensions.y:
			for z in dimensions.z:
				create_block_mesh(Vector3i(x, y, z))
	
	surface_tool.set_material(BlockManager.chunk_material)
	var mesh := surface_tool.commit()
	mesh_instance.mesh = mesh
	collision_shape.shape = mesh.create_trimesh_shape()

func create_block_mesh(block_position: Vector3i) -> void:
	var block: Block = _blocks[block_position.x][block_position.y][block_position.z]
	
	if block == BlockManager.air: return
	
	if is_transparent(block_position + Vector3i.UP):
		create_face_mesh(_top, block_position, block.top_texture if block.top_texture != null else block.texture)
	if is_transparent(block_position + Vector3i.DOWN):
		create_face_mesh(_bottom, block_position, block.bottom_texture if block.bottom_texture != null else block.texture)
	if is_transparent(block_position + Vector3i.LEFT):
		create_face_mesh(_left, block_position, block.texture)
	if is_transparent(block_position + Vector3i.RIGHT):
		create_face_mesh(_right, block_position, block.texture)
	if is_transparent(block_position + Vector3i.FORWARD):
		create_face_mesh(_forward, block_position, block.texture)
	if is_transparent(block_position + Vector3i.BACK):
		create_face_mesh(_back, block_position, block.texture)

func create_face_mesh(face: Array[int], block_position: Vector3i, texture: Texture2D) -> void:
	var texture_position := BlockManager.get_texture_atlas_position(texture)
	var texture_atlas_size := BlockManager.texture_atlas_size
	
	var uv_offset: Vector2 = Vector2(texture_position.x / texture_atlas_size.x, texture_position.y / texture_atlas_size.y)
	var uv_width := 1.0 / texture_atlas_size.x
	var uv_height := 1.0 / texture_atlas_size.y
	
	var uv_a := uv_offset + Vector2(0,0)
	var uv_b := uv_offset + Vector2(0, uv_height)
	var uv_c := uv_offset + Vector2(uv_width, uv_height)
	var uv_d := uv_offset + Vector2(uv_width, 0)
	
	var a := _vertices[face[0]] + block_position
	var b := _vertices[face[1]] + block_position
	var c := _vertices[face[2]] + block_position
	var d := _vertices[face[3]] + block_position
	
	var uv_triangle1 := [uv_a, uv_b, uv_c]
	var uv_triangle2 := [uv_a, uv_c, uv_d]
	
	var triangle1 := [a, b, c]
	var triangle2 := [a, c, d]
	
	surface_tool.add_triangle_fan(triangle1, uv_triangle1)
	surface_tool.add_triangle_fan(triangle2, uv_triangle2)

func is_transparent(block_position: Vector3i) -> bool:
	if block_position.x < 0 || block_position.x >= dimensions.x: return true
	if block_position.y < 0 || block_position.y >= dimensions.y: return true
	if block_position.z < 0 || block_position.z >= dimensions.z: return true
	
	return _blocks[block_position.x][block_position.y][block_position.z] == BlockManager.air
