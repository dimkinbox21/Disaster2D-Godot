extends Node
## Port of obj_achivements — binary save user://3.bin (GameMaker buffer format,
## byte-compatible with the original).

var mercoins := 0
var exeWins := 0
var survWins := 0
var exeKills := 0
var survStuns := 0
var tails := false
var knux := false
var eggman := false
var amy := false
var cream := false
var sally := false
var exe := false
var chaos := false
var exetior := false
var exeller := false
var achivements: Array = []
var prevAchivements: Array = []
var changed: Array = []
var maps: Array = []

# popup box state
var boxX := 0
var boxSide := false
var popup_ticks = 0
var autosave = true
var save_path = "user://3.bin"
var rules = preload("res://src/game/achievement_rules.gd").new(self)


func show_popup():
	boxSide = true
	popup_ticks = 240
	if is_instance_valid(get_node_or_null("/root/GameAudio")):
		GameAudio.play_sound("snd_achivement")


func _physics_process(_dt):
	if popup_ticks > 0:
		popup_ticks -= 1
	boxSide = popup_ticks > 0
	boxX = move_toward(boxX, 194 if boxSide else 0, 6)
	if is_instance_valid(get_node_or_null("/root/Net")):
		rules.tick()


func _ready() -> void:
	if SaveStore.startup_pending:
		await SaveStore.startup_completed
	for i in 50:
		achivements.append(false)
		prevAchivements.append(false)
	if not FileAccess.file_exists("user://3.bin"):
		_write_default()
	load_data("user://3.bin")
	var canvas = CanvasLayer.new()
	canvas.layer = 110
	add_child(canvas)
	canvas.add_child(load("res://src/menu/achievement_popup.gd").new())


func _write_default() -> void:
	var b := StreamPeerBuffer.new()
	b.big_endian = false
	b.put_u64(0)
	b.put_u32(0)
	b.put_u32(0)
	b.put_u32(0)
	b.put_u32(0)
	for i in 10:
		b.put_u8(0)
	b.put_u8(0)
	for i in 50:
		b.put_u8(0)
	b.put_u8(0)
	var f := FileAccess.open("user://3.bin", FileAccess.WRITE)
	if f:
		f.store_buffer(b.data_array)


func load_data(filename: String) -> bool:
	var data = SaveStore.stats_read(filename)
	if data.is_empty():
		data = SaveStore.stats_read(filename + ".bak")
		if data.is_empty():
			return false
	for key in [
		"mercoins",
		"survWins",
		"exeWins",
		"exeKills",
		"survStuns",
		"tails",
		"knux",
		"eggman",
		"amy",
		"cream",
		"sally",
		"exe",
		"chaos",
		"exetior",
		"exeller",
		"achivements",
		"changed",
		"maps"
	]:
		set(key, data[key])
	prevAchivements = achivements.duplicate()
	return true


func save() -> void:
	if not autosave:
		return
	for i in achivements.size():
		if prevAchivements[i] != achivements[i] and not changed.has(i):
			changed.append(i)
		prevAchivements[i] = achivements[i]
	var b := StreamPeerBuffer.new()
	b.big_endian = false
	b.put_u64(mercoins)
	b.put_u32(survWins)
	b.put_u32(exeWins)
	b.put_u32(exeKills)
	b.put_u32(survStuns)
	b.put_u8(1 if tails else 0)
	b.put_u8(1 if knux else 0)
	b.put_u8(1 if eggman else 0)
	b.put_u8(1 if amy else 0)
	b.put_u8(1 if cream else 0)
	b.put_u8(1 if sally else 0)
	b.put_u8(1 if exe else 0)
	b.put_u8(1 if chaos else 0)
	b.put_u8(1 if exetior else 0)
	b.put_u8(1 if exeller else 0)
	b.put_u8(changed.size())
	for c in changed:
		b.put_u8(c)
	for i in 50:
		b.put_u8(1 if achivements[i] else 0)
	b.put_u8(maps.size())
	for m in maps:
		var raw := str(m).to_utf8_buffer()
		for i in raw.size():
			b.put_u8(raw[i])
		b.put_u8(0)
	SaveStore.write_atomic(save_path, b.data_array)
