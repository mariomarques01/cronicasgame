extends SceneTree
var failures := 0

func check(ok: bool, description: String) -> bool:
	if ok:
		print("PACK PASS: ", description)
	else:
		failures += 1
		push_error(description)
	return ok

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	if not check(scene != null, "Cena principal incluída no pacote"):
		quit(1)
		return
	var world: Node3D = scene.instantiate()
	root.add_child(world)
	await physics_frame
	for path in ["GoldenAcres/CozyTimberHouse", "GoldenAcres/FarmBuildings/Workshop", "GoldenAcres/FarmBuildings/Barn", "GoldenAcres/FarmBuildings/Windmill/SlowRotor", "Trees", "Lia/WolfCharacter", "MeadowDetails", "ValleyAtmosphere/ValleyEnvironment"]:
		check(world.get_node_or_null(path) != null, "Recurso exportado: " + path)
	if failures > 0:
		quit(1)
		return
	check(ResourceLoader.exists("res://assets/ui/hud/bag.svg") and ResourceLoader.exists("res://assets/ui/hud/bunny_portrait.png"), "Arte do HUD selecionada para exportação")
	if not check(world.ui.ornament != null, "HUD ornamental inicializado no pacote"):
		quit(1)
		return
	check(world.ui.ornament.minimap.viewport.world_3d == world.get_world_3d(), "Minimapa funcional incluído no pacote")
	check_texture_budget(world)
	check(not ResourceLoader.exists("res://assets/models/golden_acres.glb"), "Pacote não inclui a fazenda original substituída")
	check(not ResourceLoader.exists("res://assets/models/farm_without_fences.res"), "Malha antiga com pedras/flores fora do pacote")
	check(not ResourceLoader.exists("res://assets/grass/source/emerald_meadow.glb"), "Modelo fonte de 534 mil faces fora do pacote")
	check(world.get_node_or_null("GoldenAcres/CultivatedPlants/Cabbages") != null and world.get_node_or_null("GoldenAcres/CultivatedPlants/Carrots") != null, "Repolhos e cenouras incluídos no pacote")
	check(not ResourceLoader.exists("res://assets/models/farm_crops.res"), "Plantações antigas removidas do pacote")
	check(not ResourceLoader.exists("res://assets/crops/source/cabbage.glb") and not ResourceLoader.exists("res://assets/crops/source/carrots.glb"), "Modelos fonte pesados fora do pacote")
	var meadow: MeshInstance3D = world.get_node("GoldenAcres/FarmCollision/EmeraldMeadowGround")
	check(meadow.material_override.get_shader_parameter("grass_tex").get_width() == 1024, "Nova grama exportada em 1024 px")
	var game := root.get_node("Game")
	check(typeof(game.quest) == TYPE_DICTIONARY and game.quest.has("id"), "Dados JSON da missão incluídos")
	world.start_game(false)
	check(world.playing and world.player.enabled and not world.ui.title_screen.visible, "Jornada inicia a partir do pacote")
	check(world.get_node("Trees").tree_count == 157, "Floresta externa reduzida pela metade")
	game.talk()
	for id in ["stone_0", "stone_1", "stone_2"]:
		check(game.collect(id), "Missão no pacote: " + id)
	game.talk()
	check(game.activate_gate(), "Missão desbloqueia a passagem")
	print("PACK RESULTADO: ", failures, " falhas")
	quit(0 if failures == 0 else 1)

# Check the resources actually loaded by the exported world, including shared
# MultiMesh materials. Compressed download size does not measure GPU memory.
func check_texture_budget(world: Node) -> void:
	var textures: Dictionary = {}
	for node: Node in world.find_children("*", "", true, false):
		var mesh: Mesh
		if node is MeshInstance3D:
			mesh = node.mesh
			if node.material_override is ShaderMaterial:
				var shader_material: ShaderMaterial = node.material_override
				for uniform: Dictionary in shader_material.shader.get_shader_uniform_list():
					var value: Variant = shader_material.get_shader_parameter(uniform.name)
					if value is Texture2D:
						textures[value.get_instance_id()] = value
		elif node is MultiMeshInstance3D and node.multimesh:
			mesh = node.multimesh.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as BaseMaterial3D
			if material == null:
				continue
			for slot in BaseMaterial3D.TEXTURE_MAX:
				var texture := material.get_texture(slot)
				if texture:
					textures[texture.get_instance_id()] = texture
	check(textures.size() >= 20, "Auditoria encontra texturas dos modelos exportados")
	var estimated_bytes := 0
	for texture: Texture2D in textures.values():
		check(texture.get_width() <= 1024 and texture.get_height() <= 1024,
			"Textura 3D limitada a 1024: " + texture.resource_path)
		# Conservative RGBA8 estimate including a full mip chain.
		estimated_bytes += ceili(texture.get_width() * texture.get_height() * 4.0 * 4.0 / 3.0)
	print("PACK TEXTURES: ", textures.size(), "; RGBA8 + mipmaps MiB: ", estimated_bytes / 1048576.0)
	check(estimated_bytes <= 192 * 1024 * 1024, "Texturas do mundo dentro do orçamento de 192 MiB")
