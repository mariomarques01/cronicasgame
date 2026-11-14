extends SceneTree
var failures: int = 0
var game: Node
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: " + description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame
	game = root.get_node("Game")
	var previous := ""
	if FileAccess.file_exists(game.SAVE_PATH):
		previous = FileAccess.get_file_as_string(game.SAVE_PATH)
	var world: Node3D = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	check(world.ui.menu.position.x >= 0 and world.ui.menu.position.y >= 0, "Menu posicionado dentro da janela")
	var title: Control = world.ui.title_screen
	check(title.visible and not world.ui.menu.visible and not world.ui.hud.visible, "Abertura usa arte dedicada sem painel antigo ou HUD")
	var original_size: Vector2 = title.size
	for viewport_size: Vector2 in [Vector2(390, 844), Vector2(844, 390), Vector2(1280, 720)]:
		title.size = viewport_size
		title.layout_art()
		var art_rect := Rect2(title.frame.position, title.frame.size)
		check(Rect2(Vector2.ZERO, viewport_size).encloses(art_rect) and is_equal_approx(title.frame.size.x / title.frame.size.y, 0.75), "Arte inteira sem distorção em " + str(viewport_size))
		var button_center: Vector2 = title.start_button.get_global_rect().get_center()
		check(art_rect.has_point(button_center), "Botão clicável acompanha arte em " + str(viewport_size))
	title.size = original_size
	title.layout_art()
	check(title.continue_button.visible == FileAccess.file_exists(game.SAVE_PATH), "Continuar aparece somente com salvamento")
	title.start_button.pressed.emit()
	check(world.playing and not title.visible and world.ui.hud.visible, "Botão da arte inicia jornada e revela jogo")
	await physics_frame
	check_farm_paths(world)
	check_visual_polish(world)
	check(world.get_node_or_null("GoldenAcres") != null, "Fazenda Golden Acres importada no cenário jogável")
	var trees := world.get_node("Trees")
	check(trees.pine_count >= 3 and trees.tree_count > 100, "Pinheiros internos e árvores externas carregados")
	var correctly_classified := true
	for tree: Dictionary in trees.placements:
		correctly_classified = correctly_classified and tree.pine == trees.is_inside(Vector2(tree.position.x, tree.position.z))
	check(correctly_classified, "Cada árvore usa modelo definido pelo contorno real do cercado")
	check(trees.is_inside(Vector2(0, 0)) and not trees.is_inside(Vector2(50, 45)), "Classificação usa perímetro poligonal em vez de caixa retangular")
	check(not trees.is_inside(Vector2(0, -94)) and trees.get_node_or_null("AncientTree") != null, "Árvore ancestral externa também substituída pelo arquivo árvore")
	check(world.terrain.height_at(-41, 29) < 0.6, "Tronco inclinado antigo removido sem fragmento alto junto ao pinheiro")
	var pine_batches := 0
	var tree_batches := 0
	for node in trees.get_children():
		if node is MultiMeshInstance3D:
			if node.multimesh.mesh == trees.PINE:
				pine_batches += 1
			if node.multimesh.mesh == trees.TREE:
				tree_batches += 1
	check(pine_batches > 0 and tree_batches > 1, "Árvores compartilham modelos e floresta é dividida em setores")
	var building_config: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_buildings.json"))
	var buildings := world.get_node("GoldenAcres/FarmBuildings")
	check(buildings.get_child_count() == 3, "Moinho, celeiro e oficina substituídos como elementos independentes")
	for spec: Dictionary in building_config:
		var building: Node3D = buildings.get_node(str(spec.id))
		var visual: MeshInstance3D = building.get_node("Visual")
		check(visual.mesh.surface_get_material(0) != null and visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3 < 70000, "Modelo otimizado com material fornecido: " + str(spec.id))
		var ground_visual: MeshInstance3D = building.get_node(str(spec.id) + "Ground").get_child(0)
		check(ground_visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0].y > 0.9, "Piso orientado para cima: " + str(spec.id))
		var p: Vector3 = building.position
		check(world.terrain.farm.surface_height(p.x, p.z) < 0.1, "Construção antiga removida da malha fundida: " + str(spec.id))
		var roof_ray := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 30, p - Vector3.UP * 3)
		var roof := world.get_world_3d().direct_space_state.intersect_ray(roof_ray)
		check(not roof.is_empty() and roof.collider.name == str(spec.id) + "Collision", "Colisão corresponde ao novo modelo: " + str(spec.id))
	var workshop_approach := PhysicsRayQueryParameters3D.create(Vector3(-30, 0.8, -16), Vector3(-30, 0.8, -17.5))
	check(world.get_world_3d().direct_space_state.intersect_ray(workshop_approach).is_empty(), "Acesso à pedra antiga perto da oficina permanece livre")
	var windmill_approach := PhysicsRayQueryParameters3D.create(Vector3(27, 0.8, 10), Vector3(27, 0.8, 14))
	check(world.get_world_3d().direct_space_state.intersect_ray(windmill_approach).is_empty(), "Acesso à pedra antiga perto do moinho permanece livre")
	check(is_instance_valid(buildings.rotor) and buildings.rotor.get_node("Vanes").mesh == buildings.ROTOR_MESH, "Hélices separadas da torre para animação")
	var tower: MeshInstance3D = buildings.get_node("Windmill/Visual")
	var tower_transform := tower.global_transform
	var axis_position: Vector3 = buildings.rotor.global_position
	var start_angle: float = buildings.rotor.rotation.z
	buildings.advance_rotor(1.0)
	check(is_equal_approx(angle_difference(start_angle, buildings.rotor.rotation.z), -TAU / 120.0), "Hélices giram devagar: uma volta a cada dois minutos")
	check(tower.global_transform.is_equal_approx(tower_transform) and buildings.rotor.global_position.is_equal_approx(axis_position), "Torre e eixo permanecem fixos durante giro")
	buildings.advance_rotor(119.0)
	check(absf(angle_difference(buildings.rotor.rotation.z, start_angle)) < 0.00001, "Giro completa volta contínua sem deslocar o moinho")
	var was_enabled: bool = world.player.enabled
	world.player.enabled = false
	var pause_angle: float = buildings.rotor.rotation.z
	buildings._process(1.0)
	check(is_equal_approx(buildings.rotor.rotation.z, pause_angle), "Pausa também interrompe as hélices")
	world.player.enabled = was_enabled
	var static_triangles: int = buildings.MODELS["windmill"].surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3
	var rotor_triangles: int = buildings.ROTOR_MESH.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3
	check(static_triangles + rotor_triangles == buildings.WINDMILL_FRAME.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3, "Separação conserva geometria sem duplicar as hélices estáticas")
	check_new_crops(world)
	var lia: StaticBody3D = world.get_node("Lia")
	var lia_visual: MeshInstance3D = lia.get_node("WolfCharacter")
	check(lia_visual.mesh != null, "Lia usa personagem lobo fornecido")
	check(is_equal_approx(lia_visual.mesh.get_aabb().size.y * lia_visual.scale.y, 2.5), "Personagem da Lia dimensionado e apoiado no chão")
	check(lia.get_child(1) is CollisionShape3D and lia.position.is_equal_approx(world.ground(-30, 9)), "Lia mantém posição e colisão próprias")
	var main_house := world.get_node("GoldenAcres/CozyTimberHouse")
	check(main_house.visual.mesh != null, "Casa principal usa modelo Cozy Timber fornecido")
	check(is_equal_approx(main_house.visual.mesh.get_aabb().size.x * main_house.visual.scale.x, 24.0), "Casa dimensionada para o espaço da construção principal")
	check(main_house.visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3 < 60000, "Casa usa malha otimizada preservando materiais")
	check(absf(world.terrain.height_at(-13, 0) - 0.01) < 0.1, "Casa antiga removida da malha e colisão fundidas da fazenda")
	var house_ray := PhysicsRayQueryParameters3D.create(Vector3(-13, 20, 0), Vector3(-13, -2, 0))
	var house_hit := world.get_world_3d().direct_space_state.intersect_ray(house_ray)
	check(not house_hit.is_empty() and house_hit.collider.name == "HouseCollision", "Telhado da casa nova possui colisão correspondente")
	var west_walkway := PhysicsRayQueryParameters3D.create(Vector3(-31, 0.8, 5), Vector3(-31, 0.8, 9))
	check(world.get_world_3d().direct_space_state.intersect_ray(west_walkway).is_empty(), "Caminho oeste junto à casa permanece livre")
	var fence_layout := world.get_node("GoldenAcres/MossyGardenFences")
	check(fence_layout.section_count > 100, "Cerca Mossy Garden substitui cercados distribuídos pelo mapa")
	var fence_batch: MultiMeshInstance3D = fence_layout.get_node("FenceSections")
	check(fence_batch.multimesh.instance_count == fence_layout.section_count and fence_batch.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3 <= 5000, "Seções compartilham módulo simplificado para celular")
	var fence_body: StaticBody3D = fence_layout.get_node("MossyFenceCollisions")
	check(fence_body.get_child_count() == fence_layout.section_count, "Cada seção de cerca tem colisão correspondente")
	var fence_ray := PhysicsRayQueryParameters3D.create(Vector3(-30, 0.8, 24.75), Vector3(-25, 0.8, 24.75))
	var fence_hit := world.get_world_3d().direct_space_state.intersect_ray(fence_ray)
	check(not fence_hit.is_empty() and fence_hit.collider == fence_body, "Nova cerca bloqueia passagem através das tábuas")
	var field_gate_ray := PhysicsRayQueryParameters3D.create(Vector3(-8, 1.0, 14), Vector3(-8, 1.0, 17))
	check(world.get_world_3d().direct_space_state.intersect_ray(field_gate_ray).is_empty(), "Abertura da plantação permite atravessar sem colisão antiga")
	var entry_ray := PhysicsRayQueryParameters3D.create(Vector3(0, 0.8, 35), Vector3(0, 0.8, 48))
	check(world.get_world_3d().direct_space_state.intersect_ray(entry_ray).is_empty(), "Entrada sul livre do arco antigo deformado")
	var entry_floor_ray := PhysicsRayQueryParameters3D.create(Vector3(0, 3, 42), Vector3(0, -3, 42))
	var entry_floor := world.get_world_3d().direct_space_state.intersect_ray(entry_floor_ray)
	check(not entry_floor.is_empty() and entry_floor.collider.name in ["SouthEntranceGround", "FarmCollision"] and absf(entry_floor.position.y - 0.01) < 0.02, "Buraco do arco antigo coberto por caminho com colisão nivelada")
	var perimeter_ray := PhysicsRayQueryParameters3D.create(Vector3(-53, 0.8, 0), Vector3(-49, 0.8, 0))
	var perimeter_hit := world.get_world_3d().direct_space_state.intersect_ray(perimeter_ray)
	check(not perimeter_hit.is_empty() and perimeter_hit.collider == fence_body, "Perímetro externo também usa a nova cerca")
	var north_ray := PhysicsRayQueryParameters3D.create(Vector3(0, 0.8, -49), Vector3(0, 0.8, -46))
	check(world.get_world_3d().direct_space_state.intersect_ray(north_ray).is_empty(), "Nova cerca externa preserva acesso ao portão da floresta")
	var bed_ray := PhysicsRayQueryParameters3D.create(Vector3(-24, 5, 25), Vector3(-24, -3, 25))
	var bed_hit := world.get_world_3d().direct_space_state.intersect_ray(bed_ray)
	check(not bed_hit.is_empty() and bed_hit.position.y < 1.0, "Canteiro fundido rebaixado sem parede esticada junto à nova cerca")
	var garden_edge_ray := PhysicsRayQueryParameters3D.create(Vector3(21.6, 5, 16.45), Vector3(21.6, -3, 16.45))
	var garden_edge := world.get_world_3d().direct_space_state.intersect_ray(garden_edge_ray)
	check(not garden_edge.is_empty() and garden_edge.position.y < 0.5, "Borda da horta sem fragmento alto da parede antiga")
	var flat_samples := 0
	for point: Vector2 in [Vector2(-44, 5), Vector2(40, -28), Vector2(35, 32), Vector2(-32, 32), Vector2(-10, -28), Vector2(10, 8)]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(point.x, 0.5, point.y), Vector3(point.x, -0.5, point.y))
		var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider.name == "FarmCollision" and absf(hit.position.y - 0.01) < 0.001:
			flat_samples += 1
	check(flat_samples == 6, "Antigas pedras/flores substituídas por piso com colisão plana em toda a fazenda")
	var corners_clear := true
	for x in [-54.0, 54.0]:
		for z in [-52.0, 52.0]:
			corners_clear = corners_clear and world.terrain.base_height_at(x, z) < 0.0
	check(corners_clear, "Terreno externo não atravessa o piso nos cantos da fazenda")
	check(world.get_node_or_null("GoldenAcres/ClearedFarm") == null and world.get_node_or_null("Trees/TreeRootGround") == null, "Sem malha antiga ou remendos de grama sobre o novo piso")
	var meadow: MeshInstance3D = world.get_node("GoldenAcres/FarmCollision/EmeraldMeadowGround")
	check(meadow.mesh.get_faces().size() == 6, "Grama usa apenas dois triângulos no lugar do modelo de 534 mil faces")
	check(meadow.material_override.get_shader_parameter("grass_tex").resource_path == "res://assets/grass/emerald_meadow_albedo.png", "Chão usa a grama Emerald Meadow fornecida")
	check(world.crop_positions.is_empty() and not is_instance_valid(world.windmill), "Fazenda procedural anterior substituída")
	var spawn_ray := PhysicsRayQueryParameters3D.create(world.player.position + Vector3.UP * 10, world.player.position - Vector3.UP * 10)
	spawn_ray.exclude = [world.player.get_rid()]
	var spawn_hit := world.get_world_3d().direct_space_state.intersect_ray(spawn_ray)
	check(not spawn_hit.is_empty() and spawn_hit.collider.name == "FarmCollision", "Início do personagem apoiado na colisão do modelo Meshy")
	for target: Dictionary in world.targets:
		var target_ray := PhysicsRayQueryParameters3D.create(target.position + Vector3.UP * 3, target.position - Vector3.UP * 5)
		check(not world.get_world_3d().direct_space_state.intersect_ray(target_ray).is_empty(), "Apoio físico do objetivo " + target.id)
	check(world.player.avatar.get_node_or_null("BraveBunny") != null, "Modelo principal fornecido instanciado")
	check(world.player.camera != null, "Terceira pessoa e câmera criadas")
	world.player.enabled = false
	world.player.avatar.animate(0, true, false)
	for i in range(5):
		await process_frame
	check(world.player.avatar.animation_player.current_animation == "Walking" and world.player.avatar.animation_player.current_animation_position > 0, "Caminhada animada avança no tempo")
	world.player.avatar.animate(0, true, true)
	check(world.player.avatar.animation_player.current_animation == "Running", "Corrida seleciona Running")
	world.player.avatar.animate(0, true, true, false)
	var animator: AnimationPlayer = world.player.avatar.animation_player
	check(animator.current_animation == "Jumping" and animator.is_playing(), "No ar reproduz animação de pulo do FBX")
	var jump := animator.get_animation("Jumping")
	check(jump.loop_mode == Animation.LOOP_NONE and jump.get_track_count() >= 20, "Pulo adaptado ao esqueleto sem repetição")
	var safe_tracks := true
	for track in jump.get_track_count():
		var kind := jump.track_get_type(track)
		safe_tracks = safe_tracks and (kind == Animation.TYPE_ROTATION_3D or (kind == Animation.TYPE_POSITION_3D and str(jump.track_get_path(track)).ends_with(":mixamorig_Hips")))
	check(safe_tracks, "Pulo mantém translação restrita à flexão local do quadril")
	var skeleton := world.player.avatar.model.find_child("Skeleton3D", true, false) as Skeleton3D
	var leg := skeleton.find_bone("mixamorig_LeftLeg")
	world.player.avatar.animate(0.08, true, true, false, 8.0)
	animator.advance(0.08)
	check(is_equal_approx(animator.current_animation_position, 0.5), "Decolagem ignora antecipação do FBX")
	var first_pose := skeleton.get_bone_pose_rotation(leg)
	world.player.avatar.animate(0.08, true, true, false, 0.0)
	animator.advance(0.08)
	check(first_pose.angle_to(skeleton.get_bone_pose_rotation(leg)) > 0.01, "Animação de pulo move os ossos do coelho")
	check(is_equal_approx(animator.current_animation_position, 0.78), "Pose do ápice acompanha velocidade vertical zero")
	world.player.avatar.animate(2.0, true, true, false, -30.0)
	animator.advance(0.08)
	check(is_equal_approx(animator.current_animation_position, 1.1), "Queda longa segura pose de descida sem aterrissar no ar")
	world.player.avatar.animate(0, true, true, true)
	check(animator.current_animation == "JumpLanding", "Contato com chão inicia absorção da aterrissagem")
	animator.advance(0.08)
	check(skeleton.get_bone_pose_position(skeleton.find_bone("mixamorig_Hips")).y < 0.79, "Flexão de joelhos abaixa quadril na aterrissagem")
	world.player.avatar.animate(0.25, true, true, true)
	check(animator.current_animation == "Running", "Após absorver aterrissagem retoma corrida")
	world.player.avatar.animate(0, false, false)
	check(not world.player.avatar.animation_player.is_playing(), "Parado mantém pose estática")
	world.player.avatar.animate(0.03, false, false, false, -0.7)
	check(animator.assigned_animation == "Walking", "Pequeno desnível não dispara pose de pulo")
	world.player.avatar.animate(0.02, false, false, true, 0.0)
	check(animator.assigned_animation == "Walking", "Retorno de pequeno desnível não provoca agachamento")
	world.player.enabled = true
	check(InputMap.has_action("jump") and InputMap.has_action("interact"), "Input Map configurado")
	check(not game.collect("stone_0"), "Pedras bloqueadas antes da conversa")
	check(not game.activate_gate(), "Portão bloqueado antes da missão")
	check(not game.collect("unknown"), "Item desconhecido rejeitado")
	game.talk()
	check(game.stage == 1, "Conversa ativa missão")
	for i in range(3):
		check(game.collect("stone_%d" % i), "Coleta pedra %d" % i)
	check(not game.collect("stone_0"), "Coleta duplicada rejeitada")
	check(game.stage == 2 and game.inventory.ancient_stone == 3, "Inventário e retorno a Lia")
	check(not game.activate_gate(), "Exige retorno a Lia")
	game.talk()
	check(game.activate_gate(), "Mecanismo conclui missão")
	check(not game.activate_gate(), "Recompensa não duplica")
	await physics_frame
	check(not world.gate.visible and world.gate.get_child(1).disabled, "Portão invisível e colisão desativada")
	check(game.save_game(Vector3(0, 4, -60)), "Grava salvamento")
	game.reset()
	check(game.load_game(), "Carrega salvamento")
	await physics_frame
	check(game.stage == 4 and "forest" in game.regions and world.gate.get_child(1).disabled, "Desbloqueio persiste")
	var query := PhysicsRayQueryParameters3D.create(Vector3(60, 40, 40), Vector3(60, -20, 40))
	check(not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Terreno possui colisão")
	world.player.position = Vector3(-13.25, 5, 13.2)
	for i in range(150):
		await physics_frame
	check(world.player.is_on_floor(), "Personagem pousa sobre terreno")
	# Feed real Godot multi-touch events; no keyboard action is injected.
	world.ui.touch.active = true
	var center := Vector2(135, world.get_viewport().get_visible_rect().size.y - 145)
	var start: Vector3 = world.player.position
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = center
	world.get_viewport().push_input(press, true)
	Input.flush_buffered_events()
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = center + Vector2(0, -70)
	drag.relative = Vector2(0, -70)
	world.get_viewport().push_input(drag, true)
	Input.flush_buffered_events()
	for i in range(30):
		await physics_frame
	check(world.player.position.distance_to(start) > 0.5, "Joystick de toque move personagem sem teclado")
	press.pressed = false
	world.get_viewport().push_input(press, true)
	Input.flush_buffered_events()
	await process_frame
	check(world.player.touch_axis == Vector2.ZERO, "Soltar dedo interrompe joystick")
	var jump_touch := InputEventScreenTouch.new()
	jump_touch.index = 1
	jump_touch.pressed = true
	jump_touch.position = world.ui.touch.action_buttons[0].get_global_rect().get_center()
	world.get_viewport().push_input(jump_touch, true)
	await physics_frame
	await physics_frame
	check(world.player.velocity.y > 0, "Segundo dedo no botão Pular usa física do personagem")
	check(animator.current_animation == "Jumping", "Pulo por toque também dispara animação")
	jump_touch.pressed = false
	world.get_viewport().push_input(jump_touch, true)
	world.ui.touch.player.touch_axis = Vector2.ONE
	world.ui.pause_menu()
	check(world.player.touch_axis == Vector2.ZERO, "Pausa libera comandos de toque")
	world.ui.show_play()
	var yaw_before: float = world.player.yaw.rotation.y
	var look := InputEventScreenTouch.new()
	look.index = 1
	look.pressed = true
	look.position = Vector2(650, 100)
	world.get_viewport().push_input(look, true)
	var look_drag := InputEventScreenDrag.new()
	look_drag.index = 1
	look_drag.position = Vector2(690, 110)
	look_drag.relative = Vector2(40, 10)
	world.get_viewport().push_input(look_drag, true)
	world.player.update_camera(1.0 / 60.0)
	check(world.player.yaw.rotation.y != yaw_before, "Arrasto direito gira a câmera")
	look.pressed = false
	world.get_viewport().push_input(look, true)
	world.toggle_map()
	check(world.map_camera.current, "Mapa aéreo ativado")
	var map_yaw: float = world.player.camera_yaw
	world.player.rotate_camera(Vector2(100, 100))
	check(is_equal_approx(world.player.camera_yaw, map_yaw), "Mapa bloqueia giro da câmera do personagem")
	world.toggle_map()
	check(world.player.camera.current, "Retorno à câmera do personagem")
	world.player.rotate_camera(Vector2(0, -100000))
	world.player.update_camera(1.0)
	check(is_equal_approx(world.player.pitch.rotation.x, world.player.CAMERA_MAX_PITCH) and world.player.pitch.rotation.x < 0, "Inclinação superior mantém câmera acima do personagem")
	world.player.rotate_camera(Vector2(0, 100000))
	world.player.update_camera(1.0)
	check(is_equal_approx(world.player.pitch.rotation.x, world.player.CAMERA_MIN_PITCH), "Inclinação inferior limitada sem visão vertical livre")
	world.player.rotate_camera(Vector2(100000, 0))
	world.player.update_camera(0.02)
	check(is_zero_approx(world.player.yaw.rotation.x) and is_zero_approx(world.player.yaw.rotation.z) and is_zero_approx(world.player.pitch.rotation.y) and is_zero_approx(world.player.pitch.rotation.z), "Órbita mantém horizonte sem rolagem lateral")
	var previous_angle: float = world.player.yaw.rotation.y
	world.player.rotate_camera(Vector2(80, 0))
	check(is_equal_approx(world.player.yaw.rotation.y, previous_angle), "Mouse define alvo sem giro instantâneo")
	world.player.update_camera(0.016)
	check(not is_equal_approx(world.player.yaw.rotation.y, previous_angle), "Suavização aplica giro progressivamente")
	var focus_before: Vector3 = world.player.yaw.global_position
	world.player.position.y += 1.0
	world.player.update_camera(0.016)
	check(world.player.yaw.global_position.y > focus_before.y and world.player.yaw.global_position.y < world.player.global_position.y + 1.6, "Seguimento vertical amortece salto")
	world.player.position.y -= 1.0
	world.player.camera_pitch = world.player.CAMERA_DEFAULT_PITCH
	var valid: Variant = JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	valid.collected.append("stone_0")
	check(not game.valid_save(valid), "Rejeita coleta duplicada no save")
	var file := FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(not game.load_game(), "Arquivo inválido não causa falha")
	check(game.stage == 4, "Falha de carga preserva estado atual")
	DirAccess.remove_absolute(game.SAVE_PATH)
	check(not game.load_game(), "Arquivo ausente tratado")
	world.ui.show_play()
	world.player.position = Vector3(0, 2, 50)
	world.player.velocity = Vector3.ZERO
	world.player.camera_yaw = 0.0
	world.player.yaw.rotation.y = 0.0
	world.player.touch_axis = Vector2(0, -0.5625)
	for i in range(220):
		await physics_frame
	world.player.touch_axis = Vector2.ZERO
	check(world.player.position.z < 36 and world.player.is_on_floor(), "Personagem atravessa entrada sul caminhando sem salto ou parede invisível")
	world.player.position = Vector3(-5, 2, -27.3)
	world.player.velocity = Vector3.ZERO
	world.player.camera_yaw = -PI / 2
	world.player.yaw.rotation.y = -PI / 2
	world.player.touch_axis = Vector2(0, -0.5625)
	for i in range(150):
		await physics_frame
	world.player.touch_axis = Vector2.ZERO
	check(world.player.position.x > 3 and world.player.is_on_floor(), "Caminha pela frente do celeiro sem travar nas camadas do piso")
	await check_hud_layout(world)
	await check_retina_hud(world)
	await check_compact_hud(world)
	await check_third_person_controls(world)
	if not previous.is_empty():
		file = FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
		file.store_string(previous)
		file.close()
	world.queue_free()
	await process_frame
	print("RESULTADO: %d falhas" % failures)
	quit(1 if failures else 0)

func check_new_crops(world: Node3D) -> void:
	var crops: Node3D = world.get_node("GoldenAcres/CultivatedPlants")
	check(crops.crop_counts.get("cabbage", 0) == 48 and crops.crop_counts.get("carrots", 0) == 20, "Novo campo contém 48 repolhos e 20 módulos de cenouras")
	check(crops.find_children("*", "StaticBody3D", true, false).is_empty(), "Novos cultivos não recriam colisões irregulares no chão")
	var contained := true
	for crop: String in ["cabbage", "carrots"]:
		var batch: MultiMeshInstance3D = crops.get_node("Cabbages" if crop == "cabbage" else "Carrots")
		var triangles := 0
		for surface in batch.multimesh.mesh.get_surface_count():
			triangles += batch.multimesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size() / 3
		check(triangles <= 30000, "Modelo de cultivo otimizado para instâncias: " + crop)
		for i in batch.multimesh.instance_count:
			var bounds: AABB = crops.instance_transforms[crop][i] * batch.multimesh.mesh.get_aabb()
			var inside_bed := false
			for bed: Dictionary in crops.beds:
				if bed.crop != crop:
					continue
				inside_bed = inside_bed or (bounds.position.x >= float(bed.bounds[0]) - 0.01 and bounds.end.x <= float(bed.bounds[2]) + 0.01 and bounds.position.z >= float(bed.bounds[1]) - 0.01 and bounds.end.z <= float(bed.bounds[3]) + 0.01)
			contained = contained and inside_bed and absf(bounds.position.y - 0.02) < 0.001
	check(contained, "Todos os modelos apoiados no chão, dentro dos canteiros, sem invadir cercas ou corredores")
	check(crops.get_node_or_null("EmptyLateralGarden") != null, "Horta lateral antiga removida e deixada livre para próximos cultivos")

func check_farm_paths(world: Node3D) -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_paths.json"))
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	# The quest gate deliberately closes the forest route until its objective is complete.
	query.exclude = [world.player.get_rid(), world.gate.get_rid()]
	for path: Dictionary in layout.paths:
		var blocked: Array[String] = []
		for i in range(path.points.size() - 1):
			var a := Vector2(path.points[i][0], path.points[i][1])
			var b := Vector2(path.points[i + 1][0], path.points[i + 1][1])
			var perpendicular := (b - a).normalized().orthogonal()
			for step in range(ceili(a.distance_to(b)) + 1):
				var center := a.lerp(b, minf(float(step) / maxf(a.distance_to(b), 1.0), 1.0))
				for side in [-1.0, 0.0, 1.0]:
					var point: Vector2 = center + perpendicular * side * (float(path.width) * 0.5 - 0.5)
					query.transform = Transform3D(Basis.IDENTITY, Vector3(point.x, 1.05, point.y))
					var hits := world.get_world_3d().direct_space_state.intersect_shape(query, 1)
					if not hits.is_empty():
						var description := str(hits[0].collider.name) + " at " + str(point.snapped(Vector2.ONE * 0.1))
						if not description in blocked:
							blocked.append(description)
		check(blocked.is_empty(), "Caminho livre para a cápsula do jogador (centro e bordas): " + str(path.id) + ("; " + str(blocked) if not blocked.is_empty() else ""))
	var mask: Texture2D = world.terrain.ground_material.get_shader_parameter("road_mask")
	var image := mask.get_image()
	for plot: Dictionary in layout.protected_plots:
		var bounds: Array = plot.bounds
		var clear := true
		for x in range(1, 5):
			for z in range(1, 5):
				var point := Vector2(lerpf(bounds[0], bounds[2], x / 5.0), lerpf(bounds[1], bounds[3], z / 5.0))
				var uv := (point - Vector2(layout.mask_bounds[0], layout.mask_bounds[1])) / Vector2(layout.mask_bounds[2] - layout.mask_bounds[0], layout.mask_bounds[3] - layout.mask_bounds[1])
				clear = clear and image.get_pixel(int(uv.x * image.get_width()), int(uv.y * image.get_height())).r < 0.01
		check(clear, "Estrada não invade a plantação: " + str(plot.id))

func check_visual_polish(world: Node3D) -> void:
	var meadow := world.get_node("MeadowDetails")
	check(meadow.grass_count > 1000 and meadow.grass_count <= meadow.MAX_GRASS, "Cobertura vegetal tem orçamento limitado de instâncias")
	check(meadow.flower_count > 100 and meadow.flower_count <= meadow.MAX_FLOWERS, "Flores têm orçamento limitado de instâncias")
	var clear := true
	for pose: Transform3D in meadow.grass_placements + meadow.flower_placements:
		clear = clear and meadow.can_plant(Vector2(pose.origin.x, pose.origin.z))
	check(clear, "Detalhes não invadem caminhos, casa, construções ou cultivos protegidos")
	check(meadow.find_children("*", "CollisionObject3D", true, false).is_empty(), "Vegetação decorativa não acrescenta obstáculos à circulação")
	check(world.atmosphere.environment.fog_enabled and not world.atmosphere.environment.volumetric_fog_enabled, "Névoa usa recurso compatível com WebGL")
	world.atmosphere.set_daylight(0.0)
	var night: float = world.atmosphere.environment.ambient_light_energy
	world.atmosphere.set_daylight(1.0)
	check(world.atmosphere.environment.ambient_light_energy > night, "Iluminação ambiente acompanha dia e noite")
	check(world.ui.quest_panel.visible and world.ui.objective.text == root.get_node("Game").objective(), "HUD exibe objetivo real da missão")
	check(world.ui.ornament.minimap.viewport.world_3d == world.get_world_3d(), "Minimapa usa o mundo real da fazenda")
	check(world.ui.ornament.progress.value == root.get_node("Game").stage and world.ui.ornament.stone_count.text == "%d / 3" % root.get_node("Game").collected.size(), "Retrato e contadores mostram progresso real, sem valores fictícios")
	check(not world.ui.hint.visible and not world.ui.message.visible, "HUD não exibe painéis vazios de interação ou aviso")

func check_hud_layout(world: Node3D) -> void:
	var original_size := root.size
	var original_touch: bool = world.ui.touch.active
	for viewport_size: Vector2i in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]:
		root.size = viewport_size
		world.ui.touch.active = viewport_size.x < 1000
		world.ui.show_play()
		for frame in 10:
			await process_frame
		var screen := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
		check(screen.encloses(world.ui.quest_panel.get_global_rect()) and screen.encloses(world.ui.map_button.get_global_rect()), "Missão e mapa dentro da tela em " + str(viewport_size))
		check(not world.ui.region.get_global_rect().intersects(world.ui.map_button.get_global_rect()) and not world.ui.quest_panel.get_global_rect().intersects(world.ui.map_button.get_global_rect()), "Missão não sobrepõe mapa em " + str(viewport_size))
		if world.ui.touch.active:
			var buttons_clear := true
			for action: Button in world.ui.touch.action_buttons:
				if action.is_visible_in_tree():
					buttons_clear = buttons_clear and screen.encloses(action.get_global_rect())
			check(buttons_clear, "Botões de toque dentro da tela em " + str(viewport_size))
		world.ui.pause_menu()
		for frame in 10:
			await process_frame
		check(screen.encloses(world.ui.menu.get_global_rect()), "Menu de pausa cabe na tela em " + str(viewport_size))
		check(is_zero_approx(world.atmosphere.motes.speed_scale), "Partículas respeitam pausa em " + str(viewport_size))
	root.size = original_size
	world.ui.touch.active = original_touch
	world.ui.show_play()

