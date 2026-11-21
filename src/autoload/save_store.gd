extends Node
## Original GameMaker files, copied into the port once; originals are read-only.
const FILES = ["1.bson", "2.bson", "3.bin"]
var import_error = ""
var imported_from = ""
var destination = "user://"
var startup_pending := false
signal startup_completed


func _ready():
	if OS.has_feature("editor") and "--script" in OS.get_cmdline_args():
		return
	prepare_startup()


func prepare_startup() -> void:
	var source = OS.get_environment("DISASTER_ORIGINAL_SAVE")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--import-original-save="):
			source = arg.trim_prefix("--import-original-save=")
	if source != "":
		import_original(source)
		return
	if FileAccess.file_exists(destination.path_join("first-launch.json")):
		return
	if FileAccess.file_exists(destination.path_join("original-save-import.json")):
		return
	for name in FILES:
		if FileAccess.file_exists(destination.path_join(name)):
			return
	begin_first_launch()


func begin_first_launch() -> void:
	startup_pending = true
	_show_first_launch.call_deferred()


func _show_first_launch() -> void:
	var prompt = load("res://src/menu/first_run_import.gd").new()
	add_child(prompt)


func original_save_folder() -> String:
	return OS.get_environment("LOCALAPPDATA").path_join("Sonicexe_The_Disaster_2D_Remake")


func finish_first_launch(choice: String) -> bool:
	var marker = FileAccess.open(destination.path_join("first-launch.json"), FileAccess.WRITE)
	if marker == null:
		import_error = "Could not save your first-launch choice."
		return false
	marker.store_string(JSON.stringify({"choice": choice, "version": 1}))
	marker.close()
	startup_pending = false
	startup_completed.emit()
	return true


func json_read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var bytes = FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	for i in bytes.size():
		bytes[i] = bytes[i] ^ 69
	var end = bytes.find(0)
	if end >= 0:
		bytes = bytes.slice(0, end)
	return JSON.parse_string(bytes.get_string_from_utf8())


func json_write(path: String, data: Dictionary) -> bool:
	var bytes = JSON.stringify(data, "", false).to_utf8_buffer()
	bytes.append(0)
	for i in bytes.size():
		bytes[i] = bytes[i] ^ 69
	return write_atomic(path, bytes)


func write_atomic(path: String, bytes: PackedByteArray) -> bool:
	var f = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.flush()
	var err = f.get_error()
	f.close()
	if err != OK:
		return false
	if FileAccess.file_exists(path) and DirAccess.copy_absolute(path, path + ".bak") != OK:
		return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK


func stats_read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var bytes = FileAccess.get_file_as_bytes(path)
	if bytes.size() < 86:
		return {}
	var b = StreamPeerBuffer.new()
	b.data_array = bytes
	var d = {
		"mercoins": b.get_u64(),
		"survWins": b.get_u32(),
		"exeWins": b.get_u32(),
		"exeKills": b.get_u32(),
		"survStuns": b.get_u32()
	}
	for key in [
		"tails", "knux", "eggman", "amy", "cream", "sally", "exe", "chaos", "exetior", "exeller"
	]:
		d[key] = b.get_u8() != 0
	var count = b.get_u8()
	if b.get_available_bytes() < count + 51:
		return {}
	d.changed = []
	for i in count:
		var id = b.get_u8()
		if id >= 50:
			return {}
		if not d.changed.has(id):
			d.changed.append(id)
	d.achivements = []
	for i in 50:
		d.achivements.append(b.get_u8() != 0)
	count = b.get_u8()
	d.maps = []
	for i in count:
		var start = b.get_position()
		var end = bytes.find(0, start)
		if end < 0:
			return {}
		d.maps.append(bytes.slice(start, end).get_string_from_utf8())
		b.seek(end + 1)
	return d


func valid_file(path: String, name: String) -> bool:
	if name == "3.bin":
		return not stats_read(path).is_empty()
	var data = json_read(path)
	if not data is Dictionary:
		return false
	if name == "1.bson":
		return data.get("nickname") is String
	if not data.get("palettes") is Dictionary or not data.get("trades") is Array:
		return false
	for palette in data.palettes.values():
		if not valid_palette(palette):
			return false
	return true


func valid_palette(palette: Variant) -> bool:
	if (
		not palette is Dictionary
		or not palette.get("from") is Array
		or not palette.get("to") is Array
	):
		return false
	if (
		palette["from"].size() != palette["to"].size()
		or palette["from"].size() % 4 != 0
		or palette["from"].size() > 252
	):
		return false
	for value in palette["from"] + palette["to"]:
		if (
			typeof(value) not in [TYPE_INT, TYPE_FLOAT]
			or not is_finite(float(value))
			or float(value) < 0
			or float(value) > 1
		):
			return false
	return true


func import_original(folder: String) -> bool:
	folder = folder.strip_edges().trim_prefix('"').trim_suffix('"')
	import_error = ""
	var staged = {}
	for name in FILES:
		var path = folder.path_join(name)
		if not valid_file(path, name):
			path += ".bak"
			if not valid_file(path, name):
				import_error = "Invalid original save: " + name
				return false
		staged[name] = FileAccess.get_file_as_bytes(path)
	var backup = destination.path_join(
		"before-original-import-" + str(Time.get_unix_time_from_system()).replace(".", "-")
	)
	if DirAccess.make_dir_recursive_absolute(backup) != OK:
		return false
	for name in FILES:
		if FileAccess.file_exists(destination.path_join(name)):
			if DirAccess.copy_absolute(destination.path_join(name), backup.path_join(name)) != OK:
				return false
	for name in FILES:
		if not write_atomic(destination.path_join(name), staged[name]):
			import_error = "Cannot write " + name
			return false
	var f = FileAccess.open(destination.path_join("original-save-import.json"), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"source": folder, "backup": backup, "version": 1}))
	f.close()
	imported_from = folder
	return true
