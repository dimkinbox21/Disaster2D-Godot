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

func _ready() -> void:
	for i in 50:
		achivements.append(false)
		prevAchivements.append(false)
	if not FileAccess.file_exists("user://3.bin"):
		_write_default()
	load_data("user://3.bin")

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

func load_data(filename: String) -> void:
	var f := FileAccess.open(filename, FileAccess.READ)
	if f == null:
		return
	var b := StreamPeerBuffer.new()
	b.data_array = f.get_buffer(f.get_length())
	b.big_endian = false
	b.seek(0)
	mercoins = int(b.get_u64())
	survWins = b.get_u32()
	exeWins = b.get_u32()
	survStuns = b.get_u32()
	exeKills = b.get_u32()
	tails = b.get_u8() != 0
	knux = b.get_u8() != 0
	eggman = b.get_u8() != 0
	amy = b.get_u8() != 0
	cream = b.get_u8() != 0
	sally = b.get_u8() != 0
	exe = b.get_u8() != 0
	chaos = b.get_u8() != 0
	exetior = b.get_u8() != 0
	exeller = b.get_u8() != 0
	achivements = []
	prevAchivements = []
	changed = []
	var changedCount := b.get_u8()
	for i in changedCount:
		changed.append(b.get_u8())
	for i in 50:
		achivements.append(b.get_u8() != 0)
		prevAchivements.append(achivements[i])
	var mapCount := b.get_u8()
	maps = []
	for i in mapCount:
		var ln := b.get_u16()  # GM buffer_string is null-terminated; u16 read keeps stream aligned below
		var s := ""
		var ch := b.get_u8()
		while ch != 0:
			s += char(ch)
			ch = b.get_u8()
		maps.append(s)

func save() -> void:
	for i in achivements.size():
		if prevAchivements[i] != achivements[i]:
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
	var f := FileAccess.open("user://3.bin", FileAccess.WRITE)
	if f:
		f.store_buffer(b.data_array)
