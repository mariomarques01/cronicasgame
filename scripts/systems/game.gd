extends Node
signal changed
signal notice(message: String)
const SAVE_PATH = "user://eldervale_v1.json"
var quest: Dictionary = {}
var stone_definition: Dictionary = {}
var stage: int = 0
var inventory: Dictionary = {}
var collected: Array = []
var regions: Array = ["valley"]
var player_position: Vector3 = Vector3(0, 3, 12)
var capacity: int = 24
var last_error: String = ""

func _ready() -> void:
	quest = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests/forest_call.json"))
	stone_definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/ancient_stone.json"))
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "run": KEY_SHIFT, "jump": KEY_SPACE, "interact": KEY_E, "inventory": KEY_I, "pause": KEY_ESCAPE, "save": KEY_F5, "load": KEY_F9}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = keys[action]
			InputMap.action_add_event(action, event)

func reset() -> void:
	stage = 0
	inventory = {}
	collected = []
	regions = ["valley"]
	player_position = Vector3(0, 3, 12)
	changed.emit()

func objective() -> String:
	if stage == 4:
		return "Passagem aberta! Explore a Floresta dos Sussurros."
	if stage == 1:
		return "Encontre as pedras antigas: %d / 3" % collected.size()
	return str(quest.objectives[stage])

func talk() -> String:
	if stage == 0:
		stage = 1
		changed.emit()
		return "Lia • Guardiã do vale
Três pedras antigas repousam pelo vale. Procure seus brilhos azuis junto ao lago, ao celeiro e à colina. Traga-as e revelarei a passagem."
	if stage == 1:
		return "Lia
Siga os pilares de luz azul. Ainda faltam %d pedras." % (3 - collected.size())
	if stage == 2:
		stage = 3
		changed.emit()
		return "Lia
As três marcas estão reunidas! Ative o obelisco dourado junto ao portão. A floresta reconhecerá você."
	return "Lia
A Árvore Ancestral espera além da passagem. A magia voltou a respirar."

func collect(id: String) -> bool:
	if stage != 1 or not id in ["stone_0", "stone_1", "stone_2"] or id in collected or inventory.size() >= capacity:
		return false
	collected.append(id)
	inventory["ancient_stone"] = collected.size()
	if collected.size() == 3:
		stage = 2
	notice.emit("Pedra antiga encontrada • %d / 3" % collected.size())
	changed.emit()
	return true

func activate_gate() -> bool:
	if stage != 3:
		return false
	stage = 4
	if not "forest" in regions:
		regions.append("forest")
	notice.emit("REGIÃO DESBLOQUEADA • Floresta dos Sussurros")
	changed.emit()
	return true

func save_game(position: Vector3) -> bool:
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível gravar o salvamento."
		notice.emit(last_error)
		return false
	file.store_string(JSON.stringify({"version": 1, "stage": stage, "collected": collected, "inventory": inventory, "regions": regions, "position": [position.x, position.y, position.z]}))
	file.close()
	var error := DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	if error != OK:
		notice.emit("Falha ao substituir salvamento: %d" % error)
		return false
	notice.emit("Jogo salvo")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		notice.emit("Nenhum salvamento encontrado.")
		return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(SAVE_PATH)) != OK:
		notice.emit("Salvamento inválido; arquivo preservado.")
		return false
	var data: Variant = parser.data
	if not valid_save(data):
		notice.emit("Salvamento inválido ou incompatível; arquivo preservado.")
		return false
	stage = int(data.stage)
	collected = data.collected.duplicate()
	inventory = data.inventory.duplicate()
	regions = data.regions.duplicate()
	player_position = Vector3(data.position[0], data.position[1], data.position[2])
	changed.emit()
	return true

func valid_save(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1:
		return false
	if not data.get("stage") is float and not data.get("stage") is int:
		return false
	var s: int = int(data.stage)
	if s < 0 or s > 4 or float(s) != float(data.stage):
		return false
	if not data.get("collected") is Array or not data.get("inventory") is Dictionary or not data.get("regions") is Array or not data.get("position") is Array:
		return false
	var seen: Array = []
	for id: Variant in data.collected:
		if not id in ["stone_0", "stone_1", "stone_2"] or id in seen:
			return false
		seen.append(id)
	if (s >= 2 and seen.size() != 3) or (s == 0 and not seen.is_empty()) or (s == 1 and seen.size() == 3):
		return false
	if (seen.is_empty() and not data.inventory.is_empty()) or (not seen.is_empty() and (data.inventory.size() != 1 or data.inventory.get("ancient_stone") != seen.size())):
		return false
	if data.regions != (["valley", "forest"] if s == 4 else ["valley"]):
		return false
	if data.position.size() != 3:
		return false
	for value: Variant in data.position:
		if not (value is float or value is int) or not is_finite(float(value)) or abs(float(value)) > 512:
			return false
	return true
