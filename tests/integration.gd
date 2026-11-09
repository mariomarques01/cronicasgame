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
	check(world.get_node_or_null("GoldenAcres") != null, "Fazenda Golden Acres importada no cenário jogável")
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
	check(not entry_floor.is_empty() and entry_floor.collider.name == "SouthEntranceGround" and absf(entry_floor.position.y - 0.01) < 0.02, "Buraco do arco antigo coberto por caminho com colisão nivelada")
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
	world.player.position = Vector3(0, 5, 12)
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
	world.player.touch_axis = Vector2(0, -1)
	world.player.touch_running = false
	for i in range(220):
		await physics_frame
	world.player.touch_axis = Vector2.ZERO
	check(world.player.position.z < 36 and world.player.is_on_floor(), "Personagem atravessa entrada sul caminhando sem salto ou parede invisível")
	if not previous.is_empty():
		file = FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
		file.store_string(previous)
		file.close()
	world.queue_free()
	await process_frame
	print("RESULTADO: %d falhas" % failures)
	quit(1 if failures else 0)
