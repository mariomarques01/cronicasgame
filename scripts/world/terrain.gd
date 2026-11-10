extends StaticBody3D
const SIZE: int = 256
const STEP: int = 4
@export var seed_value: int = 7421
var farm: Node3D
var building_footprints: Array = []

func height_at(x: float, z: float) -> float:
	if preload("res://scripts/world/building_geometry.gd").contains(Vector2(x, z) / 55.0, building_footprints):
		return 0.085
	if is_instance_valid(farm) and absf(x) < 53 and absf(z) < 49:
		var surface: float = farm.surface_height(x, z)
		if is_finite(surface):
			return surface
	return base_height_at(x, z)

func base_height_at(x: float, z: float) -> float:
	var flatten := smoothstep(55.0, 95.0, Vector2(x, z).length())
	var height := (sin(x * 0.045 + seed_value * 0.001) * cos(z * 0.039) * 5.0 + sin(z * 0.085) * 1.8) * flatten
	# Keep the supporting terrain below the imported farm, including its entrance.
	return height - (1.0 - smoothstep(47.0, 56.0, maxf(absf(x), absf(z))))

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
				var path := absf(Vector2(px / 1.06, pz).length() - 40.0) < 2.8 or (absf(px) < 2.5 and absf(pz) > 9) or (absf(pz - 11) < 2.5 and absf(px) < 36) or (absf(pz + 19) < 2.5 and absf(px) < 37)
				surface.set_color(Color(1,0,0) if path else Color(0,0,0))
				surface.add_vertex(Vector3(px, base_height_at(px, pz), pz))
	surface.generate_normals()
	var terrain_mesh := surface.commit()
	var visual := MeshInstance3D.new()
	visual.mesh = terrain_mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.95
	var shader := Shader.new()
	shader.code = """shader_type spatial;
	uniform sampler2D grass_tex: source_color, repeat_enable;
	uniform sampler2D dirt_tex: source_color, repeat_enable;
	varying vec3 world_pos;
	void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
	void fragment(){
		vec2 p=world_pos.xz;
		float ring=abs(length(vec2(p.x/1.06,p.y))-40.0);
		float center=max(abs(p.x),9.0-abs(p.y));
		float south=max(abs(p.y-11.0),abs(p.x)-36.0);
		float north=max(abs(p.y+19.0),abs(p.x)-37.0);
		float path=1.0-smoothstep(2.0,3.0,min(ring,min(center,min(south,north))));
		ALBEDO=mix(texture(grass_tex,UV*8.0).rgb,texture(dirt_tex,UV*8.0).rgb,path);
		ROUGHNESS=0.95;
	}"""
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = shader
	terrain_material.set_shader_parameter("grass_tex",load("res://assets/textures/grass.png"))
	terrain_material.set_shader_parameter("dirt_tex",load("res://assets/textures/dirt.png"))
	visual.material_override = terrain_material
	add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = terrain_mesh.create_trimesh_shape()
	add_child(collision)
