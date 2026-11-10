extends StaticBody3D
const SIZE: int = 256
const STEP: int = 4
@export var seed_value: int = 7421
var farm: Node3D
var building_footprints: Array = []
var ground_material: ShaderMaterial

func height_at(x: float, z: float) -> float:
	if preload("res://scripts/world/building_geometry.gd").contains(Vector2(x, z) / 55.0, building_footprints):
		return 0.085
	if is_instance_valid(farm):
		var surface: float = farm.surface_height(x, z)
		if is_finite(surface):
			return surface
	return base_height_at(x, z)

func base_height_at(x: float, z: float) -> float:
	var flatten := smoothstep(55.0, 95.0, Vector2(x, z).length())
	var height := (sin(x * 0.045 + seed_value * 0.001) * cos(z * 0.039) * 5.0 + sin(z * 0.085) * 1.8) * flatten
	# A flat margin keeps coarse terrain triangles below every farm corner.
	# Only the exterior forest transitions back into the surrounding hills.
	var edge := maxf(absf(x) / 58.0, absf(z) / 56.0)
	return lerpf(-0.05, height, smoothstep(1.0, 1.35, edge))

func _ready() -> void:
	var buildings: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_buildings.json"))
	building_footprints = preload("res://scripts/world/building_geometry.gd").prepare(buildings)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-128, 128, STEP):
		for x in range(-128, 128, STEP):
			for offset: Vector2 in [Vector2(0, 0), Vector2(STEP, 0), Vector2(0, STEP), Vector2(STEP, 0), Vector2(STEP, STEP), Vector2(0, STEP)]:
				var px: float = x + offset.x
				var pz: float = z + offset.y
				surface.set_uv(Vector2(px, pz) / 16.0)
				surface.add_vertex(Vector3(px, base_height_at(px, pz), pz))
	surface.generate_normals()
	var terrain_mesh := surface.commit()
	var visual := MeshInstance3D.new()
	visual.mesh = terrain_mesh
	var shader := Shader.new()
	shader.code = """shader_type spatial;
	uniform sampler2D grass_tex: source_color, repeat_enable;
	uniform sampler2D dirt_tex: source_color, repeat_enable;
	uniform sampler2D road_mask: repeat_disable, filter_linear;
	uniform vec4 road_bounds;
	varying vec3 world_pos;
	void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
	void fragment(){
		vec2 p=world_pos.xz;
		vec2 road_uv=(p-road_bounds.xy)/road_bounds.zw;
		float path=texture(road_mask,road_uv).r;
		ALBEDO=mix(texture(grass_tex,p/8.0).rgb,texture(dirt_tex,p/2.0).rgb,path);
		ROUGHNESS=0.95;
	}"""
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = shader
	terrain_material.set_shader_parameter("grass_tex",load("res://assets/grass/emerald_meadow_albedo.png"))
	terrain_material.set_shader_parameter("dirt_tex",load("res://assets/textures/dirt.png"))
	var paths: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_paths.json"))
	var bounds: Array = paths.mask_bounds
	terrain_material.set_shader_parameter("road_mask", load("res://assets/textures/farm_paths_mask.png"))
	terrain_material.set_shader_parameter("road_bounds", Vector4(bounds[0], bounds[1], bounds[2] - bounds[0], bounds[3] - bounds[1]))
	visual.material_override = terrain_material
	ground_material = terrain_material
	add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = terrain_mesh.create_trimesh_shape()
	add_child(collision)
