extends Node
## Port of obj_config — settings, save/load (user://1.bson, XOR 69, compatible
## with the original GameMaker save), resolution modes.

var save_path := "user://1.bson"
var screenMode := 0
var nickname := "player"
var ip := "localhost"
var showFps := false
var showPing := true

# touch button layout (kept for parity)
var dpadX := 68
var dpadY := 187
var jScale := 1.0
var jOpacity := 0.6

var bAX := 378
var bAY := 221
var bAScale := 1.0
var bAOpacity := 0.6

var bBX := 416
var bBY := 177
var bBScale := 1.0
var bBOpacity := 0.6

var bCX := 452
var bCY := 221
var bCScale := 1.0
var bCOpacity := 0.6

var bDX := 466
var bDY := 48
var bDScale := 1.0
var bDOpacity := 0.6

var bEX := 466
var bEY := 80
var bEScale := 1.0
var bEOpacity := 0.6

var bFX := 466
var bFY := 112
var bFScale := 1.0
var bFOpacity := 0.6

var bGX := 23
var bGY := 51
var bGScale := 1.0
var bGOpacity := 0.6

var bWX := 466
var bWY := 144
var bWScale := 1.0
var bWOpacity := 0.6

var _buffer: Dictionary = {}


func _ready() -> void:
	if SaveStore.startup_pending:
		await SaveStore.startup_completed
	_buffer = _defaults()
	_apply_buffer()
	if not FileAccess.file_exists("user://1.bson"):
		save()
	else:
		load_cfg("user://1.bson")
	if not Globals.configInit:
		Globals.configInit = true
		apply_res()


func _defaults() -> Dictionary:
	return {
		"screenMode": 0,
		"nickname": "\\player /%d" % (randi() % 10000),
		"ip": "localhost",
		"showFps": false,
		"showPing": true,
		"left": GM.VK_LEFT,
		"right": GM.VK_RIGHT,
		"up": GM.VK_UP,
		"down": GM.VK_DOWN,
		"a": 90,
		"b": 88,
		"c": 67,
		"em1": 65,
		"em2": 83,
		"em3": 68,
		"hide": GM.VK_LCONTROL,
		"plist": GM.VK_TAB,
		"idle": 87,
		"gampadTouch": {"xx": 68, "yy": 187, "scale": 1, "opacity": 0.6},
		"zTouch": {"xx": 378, "yy": 221, "scale": 1, "opacity": 0.6},
		"xTouch": {"xx": 416, "yy": 177, "scale": 1, "opacity": 0.6},
		"cTouch": {"xx": 452, "yy": 221, "scale": 1, "opacity": 0.6},
		"aTouch": {"xx": 466, "yy": 48, "scale": 1, "opacity": 0.6},
		"sTouch": {"xx": 466, "yy": 80, "scale": 1, "opacity": 0.6},
		"dTouch": {"xx": 466, "yy": 112, "scale": 1, "opacity": 0.6},
		"wTouch": {"xx": 466, "yy": 144, "scale": 1, "opacity": 0.6},
		"gTouch": {"xx": 23, "yy": 81, "scale": 1, "opacity": 0.6},
	}


func _apply_buffer() -> void:
	var b := _buffer
	screenMode = b["screenMode"]
	nickname = _gm_string_copy(b["nickname"], 0, 15)
	ip = b["ip"]
	showFps = b["showFps"]
	showPing = b["showPing"]
	Globals.KeyLeft = b["left"]
	Globals.KeyRight = b["right"]
	Globals.KeyUp = b["up"]
	Globals.KeyDown = b["down"]
	Globals.KeyA = b["a"]
	Globals.KeyB = b["b"]
	Globals.KeyC = b["c"]
	Globals.KeyEm1 = b["em1"]
	Globals.KeyEm2 = b["em2"]
	Globals.KeyEm3 = b["em3"]
	Globals.KeyHide = b["hide"]
	Globals.KeyPList = b["plist"]
	Globals.KeyIdle = b.get("idle", 87)
	dpadX = b["gampadTouch"]["xx"]
	dpadY = b["gampadTouch"]["yy"]
	jScale = b["gampadTouch"]["scale"]
	jOpacity = b["gampadTouch"]["opacity"]
	bAX = b["zTouch"]["xx"]
	bAY = b["zTouch"]["yy"]
	bAScale = b["zTouch"]["scale"]
	bAOpacity = b["zTouch"]["opacity"]
	bBX = b["xTouch"]["xx"]
	bBY = b["xTouch"]["yy"]
	bBScale = b["xTouch"]["scale"]
	bBOpacity = b["xTouch"]["opacity"]
	bCX = b["cTouch"]["xx"]
	bCY = b["cTouch"]["yy"]
	bCScale = b["cTouch"]["scale"]
	bCOpacity = b["cTouch"]["opacity"]
	bDX = b["aTouch"]["xx"]
	bDY = b["aTouch"]["yy"]
	bDScale = b["aTouch"]["scale"]
	bDOpacity = b["aTouch"]["opacity"]
	bEX = b["sTouch"]["xx"]
	bEY = b["sTouch"]["yy"]
	bEScale = b["sTouch"]["scale"]
	bEOpacity = b["sTouch"]["opacity"]
	bFX = b["dTouch"]["xx"]
	bFY = b["dTouch"]["yy"]
	bFScale = b["dTouch"]["scale"]
	bFOpacity = b["dTouch"]["opacity"]
	bGX = b["gTouch"]["xx"]
	bGY = b["gTouch"]["yy"]
	bGScale = b["gTouch"]["scale"]
	bGOpacity = b["gTouch"]["opacity"]
	bWX = b["wTouch"]["xx"]
	bWY = b["wTouch"]["yy"]
	bWScale = b["wTouch"]["scale"]
	bWOpacity = b["wTouch"]["opacity"]
	Globals.nickname = validate_nickname(nickname)


