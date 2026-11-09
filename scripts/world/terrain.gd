extends StaticBody3D
const SIZE: int = 256
const STEP: int = 4
@export var seed_value: int = 7421

func height_at(x: float, z: float) -> float:
	var flatten := smoothstep(18.0, 65.0, Vector2(x, z).length())
	return (sin(x * 0.045 + seed_value * 0.001) * cos(z * 0.039) * 5.0 + sin(z * 0.085) * 1.8) * flatten

func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-128, 128, STEP):
		for x in range(-128, 128, STEP):
			for offset: Vector2 in [Vector2(0, 0), Vector2(STEP, 0), Vector2(0, STEP), Vector2(STEP, 0), Vector2(STEP, STEP), Vector2(0, STEP)]:
				var px: float = x + offset.x
				var pz: float = z + offset.y
				surface.set_uv(Vector2(px, pz) / 16.0)
				var path := absf(px - sin(pz * 0.04) * 4.0) < 2.4 or (absf(pz + 7) < 2 and absf(px) < 25)
				surface.set_color(Color("968460") if path else Color("507349").lerp(Color("75904e"), (sin(px * 0.3) + 1) * 0.3))
				surface.add_vertex(Vector3(px, height_at(px, pz), pz))
	surface.generate_normals()
	var terrain_mesh := surface.commit()
	var visual := MeshInstance3D.new()
	visual.mesh = terrain_mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.95
	visual.material_override = mat
	add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = terrain_mesh.create_trimesh_shape()
	add_child(collision)
