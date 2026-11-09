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
	world.start_game(false)
	await physics_frame
	check(world.get_node_or_null("GoldenAcres") != null, "Fazenda Golden Acres importada no cenário jogável")
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
	var rotation_tracks_only := true
	for track in jump.get_track_count():
		rotation_tracks_only = rotation_tracks_only and jump.track_get_type(track) == Animation.TYPE_ROTATION_3D
	check(rotation_tracks_only, "Animação não altera deslocamento nem proporções do personagem")
	var skeleton := world.player.avatar.model.find_child("Skeleton3D", true, false) as Skeleton3D
	var leg := skeleton.find_bone("mixamorig_LeftLeg")
	animator.advance(0.08)
	var first_pose := skeleton.get_bone_pose_rotation(leg)
	animator.advance(0.08)
	check(first_pose.angle_to(skeleton.get_bone_pose_rotation(leg)) > 0.01, "Animação de pulo move os ossos do coelho")
	var jump_time := animator.current_animation_position
	world.player.avatar.animate(0, true, true, false)
	check(is_equal_approx(animator.current_animation_position, jump_time), "Pulo não reinicia a cada frame no ar")
	world.player.avatar.animate(0, true, true, true)
	check(animator.current_animation == "Running", "Aterrissagem retoma corrida")
	world.player.avatar.animate(0, false, false)
	check(not world.player.avatar.animation_player.is_playing(), "Parado mantém pose estática")
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
	check(world.player.yaw.rotation.y != yaw_before, "Arrasto direito gira a câmera")
	look.pressed = false
	world.get_viewport().push_input(look, true)
	world.toggle_map()
	check(world.map_camera.current, "Mapa aéreo ativado")
	world.toggle_map()
	check(world.player.camera.current, "Retorno à câmera do personagem")
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
	if not previous.is_empty():
		file = FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
		file.store_string(previous)
		file.close()
	world.queue_free()
	await process_frame
	print("RESULTADO: %d falhas" % failures)
	quit(1 if failures else 0)
