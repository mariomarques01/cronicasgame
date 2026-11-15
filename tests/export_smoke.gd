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
	for path in ["GoldenAcres/CozyTimberHouse", "GoldenAcres/FarmBuildings/Workshop", "GoldenAcres/FarmBuildings/Barn", "GoldenAcres/FarmBuildings/Windmill/SlowRotor", "Trees", "Lia/WolfCharacter", "LandingFeedback", "AncientRuins", "MeadowDetails", "ValleyAtmosphere/ValleyEnvironment"]:
		check(world.get_node_or_null(path) != null, "Recurso exportado: " + path)
	if failures > 0:
		quit(1)
		return
	check(ResourceLoader.exists("res://assets/ui/hud/bag.svg") and ResourceLoader.exists("res://assets/ui/hud/bunny_portrait.png"), "Arte do HUD selecionada para exportação")
	if not check(world.ui.ornament != null, "HUD ornamental inicializado no pacote"):
		quit(1)
		return
	check(world.ui.ornament.minimap.viewport.world_3d == world.get_world_3d(), "Minimapa funcional incluído no pacote")
	check(not ResourceLoader.exists("res://assets/models/bunny_animated.glb") and not ResourceLoader.exists("res://assets/models/Jumping.fbx"), "Personagens de alta densidade fora do pacote")
	check(world.player.avatar.animation_player.has_animation("Jumping") and world.player.avatar.animation_player.has_animation("JumpLanding"), "Pulo e contato pré-processados presentes no pacote")
	check(not ResourceLoader.exists("res://scripts/world/forest_trail.gd") and world.get_node_or_null("ForestTrail") == null, "Trilha rejeitada fora do pacote")
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
	var had_previous := FileAccess.file_exists(game.SAVE_PATH)
	var previous := FileAccess.get_file_as_string(game.SAVE_PATH) if had_previous else ""
	check(typeof(game.quest) == TYPE_DICTIONARY and game.quest.has("id"), "Dados JSON da missão incluídos")
	world.start_game(false)
	check(world.playing and world.player.enabled and not world.ui.title_screen.visible, "Jornada inicia a partir do pacote")
	check(world.get_node("Trees").tree_count > 120 and world.get_node("Trees").tree_count < 157, "Floresta mantém cobertura e libera as novas trilhas")
	world.interact("lia")
	world.ui.show_play()
	for id in ["stone_0", "stone_1", "stone_2"]:
		var count_before: int = world.get_node("LandingFeedback").collection_count
		world.interact(id)
		check(id in game.collected, "Missão no pacote: " + id)
		check(world.get_node("LandingFeedback").collection_count == count_before + 1, "Coleta no pacote dispara efeito: " + id)
	check(game.stage == 4 and game.regions == ["valley", "forest"], "Uma conversa e três pedras abrem passagem automaticamente")
	await physics_frame
	check(not world.gate.visible and world.gate.get_child(1).disabled, "Passagem exportada libera colisão sem mecanismo")
	world.player.position = world.ground(-26,-74,.08)
	world.player.velocity = Vector3.ZERO
	for frame in 35: await physics_frame
	check(game.stage == 5, "Área exportada inicia investigação ao entrar no pátio")
	for id in ["roots","waters","light"]:
		world.player.position = world.ruins.tablets[id] + Vector3(0,.08,1.5)
		world.player.velocity = Vector3.ZERO
		for frame in 80: await physics_frame
		check(id in game.runes, "Inscrição exportada avança automaticamente: " + id)
	check(game.stage == 6 and game.runes.size() == 3, "Pacote revela caminho da Árvore Ancestral")
	world.player.position = world.ground(-3,-94,.08)
	world.player.velocity = Vector3.ZERO
	for frame in 40: await physics_frame
	check(game.stage == 7, "Chegada à árvore conclui jornada no pacote exportado")
	if not had_previous:
		DirAccess.remove_absolute(game.SAVE_PATH)
	else:
		var file := FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
		file.store_string(previous)
		file.close()
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
