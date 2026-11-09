extends Node3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var phase: float = 0
func part(pos: Vector3, size: Vector3, color: Color, parent: Node3D = self, texture: String = "") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	node.mesh = mesh
	node.position = pos
	node.scale = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if not texture.is_empty():
		mat.albedo_texture = load("res://assets/textures/" + texture + ".png")
	node.material_override = mat
	parent.add_child(node)
	return node

func _ready() -> void:
	part(Vector3(0, 1.05, 0), Vector3(0.64, 0.62, 0.43), Color("d7bd89"), self, "linen")
	part(Vector3(0, 1.11, 0.07), Vector3(0.69, 0.46, 0.44), Color("63452d"), self, "leather")
	part(Vector3(0, 1.17, -0.18), Vector3(0.38, 0.5, 0.12), Color("e2c894"), self, "linen")
	part(Vector3(0, 1.52, 0), Vector3(0.43, 0.09, 0.38), Color("913b2e"))
	part(Vector3(0.17, 1.36, -0.23), Vector3(0.15, 0.25, 0.05), Color("913b2e"))
	part(Vector3(0, 1.84, -0.03), Vector3(0.63, 0.43, 0.53), Color("cb945a"), self, "fur")
	part(Vector3(0, 1.68, -0.24), Vector3(0.47, 0.20, 0.30), Color("fff0d1"), self, "fur")
	part(Vector3(0, 1.75, -0.395), Vector3(0.10, 0.05, 0.05), Color("b77869"))
	for side: int in [-1, 1]:
		var ear := part(Vector3(side * 0.20, 2.30, 0.01), Vector3(0.18, 0.57, 0.14), Color("bc8855"), self, "fur")
		ear.rotation.z = side * -0.16
		part(Vector3(side * 0.20, 2.30, -0.07), Vector3(0.10, 0.45, 0.04), Color("d39d88"))
		part(Vector3(side * 0.23, 1.91, -0.23), Vector3(0.15, 0.13, 0.09), Color("fff2da"))
		part(Vector3(side * 0.23, 1.91, -0.285), Vector3(0.09, 0.10, 0.035), Color("472b16"))
		part(Vector3(side * 0.23, 1.92, -0.313), Vector3(0.04, 0.07, 0.02), Color("161611"))
		part(Vector3(side * 0.23 - 0.015, 1.95, -0.327), Vector3(0.018, 0.02, 0.01), Color.WHITE)
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.21, 0.78, 0)
		add_child(leg)
		legs.append(leg)
		part(Vector3(0, -0.20, 0), Vector3(0.33, 0.40, 0.34), Color("625032"), leg, "linen")
		part(Vector3(0, -0.49, -0.08), Vector3(0.34, 0.13, 0.50), Color("d3ad75"), leg, "fur")
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.42, 1.37, 0)
		add_child(arm)
		arms.append(arm)
		part(Vector3(0, -0.17, 0), Vector3(0.23, 0.32, 0.23), Color("e1cda4"), arm, "linen")
		part(Vector3(0, -0.37, 0), Vector3(0.22, 0.17, 0.22), Color("58422b"), arm, "leather")
		part(Vector3(0, -0.50, -0.03), Vector3(0.22, 0.12, 0.24), Color("dfc49b"), arm, "fur")
	part(Vector3(0, 1.12, 0.36), Vector3(0.62, 0.44, 0.23), Color("87613a"), self, "leather")
	part(Vector3(0, 1.42, 0.40), Vector3(0.70, 0.13, 0.24), Color("b99559"), self, "linen")
	part(Vector3(0, 0.68, 0.31), Vector3(0.30, 0.17, 0.25), Color("f4e3c3"), self, "fur")
	for y: float in [1.05, 1.24]:
		part(Vector3(0, y, -0.25), Vector3(0.04, 0.02, 0.03), Color("e7bf67"))

func animate(delta: float, moving: bool, running: bool) -> void:
	phase += delta * (12 if running else 8)
	for i in range(legs.size()):
		var swing: float = sin(phase + i * PI) * 0.45 if moving else 0.0
		legs[i].rotation.x = swing
		arms[i].rotation.x = -swing * 0.7