func check_retina_hud(world: Node3D) -> void:
	var original_size := root.size
	var original_touch: bool = world.ui.touch.active
	var original_mode := root.content_scale_mode
	var original_aspect := root.content_scale_aspect
	var original_design := root.content_scale_size
	var scaler = preload("res://scripts/ui/display_scale.gd")
	world.ui.touch.active = true
	for css_size: Vector2i in [Vector2i(390, 844), Vector2i(844, 390)]:
		for density in [1, 2, 3]:
			root.size = css_size * density
			scaler.apply_css_size(root, css_size)
			world.ui.show_play()
			for frame in 10:
				await process_frame
			var description := "%s DPR %d" % [css_size, density]
			check(root.get_visible_rect().size.is_equal_approx(Vector2(css_size)), "HUD usa dimensões CSS em " + description)
			var screen_transform := root.get_final_transform()
			var jump_button: Button = world.ui.touch.action_buttons[0]
			var drawn_width := screen_transform.basis_xform(Vector2(jump_button.size.x, 0)).length()
			check(drawn_width / density >= 64, "Botão mantém tamanho confortável em CSS em " + description)
			var bounds := Rect2(Vector2.ZERO, Vector2(css_size))
			check(bounds.encloses(world.ui.quest_panel.get_global_rect()) and bounds.encloses(jump_button.get_global_rect()), "Missão e botões cabem após escala Retina em " + description)
			# Send physical pixel events, as DisplayServer does, not pre-scaled UI events.
			var press := InputEventScreenTouch.new()
			press.index = 0
			press.pressed = true
			press.position = screen_transform * jump_button.get_global_rect().get_center()
			world.player.touch_jump = false
			root.push_input(press, false)
			check(world.player.touch_jump, "Toque físico aciona Pular na posição desenhada em " + description)
			press.pressed = false
			root.push_input(press, false)
			world.player.touch_jump = false
			var center := Vector2(85 if css_size.x < 600 else 135, css_size.y - 120)
			press.index = 1
			press.pressed = true
			press.position = screen_transform * center
			root.push_input(press, false)
			var drag := InputEventScreenDrag.new()
			drag.index = 1
			drag.position = screen_transform * (center + Vector2(0, -40))
			drag.relative = screen_transform.basis_xform(Vector2(0, -40))
			root.push_input(drag, false)
			check(world.player.touch_axis.y < -0.5, "Joystick transforma arrasto de pixels físicos em " + description)
			press.pressed = false
			root.push_input(press, false)
			check(world.player.touch_axis == Vector2.ZERO, "Soltar joystick libera movimento em " + description)
			world.player.camera_yaw = 0
			var look_point := Vector2(css_size) * Vector2(0.6, 0.5)
			press.index = 2
			press.pressed = true
			press.position = screen_transform * look_point
			root.push_input(press, false)
			drag.index = 2
			drag.position = screen_transform * (look_point + Vector2(40, 0))
			drag.relative = screen_transform.basis_xform(Vector2(40, 0))
			root.push_input(drag, false)
			var expected_yaw := -40.0 * PI / maxf(320.0, minf(css_size.x, css_size.y))
			check(absf(world.player.camera_yaw - expected_yaw) < 0.001, "Câmera transforma arrasto físico com sensibilidade constante em " + description)
			press.pressed = false
			root.push_input(press, false)
	# A transient hidden canvas must not collapse a valid layout.
	var valid_design := root.content_scale_size
	scaler.apply_css_size(root, Vector2i.ZERO)
	check(root.content_scale_size == valid_design, "Rotação não aplica canvas temporariamente vazio")
	root.content_scale_mode = original_mode
	root.content_scale_aspect = original_aspect
	root.content_scale_size = original_design
	root.size = original_size
	world.ui.touch.active = original_touch
	world.ui.show_play()

