extends Node
signal changed
signal notice(message: String)
const SAVE_PATH = "user://eldervale_v1.json"
var quest: Dictionary = {}
var ruins_quest: Dictionary = {}
var ruins_definition: Dictionary = {}
var runes: Array = []
const RUNE_IDS := ["roots", "waters", "light"]
const JOURNEY_STEPS := 5
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
	ruins_definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/ancient_ruins.json"))
	ruins_quest = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests/ancient_ruins.json"))
	stone_definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/ancient_stone.json"))
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "run": KEY_SHIFT, "jump": KEY_SPACE, "interact": KEY_E, "inventory": KEY_I, "pause": KEY_ESCAPE, "save": KEY_F5, "load": KEY_F9, "camera_center": KEY_R}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = keys[action]
			InputMap.action_add_event(action, event)

func reset() -> void:
	stage = 0
	runes = []
	inventory = {}
	collected = []
	regions = ["valley"]
	player_position = Vector3(0, 3, 12)
	changed.emit()

func objective() -> String:
	match stage:
		0: return str(quest.objectives[0])
		1: return "Encontre as pedras antigas: %d / 3" % collected.size()
		5: return "Decifre as inscrições das ruínas: %d / 3" % runes.size()
		6: return "Siga a trilha até a Árvore Ancestral."
		7: return "Memórias reveladas! Explore o Vale da Fazenda."
		_: return "Encontre as Ruínas Antigas na floresta."

func completed_steps() -> int:
	return int({0:0, 1:1, 2:2, 3:2, 4:2, 5:3, 6:4, 7:5}.get(stage,0))

func ruins_journal() -> String:
	var lines: PackedStringArray = []
	for definition: Dictionary in ruins_definition.inscriptions:
		if definition.id in runes:
			lines.append(str(definition.name) + ": " + str(definition.text))
	return "\n\n".join(lines)

func active_quest_name() -> String:
	return str(ruins_quest.name if stage >= 4 else quest.name)

func enter_ruins() -> bool:
	if stage != 4: return false
	stage = 5
	notice.emit("Ruínas Antigas • Aproxime-se das inscrições para decifrá-las")
	changed.emit()
	return true

func read_inscription(id: String) -> bool:
	if stage != 5 or not id in RUNE_IDS or id in runes: return false
	runes.append(id)
	if runes.size() == RUNE_IDS.size():
		stage = 6
		notice.emit("Inscrições decifradas • Siga a trilha da Árvore Ancestral")
	else:
		notice.emit("Memória das ruínas revelada • %d / 3" % runes.size())
	changed.emit()
	return true

func reach_tree() -> bool:
	if stage != 6: return false
	stage = 7
	notice.emit("Árvore Ancestral alcançada • As memórias do vale foram reveladas")
	changed.emit()
	return true

func talk() -> String:
	if stage == 0:
		stage = 1
		changed.emit()
		return "Lia • Guardiã do vale\nTrês pedras antigas repousam perto do moinho, da oficina e da passagem norte. Reúna as três: a passagem da Floresta dos Sussurros se abrirá. Além da passagem, a trilha leva às Ruínas Antigas."
	return "Lia • Guardiã do vale\n" + objective()

func collect(id: String) -> bool:
	if stage != 1 or not id in ["stone_0", "stone_1", "stone_2"] or id in collected or inventory.size() >= capacity:
		return false
	collected.append(id)
	inventory["ancient_stone"] = collected.size()
	if collected.size() == 3:
		activate_gate()
	else:
		notice.emit("Pedra antiga encontrada • %d / 3" % collected.size())
		changed.emit()
	return true

func activate_gate() -> bool:
	if stage != 1 or collected.size() != 3:
		return false
	stage = 4
	if not "forest" in regions:
		regions.append("forest")
	notice.emit("Três pedras reunidas • Passagem da Floresta dos Sussurros aberta")
	changed.emit()
	return true

func save_game(position: Vector3, silent: bool = false) -> bool:
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível gravar o salvamento."
		notice.emit(last_error)
		return false
	file.store_string(JSON.stringify({"version": 2, "runes": runes, "stage": stage, "collected": collected, "inventory": inventory, "regions": regions, "position": [position.x, position.y, position.z]}))
	file.close()
	var error := DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	if error != OK:
		notice.emit("Falha ao substituir salvamento: %d" % error)
		return false
	if not silent:
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
	runes = data.get("runes", []).duplicate() if int(data.version) == 2 else []
	collected = data.collected.duplicate()
	inventory = data.inventory.duplicate()
	regions = data.regions.duplicate()
	# Legacy saves waited for a second conversation or for the mechanism.
	# The same three stones now unlock the forest immediately, before notifying UI.
	if stage in [2, 3]:
		stage = 4
		regions = ["valley", "forest"]
	player_position = Vector3(data.position[0], data.position[1], data.position[2])
	changed.emit()
	return true

func valid_save(data: Variant) -> bool:
	if not data is Dictionary or not (data.get("version") is int or data.get("version") is float):
		return false
	var version: int = int(data.version)
	if not version in [1,2] or float(version) != float(data.version):
		return false
	if not data.get("stage") is float and not data.get("stage") is int:
		return false
	var s: int = int(data.stage)
	if float(s) != float(data.stage) or (int(data.version) == 1 and (s < 0 or s > 4)) or (int(data.version) == 2 and not s in [0,1,4,5,6,7]):
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
	if data.regions != (["valley", "forest"] if s >= 4 else ["valley"]):
		return false
	if int(data.version) == 2:
		if not data.get("runes") is Array: return false
		var seen_runes: Array = []
		for id: Variant in data.runes:
			if not id in RUNE_IDS or id in seen_runes: return false
			seen_runes.append(id)
		if (s < 5 and not seen_runes.is_empty()) or (s == 5 and seen_runes.size() >= 3) or (s >= 6 and seen_runes.size() != 3): return false
	if data.position.size() != 3:
		return false
	for value: Variant in data.position:
		if not (value is float or value is int) or not is_finite(float(value)) or abs(float(value)) > 512:
			return false
	return true
