extends Node3D
const Layout = preload("res://scripts/world/ruins_layout.gd")
const ARCH = preload("res://assets/ruins/arch.res")
const BROKEN = preload("res://assets/ruins/broken_arch.res")
const WALL = preload("res://assets/ruins/wall.res")
const RUBBLE = preload("res://assets/ruins/rubble.res")
var world: Node3D
var tablets: Dictionary = {}
var glyphs: Dictionary = {}
var nearby_hint := ""
var dwell_id := ""
var dwell := 0.0
var tick := 0.0
var unread_material: StandardMaterial3D
var read_material: StandardMaterial3D
const READ_SECONDS := 0.8

func _ready() -> void:
	name = "AncientRuins"
	unread_material = world.material(Color("8da8ad"), true)
	read_material = world.material(Color("dbbf70"), true)
	place_arch("EntranceArch", ARCH, Vector3(-26,Layout.FLOOR_Y,-68),0)
	place_arch("WesternBrokenArch", BROKEN, Vector3(-36,Layout.FLOOR_Y,-77),PI * 0.5)
	place_arch("NorthernArch", BROKEN, Vector3(-26,Layout.FLOOR_Y,-94),0)
	place_wall(Vector3(-39,Layout.FLOOR_Y,-84),PI*0.5)
	place_wall(Vector3(-13,Layout.FLOOR_Y,-81),PI*0.5)
	var rubble_shape := RUBBLE.create_trimesh_shape()
	for at: Vector2 in [Vector2(-37,-73),Vector2(-14,-93),Vector2(-36,-95),Vector2(-14,-73)]:
		place_visual(RUBBLE,Vector3(at.x,Layout.FLOOR_Y,at.y),at.x, "FallenMasonry")
		var body := StaticBody3D.new()
		body.name = "FallenMasonryCollision"
		body.position = Vector3(at.x,Layout.FLOOR_Y,at.y)
		body.rotation.y = at.x
		var shape := CollisionShape3D.new()
		shape.shape = rubble_shape
		body.add_child(shape)
		add_child(body)
	paving()
	for definition: Dictionary in Layout.config.inscriptions:
		var at := Vector3(definition.position[0],Layout.FLOOR_Y,definition.position[1])
		tablets[definition.id] = at
		var body := StaticBody3D.new()
		body.name = str(definition.id).capitalize() + "Inscription"
		body.position = at + Vector3(0,0,-2.0)
		add_child(body)
		var visual := MeshInstance3D.new()
		var slab := BoxMesh.new()
		slab.size = Vector3(1.4,1.5,0.45)
		visual.mesh = slab
		visual.position.y = 0.75
		var mat: StandardMaterial3D = world.material(Color("a8a28d"))
		mat.albedo_texture = preload("res://assets/ruins/limestone.png")
		visual.material_override = mat
		body.add_child(visual)
		add_box(body,Vector3(1.4,1.5,0.45),Vector3(0,.75,0))
		glyphs[definition.id] = glyph(body)
	var sign := Label3D.new()
	sign.text = "Ruínas Antigas"
	sign.position = Vector3(-26,Layout.FLOOR_Y+6.8,-68)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 30
	sign.pixel_size = 0.009
	sign.outline_size = 3
	sign.visibility_range_end = 40
	add_child(sign)
	sync_progress()

func place_visual(mesh: Mesh, at: Vector3, angle: float, title: String) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = title
	visual.mesh = mesh
	visual.position = at
	visual.rotation.y = angle
	add_child(visual)
	return visual

func add_box(body: StaticBody3D, size: Vector3, at: Vector3, angle: float = 0.0) -> void:
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	collision.position = at
	collision.rotation.z = angle
	body.add_child(collision)

func place_arch(title: String, mesh: Mesh, at: Vector3, angle: float) -> void:
	place_visual(mesh,at,angle,title)
	var body := StaticBody3D.new()
	body.name = title + "Collision"
	body.position = at
	body.rotation.y = angle
	add_child(body)
	for side in [-1.0,1.0]:
		var height := 2.0 if mesh == BROKEN and side > 0 else 3.3
		add_box(body,Vector3(1.15,height,1.35),Vector3(side*2.5,height*.5,0))
		add_box(body,Vector3(1.65,.36,1.7),Vector3(side*2.5,.18,0))
	if mesh == BROKEN: add_box(body,Vector3(2.2,.5,2),Vector3(4.5,.25,0))
	for i in 12:
		if mesh == BROKEN and i in [3,4,5,6,7]: continue
		var arc := PI * (i+0.5)/12.0
		add_box(body,Vector3(.68,1.,1.25),Vector3(cos(arc)*2.5,3.25+sin(arc)*2.5,0),arc-PI*.5)