func tap_hud(world: Node3D, action: Button) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 4
	press.pressed = true
	press.position = root.get_final_transform() * action.get_global_rect().get_center()
	root.push_input(press, false)
	press.pressed = false
	root.push_input(press, false)

func menu_action(world: Node3D, title: String) -> Button:
	for child in world.ui.content.get_children():
		if child is Button and child.text == title:
			return child
	return null

func check_compact_hud(world: Node3D) -> void:
	var original_size := root.size
	var original_mode := root.content_scale_mode
	var original_aspect := root.content_scale_aspect
	var original_design := root.content_scale_size
	var original_touch: bool = world.ui.touch.active
	root.size = Vector2i(1170, 2532)
	preload("res://scripts/ui/display_scale.gd").apply_css_size(root, Vector2i(390, 844))
	world.ui.touch.active = true
	world.ui.show_play()
	for frame in 10:
		await process_frame
	check(world.ui.quest_panel.size.y <= 64, "Missão recolhida ocupa no máximo 64 pixels CSS de altura")
	check(not world.ui.objective.visible and not world.ui.quest_progress.visible and world.ui.ornament.quest_summary.visible, "HUD de missão mostra só o resumo sem textos repetidos")
	check(world.ui.mobile_buttons.get_child_count() == 3, "HUD móvel fica com três ações principais")
	var no_pause := true
	for child in world.ui.mobile_buttons.get_children() + world.ui.desktop_actions.get_children():
		if child is Button:
			no_pause = no_pause and not "Pausa" in child.text and not "Pausa" in child.tooltip_text
	check(no_pause, "Pausa não ocupa um botão permanente no HUD")
	tap_hud(world, world.ui.ornament.quest_button)
	check(world.ui.menu.visible and not world.player.enabled, "Toque na faixa abre os detalhes da missão")
	var has_objective := false
	for child in world.ui.content.get_children():
		if child is Label and child.text == game.objective():
			has_objective = true
	check(has_objective, "Detalhes preservam o objetivo completo e atual da missão")
	var back := menu_action(world, "Voltar ao jogo")
	check(back != null, "Detalhes da missão oferecem retorno ao jogo")
	if back:
		back.pressed.emit()
	tap_hud(world, world.ui.ornament.settings)
	check(world.ui.menu.visible and world.ui.content.get_child(0).text == "Configurações", "Engrenagem abre Configurações por toque em DPR 3")
	var pause := menu_action(world, "Pausar jogo")
	check(pause != null, "Opção Pausar jogo está dentro de Configurações")
	if pause:
		pause.pressed.emit()
	check(not world.player.enabled and menu_action(world, "Retomar") != null, "Pausar pelas configurações abre o menu de pausa")
	var resume := menu_action(world, "Retomar")
	if resume:
		resume.pressed.emit()
	check(world.player.enabled and not world.ui.menu.visible, "Retomar após pausa devolve controle do personagem")
	root.content_scale_mode = original_mode
	root.content_scale_aspect = original_aspect
	root.content_scale_size = original_design
	root.size = original_size
	world.ui.touch.active = original_touch
	world.ui.show_play()


