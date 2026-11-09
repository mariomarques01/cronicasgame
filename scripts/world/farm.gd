extends RefCounted
var w: Node3D
func _init(world: Node3D) -> void:
	w = world
func box(size: Vector3, pos: Vector3, color: Color, texture: String = "wood", solid: bool = true) -> Node3D:
	var node: Node3D = w.box(size, pos, color, solid)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_texture = load("res://assets/textures/" + texture + ".png")
	mat.uv1_scale = Vector3(maxf(size.x / 2, 1), maxf(size.y / 2, 1), 1)
	mat.roughness = 0.95
	node.get_child(0).material_override = mat
	return node
func at(x: float, z: float, y: float = 0) -> Vector3:
	return w.ground(x, z, y)
func title(text: String, x: float, z: float, y: float = 4) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at(x, z, y)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 38
	label.pixel_size = 0.012
	label.modulate = Color("f5dfae")
	w.add_child(label)
func building(x: float, z: float, sx: float, sz: float, height: float, color: Color, name: String) -> void:
	box(Vector3(sx, 0.6, sz), at(x,z,0.3), Color("b3a58b"), "stone")
	box(Vector3(sx, height, sz), at(x,z,height/2+0.5), color)
	# Two pitched roof planes with explicit eaves, chimney and timber framing.
	for side: int in [-1,1]:
		var roof := box(Vector3(sx/2+1.0,0.3,sz+1.4),at(x+side*sx/4,z,height+1.3),Color("d59a78") if name == "Celeiro" else Color("aeb4ab"),"roof",false)
		roof.rotation.z = side * -0.48
		box(Vector3(0.25,height,0.25),at(x+side*(sx/2-0.1),z+sz/2+0.05,height/2+0.5),Color("604a31"))
		box(Vector3(1.5,1.6,0.12),at(x+side*sx*.29,z+sz/2+0.1,2.9),Color("efca7a"),"linen",false)
		for dx: float in [-0.8,0.0,0.8]:
			box(Vector3(0.08,1.8,0.15),at(x+side*sx*.29+dx,z+sz/2+.18,2.9),Color("4b3825"),"wood",false)
	box(Vector3(1.7,2.6,0.16),at(x,z+sz/2+.15,1.8),Color("6f4d2b"))
	box(Vector3(sx+0.2,0.2,0.2),at(x,z+sz/2+.2,1),Color("443721"))
	box(Vector3(1,2.6,1),at(x+sx*.25,z,height+1.5),Color("a9a08b"),"stone")
	title(name,x,z,height+3)
func fence(x1: float,z1: float,x2: float,z2: float) -> void:
	var start := Vector2(x1,z1)
	var end := Vector2(x2,z2)
	var n := maxi(1,int(start.distance_to(end)/3))
	for i in range(n+1):
		var p := start.lerp(end,float(i)/n)
		box(Vector3(.2,1.6,.2),at(p.x,p.y,.8),Color("b29c72"))
	for h: float in [.6,1.2]:
		var rail := box(Vector3(start.distance_to(end),.13,.13),at((x1+x2)/2,(z1+z2)/2,h),Color("a58e62"),"wood",false)
		rail.rotation.y = -atan2(z2-z1,x2-x1)
func pen(x1: float,z1: float,x2: float,z2: float,name: String) -> void:
	fence(x1,z1,x2,z1)
	fence(x2,z1,x2,z2)
	fence(x2,z2,x1,z2)
	fence(x1,z2,x1,z1)
	title(name,(x1+x2)/2,(z1+z2)/2)
func animal(x: float,z: float,sheep: bool) -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.radius = .7
	mesh.height = 1
	var body: Node3D = w.prop(mesh,at(x,z,1),Color("dfd9bd") if sheep else Color("d6c7a8"))
	body.scale = Vector3(1,1,1.8)
	w.prop(mesh,at(x,z-.9,1),Color("b2a385") if sheep else Color("483e30")) .scale = Vector3(.5,.6,.6)
	for dx: float in [-.4,.4]:
		for dz: float in [-.5,.5]:
			box(Vector3(.14,.8,.14),at(x+dx,z+dz,.4),Color("59482e"),"wood",false)