func place_wall(at: Vector3, angle: float) -> void:
	place_visual(WALL,at,angle,"BrokenWall")
	var body := StaticBody3D.new()
	body.name = "RuinsWallCollision"
	body.position = at
	body.rotation.y = angle
	add_child(body)
	for row in 4:
		for col in 9:
			if row == 3 and col in [0,1,4,7,8]: continue
			if row == 2 and col == 0: continue
			add_box(body,Vector3(.92,.54,1.05),Vector3((col-4)*.95+(row%2)*.32,.29+row*.57,0))

func glyph(body: StaticBody3D) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 4:
		var y := .4 + row*.23
		var half := .22 + (row%2)*.12
		for point: Vector3 in [Vector3(-half,y,.24),Vector3(half,y,.24),Vector3(-half,y+.035,.24),Vector3(half,y,.24),Vector3(half,y+.035,.24),Vector3(-half,y+.035,.24)]:
			tool.add_vertex(point)
	tool.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = unread_material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(visual)
	return visual

func paving() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 81921
	var slab := BoxMesh.new()
	slab.size = Vector3(.72,.025,.52)
	var mat: StandardMaterial3D = world.material(Color("a49f87"))
	mat.albedo_texture = preload("res://assets/ruins/limestone.png")
	slab.material = mat
	var transforms: Array[Transform3D] = []
	for path: Dictionary in Layout.config.paths:
		for segment in path.points.size()-1:
			var a := Vector2(path.points[segment][0],path.points[segment][1])
			var b := Vector2(path.points[segment+1][0],path.points[segment+1][1])
			for step in ceili(a.distance_to(b)/1.4):
				var p := a.lerp(b,(float(step)+.5)/maxf(1.,ceilf(a.distance_to(b)/1.4)))
				if p.y > -64 or rng.randf() < .25: continue
				for side in [-.55,.55]:
					var v: Vector2 = p + (b-a).normalized().orthogonal()*side
					var at: Vector3 = world.ground(v.x,v.y,.022)
					transforms.append(Transform3D(Basis(Vector3.UP,rng.randf_range(-.12,.12)),at))
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = slab
	multi.instance_count = transforms.size()
	for i in transforms.size(): multi.set_instance_transform(i,transforms[i])
	var batch := MultiMeshInstance3D.new()
	batch.name = "WornPaving"
	batch.multimesh = multi
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)

func contains(at: Vector3) -> bool:
	return Layout.BOUNDS.has_point(Vector2(at.x,at.z))

func sync_progress() -> void:
	for id: String in glyphs:
		glyphs[id].material_override = read_material if id in Game.runes else unread_material
	dwell_id = ""
	dwell = 0.0
	nearby_hint = ""

func goal_position() -> Vector3:
	if Game.stage == 4: return Vector3(-26,Layout.FLOOR_Y,-70)
	if Game.stage == 5:
		var nearest := Vector3.INF
		var distance := INF
		for id: String in tablets:
			if id in Game.runes: continue
			var d: float = world.player.position.distance_squared_to(tablets[id])
			if d < distance:
				distance = d
				nearest = tablets[id]
		return nearest
	if Game.stage == 6: return world.ground(-3,-94)
	return Vector3.INF

func _physics_process(delta: float) -> void:
	if not world.playing or not world.player.enabled or Game.stage < 4 or Game.stage >= 7: return
	tick += delta
	if tick < .1: return
	var elapsed := tick
	tick = 0.0
	var at: Vector3 = world.player.position
	if Game.stage == 4:
		if contains(at) and at.z < -70 and world.player.is_on_floor():
			if Game.enter_ruins(): Game.save_game(at,true)
	elif Game.stage == 5:
		var candidate := ""
		for definition: Dictionary in Layout.config.inscriptions:
			var id: String = definition.id
			if id in Game.runes: continue
			if at.distance_to(tablets[id]) < 2.0:
				candidate = id
				nearby_hint = "Pare perto da inscrição: " + str(definition.name)
				break
		if candidate.is_empty(): nearby_hint = ""
		if candidate != dwell_id:
			dwell_id = candidate
			dwell = 0.0
		if not candidate.is_empty() and world.player.is_on_floor() and world.player.movement_speed < 1.5:
			dwell += elapsed
			if dwell >= READ_SECONDS and Game.read_inscription(candidate):
				Game.save_game(at,true)
		else: dwell = 0.0
	elif Game.stage == 6 and world.player.is_on_floor() and at.distance_to(world.ground(-3,-94)) < 3.5:
		if Game.reach_tree(): Game.save_game(at,true)