static func _gm_string_copy(s: String, start: int, count: int) -> String:
	# GML string_copy(str, 1-based start, count)
	if start <= 0:
		start = 1
	if count < 0:
		count = 0
	return s.substr(start - 1, count)


func load_cfg(filename: String) -> void:
	var json: Variant = SaveStore.json_read(filename)
	if not json is Dictionary:
		json = SaveStore.json_read(filename + ".bak")
	if json is Dictionary:
		_buffer = _defaults().merged(json, true)
		_apply_buffer()


static func _strlen(b: PackedByteArray) -> int:
	# find first NUL
	for i in b.size():
		if b[i] == 0:
			return i
	return b.size()


func save() -> void:
	var b := _buffer
	b["screenMode"] = screenMode
	b["nickname"] = _gm_string_copy(Globals.nickname, 0, 15)
	b["ip"] = ip
	b["showFps"] = showFps
	b["showPing"] = showPing
	b["left"] = Globals.KeyLeft
	b["right"] = Globals.KeyRight
	b["up"] = Globals.KeyUp
	b["down"] = Globals.KeyDown
	b["a"] = Globals.KeyA
	b["b"] = Globals.KeyB
	b["c"] = Globals.KeyC
	b["em1"] = Globals.KeyEm1
	b["em2"] = Globals.KeyEm2
	b["em3"] = Globals.KeyEm3
	b["hide"] = Globals.KeyHide
	b["plist"] = Globals.KeyPList
	b["idle"] = Globals.KeyIdle
	b["gampadTouch"] = {"xx": dpadX, "yy": dpadY, "scale": jScale, "opacity": jOpacity}
	b["zTouch"] = {"xx": bAX, "yy": bAY, "scale": bAScale, "opacity": bAOpacity}
	b["xTouch"] = {"xx": bBX, "yy": bBY, "scale": bBScale, "opacity": bBOpacity}
	b["cTouch"] = {"xx": bCX, "yy": bCY, "scale": bCScale, "opacity": bCOpacity}
	b["aTouch"] = {"xx": bDX, "yy": bDY, "scale": bDScale, "opacity": bDOpacity}
	b["sTouch"] = {"xx": bEX, "yy": bEY, "scale": bEScale, "opacity": bEOpacity}
	b["dTouch"] = {"xx": bFX, "yy": bFY, "scale": bFScale, "opacity": bFOpacity}
	b["gTouch"] = {"xx": bGX, "yy": bGY, "scale": bGScale, "opacity": bGOpacity}
	b["wTouch"] = {"xx": bWX, "yy": bWY, "scale": bWScale, "opacity": bWOpacity}

	SaveStore.json_write(save_path, b)


func apply_res() -> void:
	match screenMode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_set_window_size(480, 270)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_set_window_size(960, 540)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_set_window_size(1440, 810)
		3:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _set_window_size(w: int, h: int) -> void:
	DisplayServer.window_set_size(Vector2i(w, h))
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var screen_pos := DisplayServer.screen_get_position(screen)
	DisplayServer.window_set_position(screen_pos + (screen_size - Vector2i(w, h)) / 2)


func validate_nickname(s: String) -> String:
	var s2 := s
	for p in ["\\", "/", "@", "|", "№", "`", "~", "&", " "]:
		s2 = s2.replace(p, "")
	if s2.length() <= 0:
		return "/player~ \\%d" % (randi() % 10000)
	return s


func _touch_prefix(button: int) -> String:
	return (
		"j"
		if button == 0
		else "b" + ["", "A", "B", "C", "D", "E", "F", "G", "W"][clampi(button, 1, 8)]
	)


func buttonSetProp(button: int, size: float, opacity: float):
	var prefix = _touch_prefix(button)
	if float(get(prefix + "Scale")) == size and float(get(prefix + "Opacity")) == opacity:
		return
	set(prefix + "Scale", size)
	set(prefix + "Opacity", opacity)
	save()


func buttonSetPos(button: int, xx: float, yy: float):
	var prefix = "dpad" if button == 0 else _touch_prefix(button)
	if float(get(prefix + "X")) == xx and float(get(prefix + "Y")) == yy:
		return
	set(prefix + "X", int(xx))
	set(prefix + "Y", int(yy))
	save()
