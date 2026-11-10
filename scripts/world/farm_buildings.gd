extends Node3D
const MODELS := {
	"workshop": preload("res://assets/models/workshop_mobile.res"),
	"barn": preload("res://assets/models/barn_mobile.res"),
	"windmill": preload("res://assets/models/windmill_static.res")
}
const WINDMILL_FRAME: ArrayMesh = preload("res://assets/models/windmill_mobile.res")
const ROTOR_MESH: ArrayMesh = preload("res://assets/models/windmill_rotor.res")
const ROTOR_PIVOT := Vector3(0.0028, 0.6258, 0.285)
const ROTOR_TURN_SECONDS := 120.0
var world: Node3D
var rotor: Node3D

func _ready() -> void:
	name = "FarmBuildings"
	var layout: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_buildings.json"))
	for spec: Dictionary in layout:
		place_building(spec)

func place_building(spec: Dictionary) -> void:
	var root := Node3D.new()
	root.name = spec.id
	root.position = Vector3(spec.position[0], spec.position[1], spec.position[2])
	add_child(root)
	var mesh: Mesh = MODELS[spec.asset]
	var bounds := WINDMILL_FRAME.get_aabb() if spec.asset == "windmill" else mesh.get_aabb()
	var factor := float(spec.size) / (bounds.size.y if spec.size_axis == "height" else bounds.size.x)
	var pivot := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	var basis := Basis(Vector3.UP, deg_to_rad(float(spec.yaw_degrees))).scaled(Vector3.ONE * factor)
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	visual.mesh = without_floor(mesh, factor)
	visual.transform = Transform3D(basis, -(basis * pivot))
	root.add_child(visual)
	if spec.asset == "windmill":
		rotor = Node3D.new()
		rotor.name = "SlowRotor"
		rotor.transform = Transform3D(basis, visual.transform * ROTOR_PIVOT)
		root.add_child(rotor)
		var vanes := MeshInstance3D.new()
		vanes.name = "Vanes"
		vanes.mesh = ROTOR_MESH
		vanes.position = -ROTOR_PIVOT
		rotor.add_child(vanes)
	var body := StaticBody3D.new()
	body.name = str(spec.id) + "Collision"
	var shape := CollisionShape3D.new()
	var geometry := ConcavePolygonShape3D.new()
	geometry.backface_collision = true
	var faces := mesh.get_faces()
	for i in faces.size():
		faces[i] = visual.transform * faces[i]
	var solid_faces := PackedVector3Array()
	for i in range(0, faces.size(), 3):
		if maxf(faces[i].y, maxf(faces[i + 1].y, faces[i + 2].y)) < 0.18:
			continue
		solid_faces.append_array(PackedVector3Array([faces[i], faces[i + 1], faces[i + 2]]))
	geometry.set_faces(solid_faces)
	shape.shape = geometry
	body.add_child(shape)
	root.add_child(body)
	build_ground(root, spec.footprint)

func _process(delta: float) -> void:
	if not is_instance_valid(world) or not world.playing or not is_instance_valid(world.player) or not world.player.enabled:
		return
	advance_rotor(delta)

func advance_rotor(delta: float) -> void:
	if is_instance_valid(rotor):
		rotor.rotation.z = wrapf(rotor.rotation.z - TAU * delta / ROTOR_TURN_SECONDS, -PI, PI)

func build_ground(root: Node3D, footprint: Dictionary) -> void:
	var polygon := PackedVector2Array()
	if footprint.has("polygon"):
		var prepared := preload("res://scripts/world/building_geometry.gd").prepare([{"footprint": footprint}])
		for point: Vector2 in prepared[0].polygon:
			polygon.append(point * 55.0)
	else:
		var center := Vector2(footprint.ellipse.center[0], footprint.ellipse.center[1]) * 55.0
		var radii := Vector2(footprint.ellipse.radii[0], footprint.ellipse.radii[1]) * 55.0
		for i in 48:
			var angle := float(i) * TAU / 48.0
			polygon.append(center + Vector2(cos(angle), sin(angle)) * radii)
	var indices := Geometry2D.triangulate_polygon(polygon)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, indices.size(), 3):
		var points: Array[Vector3] = []
		for j in 3:
			var p := polygon[indices[i + j]]
			points.append(Vector3(p.x - root.position.x, 0.06, p.y - root.position.z))
		if (points[1] - points[0]).cross(points[2] - points[0]).y > 0:
			var swap := points[1]
			points[1] = points[2]
			points[2] = swap
		for point: Vector3 in points:
			tool.set_uv(Vector2(point.x, point.z) / 4.0)
			tool.add_vertex(point)
	tool.generate_normals()
	var mesh := tool.commit()
	var ground := StaticBody3D.new()
	ground.name = str(root.name) + "Ground"
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.material_override = world.terrain.ground_material
	ground.add_child(visual)
	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	ground.add_child(collider)
	root.add_child(ground)

func without_floor(source: Mesh, factor: float) -> ArrayMesh:
	var result := ArrayMesh.new()
	var bottom := source.get_aabb().position.y
	for surface in source.get_surface_count():
		var arrays: Array = source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var kept := PackedInt32Array()
		for i in range(0, indices.size(), 3):
			var a := vertices[indices[i]]
			var b := vertices[indices[i + 1]]
			var c := vertices[indices[i + 2]]
			var normal := (b - a).cross(c - a).normalized()
			if (maxf(a.y, maxf(b.y, c.y)) - bottom) * factor < 0.12 and absf(normal.y) > 0.65:
				continue
			kept.append_array(PackedInt32Array([indices[i], indices[i + 1], indices[i + 2]]))
		arrays[Mesh.ARRAY_INDEX] = kept
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		result.surface_set_material(surface, source.surface_get_material(surface))
	return result