func build() -> void:
	building(0,0,14,11,5,Color("c7b58b"),"Casa principal")
	# Porch and steps face the southern entrance.
	box(Vector3(12,.5,3),at(0,7,.3),Color("927756"))
	for x: float in [-5.0,5.0]:
		box(Vector3(.25,3,.25),at(x,8,1.6),Color("6f5736"))
	box(Vector3(12,.25,3.5),at(0,7,3.3),Color("b19c79"),"roof",false)
	building(1,-31,14,13,6,Color("ad4a32"),"Celeiro")
	building(-23,-20,8,7,3,Color("a19169"),"Oficina")
	building(-28,16,8,8,3,Color("a18a60"),"Depósito")
	pen(14,-42,34,-23,"Curral")
	pen(25,19,44,39,"Pasto das ovelhas")
	for i in range(4):
		animal(18+i*3,-30-(i%2)*5,false)
		animal(29+i*3,25+(i%2)*6,true)
	# Silo, well and rotating windmill.
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 2.2
	cylinder.bottom_radius = 2.2
	cylinder.height = 9
	w.prop(cylinder,at(38,-29,4.5),Color("9faaa0"),true)
	var dome := SphereMesh.new()
	dome.radius = 2.3
	dome.height = 2.8
	w.prop(dome,at(38,-29,9),Color("c1c9bf"))
	cylinder = CylinderMesh.new()
	cylinder.top_radius = 1.4
	cylinder.bottom_radius = 1.5
	cylinder.height = 1.2
	w.prop(cylinder,at(-24,-3,.6),Color("96917b"),true)
	for dx: float in [-1.2,1.2]:
		box(Vector3(.2,3,.2),at(-24+dx,-3,1.5),Color("826747"))
	box(Vector3(3.5,.25,2.5),at(-24,-3,3),Color("92816a"),"roof",false)
	title("Poço",-24,-3)
	cylinder = CylinderMesh.new()
	cylinder.top_radius = 2
	cylinder.bottom_radius = 3.4
	cylinder.height = 9
	w.prop(cylinder,at(38,-10,4.5),Color("b6a27b"),true)
	var hub := Node3D.new()
	hub.position = at(38,-7,7)
	w.add_child(hub)
	for i in range(4):
		var blade := box(Vector3(.9,5,.18),at(0,0),Color("c5ae7b"),"wood",false)
		blade.reparent(hub)
		blade.position = Vector3(sin(i*PI/2)*3,cos(i*PI/2)*3,0)
		blade.rotation.z = -i*PI/2
	w.windmill = hub
	title("Moinho",38,-10,11)
	# Three lower fields and the narrow eastern vegetable garden.
	for field in range(3):
		var x := -15.0+field*10
		box(Vector3(8,.1,20),at(x,27,.07),Color.WHITE,"dirt",false)
		for row in range(5):
			for col in range(12):
				crop(x-3+row*1.4,18+col*1.55,field==2)
	pen(-20,16,10,38,"Plantações")
	box(Vector3(5,.1,19),at(23,4,.08),Color.WHITE,"dirt",false)
	for row in range(3):
		for col in range(12):
			crop(21+row*1.5,-4+col*1.4,false)
	pen(19,-7,27,15,"Horta")
	# Outer boundary with a southern entry and a northern quest passage.
	fence(-43,-45,-5,-45)
	fence(5,-45,43,-45)
	fence(-43,-45,-43,43)
	fence(43,-45,43,43)
	fence(-43,43,-4,43)
	fence(4,43,43,43)
	for x: float in [-4,4]:
		box(Vector3(.6,4,.6),at(x,43,2),Color("7a5735"))
	box(Vector3(9,.6,.7),at(0,43,4),Color("98734b"))
	title("FAZENDA DO VALE",0,43,5)
func crop(x: float,z: float,wheat: bool) -> void:
	# Collect instances; the world batches plants rather than one node per leaf.
	w.crop_positions.append({"pos":at(x,z,.7),"wheat":wheat})