func control_touch(world: Node3D, index: int, point: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event, true)

func control_drag(index: int, point: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	event.relative = relative
	root.push_input(event, true)

func settle_control_player(world: Node3D, floor_body: StaticBody3D) -> void:
	for action in ["forward", "back", "left", "right", "run", "jump"]:
		Input.action_release(action)
	floor_body.collision_layer = 1
	world.ui.show_play()
	world.ui.touch.reset()
	world.player.position = Vector3(0, 60.03, 0)
	world.player.velocity = Vector3.ZERO
	world.player.camera_yaw = 0.0
	world.player.yaw.rotation.y = 0.0
	for frame in 12:
		await physics_frame

func check_third_person_controls(world: Node3D) -> void:
	# Real character physics on a broad platform above the farm: no props interfere.
	var platform := StaticBody3D.new()
	platform.position.y = 59.5
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(80, 1, 80)
	collision.shape = shape
	platform.add_child(collision)
	world.add_child(platform)
	var player: CharacterBody3D = world.player
	var touch: Control = world.ui.touch
	var original_touch: bool = touch.active
	touch.active = true
	await settle_control_player(world, platform)
	check(player.is_on_floor(), "Plataforma de teste apoia o controlador real")
	player.touch_axis = Vector2(0, -0.25)
	await physics_frame
	check(player.movement_speed > 0 and player.movement_speed < 2, "Aceleração começa progressivamente, sem salto imediato de velocidade")
	for frame in 30:
		await physics_frame
	var slow_speed: float = player.movement_speed
	var slow_animation: float = player.avatar.animation_player.speed_scale
	check(absf(slow_speed - 2.0) < 0.1, "Um quarto do analógico produz um quarto da velocidade máxima")
	player.touch_axis = Vector2(0, -1)
	for frame in 30:
		await physics_frame
	check(absf(player.movement_speed - player.RUN_SPEED) < 0.1 and player.state == "run", "Borda do analógico chega à corrida com animação correspondente")
	check(player.avatar.animation_player.speed_scale > slow_animation, "Ritmo da animação acompanha a velocidade real")
	player.touch_axis = Vector2(1, -1)
	for frame in 30:
		await physics_frame
	check(player.movement_speed <= player.RUN_SPEED + 0.01, "Diagonal não ultrapassa a velocidade máxima")
	var brake_start: Vector3 = player.position
	player.touch_axis = Vector2.ZERO
	for frame in 15:
		await physics_frame
	check(player.movement_speed < 0.05 and player.state == "idle", "Soltar analógico freia e entra em repouso")
	check(player.position.distance_to(brake_start) < 0.8, "Frenagem não deixa o personagem deslizar por metros")
	await settle_control_player(world, platform)
	player.camera_yaw = PI / 2
	player.yaw.rotation.y = PI / 2
	player.touch_axis = Vector2(0, -0.5)
	for frame in 30:
		await physics_frame
	check(player.velocity.x < -3.8 and absf(player.velocity.z) < 0.1, "Mover para frente acompanha a direção visível da câmera")
	await settle_control_player(world, platform)
	Input.action_press("forward")
	for frame in 30:
		await physics_frame
	check(absf(player.movement_speed - player.WALK_SPEED) < 0.1, "Teclado preserva a velocidade de caminhada")
	Input.action_press("run")
	for frame in 20:
		await physics_frame
	check(absf(player.movement_speed - player.RUN_SPEED) < 0.1, "Shift acelera até a corrida")
	Input.action_release("forward")
	Input.action_release("run")
	world.ui.settings_menu()
	for frame in 2:
		await physics_frame
	world.ui.show_play()
	for frame in 2:
		await physics_frame
	check(player.movement_speed < 0.05, "Retomar de um menu não reaplica impulso de movimento antigo")
	await settle_control_player(world, platform)
	var feedback := world.get_node("LandingFeedback")
	var impacts_before: int = feedback.trigger_count
	player.touch_jump = true
	for frame in 50:
		await physics_frame
	check(feedback.trigger_count > impacts_before, "Aterrissagem real produz feedback visual de contato")
	world.ui.settings_menu()
	for frame in 2:
		await process_frame
	var feedback_paused := true
	for burst: CPUParticles3D in feedback.bursts:
		feedback_paused = feedback_paused and is_zero_approx(burst.speed_scale)
	check(feedback_paused, "Poeira de impacto respeita a pausa dos menus")
	await settle_control_player(world, platform)
	var step_body := StaticBody3D.new()
	step_body.position = Vector3(0, 60.1, -3)
	var step_collision := CollisionShape3D.new()
	var step_shape := BoxShape3D.new()
	step_shape.size = Vector3(3, 0.2, 1)
	step_collision.shape = step_shape
	step_body.add_child(step_collision)
	world.add_child(step_body)
	player.touch_axis = Vector2(0, -0.5625)
	var maximum_step_y := player.position.y
	impacts_before = feedback.trigger_count
	for frame in 65:
		await physics_frame
		maximum_step_y = maxf(maximum_step_y, player.position.y)
	check(player.position.z < -3.8 and maximum_step_y > 60.15 and maximum_step_y < 60.32, "Controlador transpõe degrau baixo sem precisar pular")
	check(feedback.trigger_count == impacts_before, "Pequenos desníveis não disparam impactos fortes a cada passo")
	step_body.position.y = 60.4
	step_shape.size.y = 0.8
	await settle_control_player(world, platform)
	player.touch_axis = Vector2(0, -0.5625)
	for frame in 65:
		await physics_frame
	check(player.position.z > -2.5 and player.position.y < 60.1, "Obstáculo alto permanece bloqueado, sem atravessar ou escalar a colisão")
	step_body.queue_free()
	await settle_control_player(world, platform)
	platform.collision_layer = 0
	for frame in 2:
		await physics_frame
	check(not player.is_on_floor(), "Controlador perdeu o apoio antes do teste de tolerância")
	player.touch_jump = true
	for frame in 2:
		await physics_frame
	check(player.velocity.y > 5, "Salto ainda responde logo após perder o apoio")
	await settle_control_player(world, platform)
	platform.collision_layer = 0
	for frame in 15:
		await physics_frame
	player.touch_jump = true
	for frame in 2:
		await physics_frame
	check(player.velocity.y < 0, "Tolerância de borda expira e não permite pular indefinidamente no ar")
	platform.collision_layer = 1
	player.position = Vector3(0, 60.22, 0)
	player.velocity = Vector3(0, -2, 0)
	player.touch_jump = true
	for frame in 12:
		await physics_frame
	check(player.velocity.y > 0 and player.position.y > 60.2, "Salto apertado antes de pousar é executado ao tocar o chão")
	await settle_control_player(world, platform)
	var origin := Vector2(70, root.get_visible_rect().size.y - 180)
	control_touch(world, 0, origin, true)
	check(touch.stick_id == 0 and touch.stick_center == origin and player.touch_axis == Vector2.ZERO, "Joystick flutuante começa sob o dedo sem disparar movimento")
	control_drag(0, origin + Vector2(4, 0), Vector2(4, 0))
	check(player.touch_axis == Vector2.ZERO, "Zona morta elimina pequenas oscilações do polegar")
	control_drag(0, origin + Vector2(30, 0), Vector2(26, 0))
	check(player.touch_axis.x > 0.3 and player.touch_axis.x < 0.6, "Meio curso do joystick mantém intensidade intermediária")
	var held_axis: Vector2 = player.touch_axis
	var look_origin := Vector2(root.get_visible_rect().size.x * 0.7, root.get_visible_rect().size.y * 0.5)
	control_touch(world, 1, look_origin, true)
	var yaw_before: float = player.camera_yaw
	control_drag(1, look_origin + Vector2(40, 0), Vector2(40, 0))
	check(absf(player.camera_yaw - yaw_before) > 0.05 and player.touch_axis == held_axis, "Segundo dedo gira a câmera enquanto o primeiro mantém movimento")
	control_touch(world, 2, touch.action_buttons[0].get_global_rect().get_center(), true)
	check(player.touch_jump and touch.look_id == 1 and touch.stick_id == 0, "Terceiro dedo pula sem roubar joystick ou câmera")
	control_touch(world, 2, Vector2.ZERO, false)
	control_touch(world, 1, look_origin, false)
	control_touch(world, 0, origin, false)
	check(player.touch_axis == Vector2.ZERO and touch.look_id == -1, "Soltar os dedos encerra movimento e câmera")
	var badge_point: Vector2 = world.ui.ornament.regions.get_global_rect().get_center()
	control_touch(world, 3, badge_point, true)
	check(touch.look_id == -1, "Toque nos indicadores do HUD não inicia rotação da câmera")
	control_touch(world, 3, badge_point, false)
	control_touch(world, 0, origin, true)
	control_touch(world, 0, origin, true, true)
	check(touch.stick_id == -1 and player.touch_axis == Vector2.ZERO, "Cancelamento de toque libera o joystick")
	player.touch_axis = Vector2.ZERO
	player.camera_yaw = 0
	player.rotate_touch_camera(Vector2(100, 0), Vector2(390, 844))
	var portrait_yaw: float = player.camera_yaw
	player.camera_yaw = 0
	player.rotate_touch_camera(Vector2(100, 0), Vector2(844, 390))
	check(is_equal_approx(player.camera_yaw, portrait_yaw), "Sensibilidade de arrasto é consistente entre retrato e paisagem")
	player.avatar.rotation.y = -1.2
	player.center_camera()
	check(is_equal_approx(player.camera_yaw, -1.2) and is_equal_approx(player.camera_pitch, player.CAMERA_DEFAULT_PITCH), "Centralizar coloca a câmera atrás da orientação do personagem")
	world.toggle_map()
	player.center_camera()
	check(player.camera.current and not world.map_camera.current, "Centralizar retorna do mapa para a câmera em terceira pessoa")
	touch.reset()
	touch.active = original_touch
	platform.queue_free()
	player.position = world.ground(-30, 11, 0.05)
	player.velocity = Vector3(2, 0, 1)
	world.interact("lia")
	var lia: StaticBody3D = world.get_node("Lia")
	var toward_lia: Vector3 = (lia.global_position - player.global_position).normalized()
	check(not player.enabled and Vector2(player.velocity.x, player.velocity.z).is_zero_approx(), "Conversar com Lia interrompe o movimento sem impulso residual")
	check((-player.avatar.basis.z).dot(toward_lia) > 0.99, "Personagem se volta para Lia ao iniciar a conversa")
	check(lia.visual.basis.z.normalized().dot(-toward_lia) > 0.99, "Lia se volta para o personagem durante a interação")
	var npc_bounds: AABB = lia.visual.transform * lia.visual.mesh.get_aabb()
	check(Vector2(npc_bounds.get_center().x, npc_bounds.get_center().z).length() < 0.01, "Giro de Lia mantém a malha alinhada à colisão")
	world.ui.show_play()
	player.position = world.ground(-29, 26, 1)
	player.velocity = Vector3.ZERO
	await physics_frame
