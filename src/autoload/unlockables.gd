extends Node
## Port of obj_unlockables — skins/pets/icons unlocks (user://2.bson, XOR 69).

var palettes: Dictionary = {}    # key(int) -> {from, to, custom, name, character}
var petPallettes: Dictionary = {} # index -> {from, to}
var trades: Array = []           # Array[String]
var lobbyIcon := 0
var pet := -1

func _ready() -> void:
	for i in 7:
		petPallettes[i] = {"from": [], "to": []}
	# seed palettes from static data
	for key: int in Palletes.palettes:
		var list: Array = Palletes.palettes[key]
		if list.is_empty():
			continue
		palettes[key] = {
			"from": list[0]["from"], "to": list[0]["to"],
			"custom": false, "name": "default", "character": key,
		}
	if FileAccess.file_exists("user://2.bson"):
		load_data("user://2.bson")
	else:
		save()

func load_data(filename: String) -> void:
	var f := FileAccess.open(filename, FileAccess.READ)
	if f == null:
		return
	var bytes := f.get_buffer(f.get_length())
	var out := PackedByteArray()
	out.resize(bytes.size())
	for i in bytes.size():
		out[i] = bytes[i] ^ 69
	var json: Variant = JSON.parse_string(out.slice(0, _strlen(out)).get_string_from_utf8())
	if not (json is Dictionary):
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
			var v: Dictionary = pals[k]
			if v is Dictionary and v.has("from") and v.has("to"):
				palettes[ki] = {
					"from": v["from"], "to": v["to"],
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
			"from": p["from"], "to": p["to"],
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
	var json := JSON.stringify(data, "", false)
	var raw := json.to_utf8_buffer()
	var enc := PackedByteArray()
	enc.resize(raw.size())
	for i in raw.size():
		enc[i] = raw[i] ^ 69
	var f := FileAccess.open("user://2.bson", FileAccess.WRITE)
	if f:
		f.store_buffer(enc)
