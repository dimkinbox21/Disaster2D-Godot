extends Node
## Port of obj_unlockables — skins/pets/icons unlocks (user://2.bson, XOR 69).

var palettes: Dictionary = {}  # key(int) -> {from, to, custom, name, character}
var petPallettes: Dictionary = {}  # index -> {from, to}
var trades: Array = []  # Array[String]
var lobbyIcon := 0
var pet := -1
var save_path = "user://2.bson"
var custom_sources: Dictionary = {}


func actor_palette(character: int, exe_character: int, revivals: int) -> Dictionary:
	var key = (
		exe_character + Globals.PALETTE_EXE
		if character == 0
		else character + (Globals.PALETTE_DEMON if revivals >= 2 else 0)
	)
	var pal: Dictionary = palettes.get(key, {"from": [], "to": [], "name": "default"})
	return (
		{"from": [], "to": [], "name": "default"}
		if pal.get("name", "default") == "default"
		else pal
	)


func actor_texture(
	sprite: String,
	frame: int,
	character: int,
	exe_character: int,
	revivals: int,
	node: GMNode = null
) -> Texture2D:
	var pal = actor_palette(character, exe_character, revivals)
	return (
		VisualEffects.actor_texture(node, pal)
		if is_instance_valid(node)
		else GM.swapped_texture(sprite, frame, pal["from"], pal["to"])
	)


func apply_local_palette():
	if not is_instance_valid(Globals.player):
		return
	var pal = actor_palette(Globals.character, Globals.exeCharacter, Globals.player.revivalTimes)
	Globals.palleteName = pal.get("name", "default")
	Globals.palleteFrom = pal["from"]
	Globals.palleteTo = pal["to"]


func _ready() -> void:
	if SaveStore.startup_pending:
		await SaveStore.startup_completed
	custom_sources = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/gm/custom_palettes.json")
	)
	for i in 7:
		petPallettes[i] = {"from": [], "to": []}
	# seed palettes from static data
	for key: int in Palletes.palettes:
		var list: Array = Palletes.palettes[key]
		if list.is_empty():
			continue
		palettes[key] = {
			"from": [0, 0, 0, 0],
			"to": [0, 0, 0, 0],
			"custom": false,
			"name": "default",
			"character": key,
		}
	if FileAccess.file_exists("user://2.bson"):
		load_data("user://2.bson")
	else:
		save()


func load_data(filename: String) -> void:
	var json: Variant = SaveStore.json_read(filename)
	if not json is Dictionary:
		json = SaveStore.json_read(filename + ".bak")
	if not json is Dictionary:
		return
	lobbyIcon = int(json.get("lobbyIcon", 0))
	pet = int(json.get("pet", -1))
	trades = []
	var t: Variant = json.get("trades", [])
	if t is Array:
		for e in t:
			trades.append(str(e))
	var ppf: Variant = json.get("petPaletteFrom", [])
	var ppt: Variant = json.get("petPaletteTo", [])
	if ppf is Array and ppt is Array:
		for i in 7:
			if i < ppf.size() and ppf[i] is Array:
				petPallettes[i]["from"] = ppf[i]
			if i < ppt.size() and ppt[i] is Array:
				petPallettes[i]["to"] = ppt[i]
	var pals: Variant = json.get("palettes", {})
	if pals is Dictionary:
		for k: String in pals:
			var ki := int(k)
			var v: Variant = pals[k]
			if palettes.has(ki) and SaveStore.valid_palette(v):
				palettes[ki] = {
					"from": v["from"],
					"to": v["to"],
					"custom": bool(v.get("custom", false)),
					"name": str(v.get("name", "default")),
					"character": int(v.get("character", ki)),
				}


static func _strlen(b: PackedByteArray) -> int:
	for i in b.size():
		if b[i] == 0:
			return i
	return b.size()


func save() -> void:
	var pals_out := {}
	for k: int in palettes:
		var p: Dictionary = palettes[k]
		pals_out[str(k)] = {
			"from": p["from"],
			"to": p["to"],
			"custom": p.get("custom", false),
			"name": p.get("name", "default"),
			"character": p.get("character", k),
		}
	var ppf := []
	var ppt := []
	for i in 7:
		ppf.append(petPallettes[i]["from"])
		ppt.append(petPallettes[i]["to"])
	var data := {
		"lobbyIcon": lobbyIcon,
		"pet": pet,
		"petPaletteFrom": ppf,
		"petPaletteTo": ppt,
		"palettes": pals_out,
		"trades": trades,
	}
	SaveStore.json_write(save_path, data)
