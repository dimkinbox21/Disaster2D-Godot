extends Node
## GM — GameMaker runtime emulation: sprites, keys, keyboard_string, text renderer.
## Autoloaded as `GM`.

# ------------------------------------------------------------------ colors
const C_AQUA := Color("00ffff")
const C_BLACK := Color("000000")
const C_BLUE := Color("0000ff")
const C_DKGRAY := Color("404040")
const C_GRAY := Color("808080")
const C_GREEN := Color("008000")
const C_LIME := Color("00ff00")
const C_LTGRAY := Color("c0c0c0")
const C_MAROON := Color("800000")
const C_NAVY := Color("000080")
const C_OLIVE := Color("808000")
const C_PURPLE := Color("800080")
const C_RED := Color("ff0000")
const C_SILVER := Color("c0c0c0")
const C_TEAL := Color("008080")
const C_WHITE := Color("ffffff")
const C_YELLOW := Color("ffff00")
const C_ORANGE := Color("ffa500")

# ------------------------------------------------------------------ vk constants (GameMaker values)
const VK_ANYKEY := 1
const VK_ENTER := 13
const VK_TAB := 9
const VK_BACKSPACE := 8
const VK_SPACE := 32
const VK_ESCAPE := 27
const VK_LEFT := 37
const VK_UP := 38
const VK_RIGHT := 39
const VK_DOWN := 40
const VK_SHIFT := 16
const VK_CONTROL := 17
const VK_ALT := 18
const VK_LCONTROL := 156
const VK_LSHIFT := 160
const VK_LALT := 162

const _GM_TO_GODOT := {
	VK_ENTER: KEY_ENTER,
	VK_TAB: KEY_TAB,
	VK_BACKSPACE: KEY_BACKSPACE,
	VK_SPACE: KEY_SPACE,
	VK_ESCAPE: KEY_ESCAPE,
	VK_LEFT: KEY_LEFT,
	VK_UP: KEY_UP,
	VK_RIGHT: KEY_RIGHT,
	VK_DOWN: KEY_DOWN,
	VK_SHIFT: KEY_SHIFT,
	VK_CONTROL: KEY_CTRL,
	VK_ALT: KEY_ALT,
	VK_LCONTROL: KEY_CTRL,
	VK_LSHIFT: KEY_SHIFT,
	VK_LALT: KEY_ALT,
}

const _GODOT_TO_GM := {
	KEY_ENTER: VK_ENTER,
	KEY_TAB: VK_TAB,
	KEY_BACKSPACE: VK_BACKSPACE,
	KEY_KP_ENTER: VK_ENTER,
	KEY_SPACE: VK_SPACE,
	KEY_ESCAPE: VK_ESCAPE,
	KEY_LEFT: VK_LEFT,
	KEY_UP: VK_UP,
	KEY_RIGHT: VK_RIGHT,
	KEY_DOWN: VK_DOWN,
	KEY_SHIFT: VK_LSHIFT,
	KEY_CTRL: VK_LCONTROL,
	KEY_ALT: VK_LALT,
}

# ------------------------------------------------------------------ state
var sprites: Dictionary = {}  # name -> {"textures": Array[Texture2D], "meta": {...}}
var keyboard_string := ""
var keyboard_lastkey: int = -1  # GM vk of last pressed key
var _pressed_this_frame: Dictionary = {}
var _released_this_frame: Dictionary = {}
var _down_keys: Dictionary = {}
var _down_mouse: Dictionary = {}
var mouse_x := 0.0
var mouse_y := 0.0

var BUILD_VER := 1131


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# run after all game nodes so per-frame flags clear at frame end
	process_physics_priority = 1000
	_load_sprites()


func _load_sprites() -> void:
	var path := "res://assets/gm/sprites.json"
	if not FileAccess.file_exists(path):
		push_error("sprites.json missing")
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for name: String in data:
		var m: Dictionary = data[name]
		var texs: Array[Texture2D] = []
		for f: String in m["frames"]:
			# chunk pseudo-sprites carry a path relative to assets/sprites/
			var t: Texture2D = (
				load("res://assets/sprites/%s" % f)
				if f.contains("/")
				else load("res://assets/sprites/%s/%s" % [name, f])
			)
			if t:
				texs.append(t)
		sprites[name] = {"textures": texs, "meta": m}


func sprite_meta(name: String) -> Dictionary:
	if sprites.has(name):
		return sprites[name]["meta"]
	push_error("unknown sprite: " + name)
	return {"w": 1, "h": 1, "xorigin": 0, "yorigin": 0, "frames": []}


func sprite_frames(name: String) -> Array[Texture2D]:
	if sprites.has(name):
		return sprites[name]["textures"]
	return [] as Array[Texture2D]


func sprite_count(name: String) -> int:
	return sprite_frames(name).size()


func sprite_texture(name: String, index: int) -> Texture2D:
	var fr := sprite_frames(name)
	if fr.is_empty():
		return null
	while index < 0:
		index += fr.size()
	return fr[index % fr.size()]


# ------------------------------------------------------------------ input
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		var gmvk := _godot_key_to_gm(k.keycode)
		if k.pressed:
			if not k.echo:
				keyboard_lastkey = gmvk
				_pressed_this_frame[gmvk] = true
			_down_keys[gmvk] = true
			# keyboard_string emulation (printable chars + backspace)
			var uni: int = k.unicode
			if k.keycode == KEY_BACKSPACE:
				if keyboard_string.length() > 0:
					keyboard_string = keyboard_string.substr(0, keyboard_string.length() - 1)
			elif uni >= 32 and uni != 127:
				keyboard_string += char(uni)
		else:
			_released_this_frame[gmvk] = true
			_down_keys.erase(gmvk)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if (
			mb.button_index
			in [
				MOUSE_BUTTON_WHEEL_UP,
				MOUSE_BUTTON_WHEEL_DOWN,
				MOUSE_BUTTON_WHEEL_LEFT,
				MOUSE_BUTTON_WHEEL_RIGHT
			]
		):
			return
		var idx := (
			0
			if mb.button_index == MOUSE_BUTTON_LEFT
			else (1 if mb.button_index == MOUSE_BUTTON_RIGHT else 2)
		)
		if mb.pressed:
			_pressed_this_frame[1000 + idx] = true
			_pressed_this_frame[1002] = true
			_down_mouse[idx] = true
			_down_mouse[2] = true
		else:
			_released_this_frame[1000 + idx] = true
			_released_this_frame[1002] = true
			_down_mouse.erase(idx)
			_down_mouse.erase(2)


func _physics_process(_delta: float) -> void:
	# runs LAST (process_physics_priority = 1000): clear per-frame flags after all steps
	_pressed_this_frame.clear()
	_released_this_frame.clear()
	var mp := get_viewport().get_mouse_position()
	# stretch: viewport coords already match room coords (viewport stretch mode)
	mouse_x = mp.x
	mouse_y = mp.y


func _godot_key_to_gm(code: int) -> int:
	if _GODOT_TO_GM.has(code):
		return _GODOT_TO_GM[code]
	return code  # ASCII letters/digits match GM ord() values


func key_pressed(gmvk: int) -> bool:
	if gmvk == VK_ANYKEY:
		for key in _pressed_this_frame:
			if key not in [1000, 1001, 1002]:
				return true
		return false
	return _pressed_this_frame.has(gmvk)


func key_released(gmvk: int) -> bool:
	if gmvk == VK_ANYKEY:
		for key in _released_this_frame:
			if key not in [1000, 1001, 1002]:
				return true
		return false
	return _released_this_frame.has(gmvk)


func key_down(gmvk: int) -> bool:
	if gmvk == VK_ANYKEY:
		return not _down_keys.is_empty()
	return _down_keys.has(gmvk)


func mouse_pressed(button: int = 0) -> bool:  # 0=left 1=right 2=any
	return _pressed_this_frame.has(1000 + button)


func mouse_down(button: int = 0) -> bool:
	return _down_mouse.has(button)


func mouse_released(button: int = 0) -> bool:
	return _released_this_frame.has(1000 + button)


# ------------------------------------------------------------------ text renderer (scr_text_spr port)
const LETTER_SPR := "spr_letter1"
const _WIDE_CHARS := ["w", "m", "x", "n", "м", "д", "и", "й", "ю", "ь", "л", "ш", "щ", "ц", "ж"]


static func _letter_index(c: String) -> int:
	var ordv := c.unicode_at(0)
	if ordv >= 0x0430 and ordv <= 0x044F:
		return 45 + (ordv - 0x0430)
	if c >= "a" and c <= "z":
		return ordv - 97
	match c:
		"-":
			return 26
		",":
			return 27
		"1":
			return 28
		"2":
			return 29
		"3":
			return 30
		"4":
			return 31
		"5":
			return 32
		"6":
			return 33
		"7":
			return 34
		"8":
			return 35
		"9":
			return 36
		"0":
			return 37
		".":
			return 38
		"'":
			return 39
		":":
			return 40
		"(":
			return 41
		")":
			return 42
		"%":
			return 43
		"+":
			return 77
	return 44


static func _color_code(c: String, base: Color) -> Color:
	match c:
		"\\":
			return Color("c20037")
		"@":
			return Color("0fff39")
		"&":
			return Color("b824ff")
		"/":
			return Color("5d67ff")
		"|":
			return Color("646464")
		"`":
			return Color("ffdb00")
		"№":
			return Color("ea6014")
		"~":
			return base
	return base


## Team-coloured names must ignore the nickname's saved chat/lobby markup.
static func plain_text(value: String) -> String:
	for code in ["\\", "@", "&", "/", "|", "`", "№", "~"]:
		value = value.replace(code, "")
	return value


## Draws styled text using the letter sprite font. Returns text width in px.
static func scr_text_spr(
	ci: CanvasItem, xx: float, yy: float, str_: String, color: Color = C_WHITE, alpha: float = 1.0
) -> float:
	var max_width := 0.0
	var x := xx
	var y := yy
	var col := color
	var base_col := color
	var letter_origin: Vector2 = Vector2(0, 0)
	if GM.sprites.has(LETTER_SPR):
		var m: Dictionary = GM.sprites[LETTER_SPR]["meta"]
		letter_origin = Vector2(m["xorigin"], m["yorigin"])
	for i in str_.length():
		var c := str_[i]
		if c == "\n":
			x = xx
			y += 8
			continue
		if c == " ":
			x += 5
			continue
		if ["\\", "@", "&", "/", "|", "`", "№", "~"].has(c):
			col = _color_code(c, base_col)
			continue
		var ind := _letter_index(c)
		var tex := GM.sprite_texture(LETTER_SPR, ind)
		if tex:
			# GML draw coords are room coords; draw_texture expects local coords
			var pos: Vector2 = ci.to_local(Vector2(x, y)) - letter_origin
			ci.draw_texture(tex, pos, Color(col, alpha))
		x += 6
		if _WIDE_CHARS.has(c):
			x += 2
		if x - xx >= max_width:
			max_width = x - xx
	return max_width


## scr_text_spr's width return without drawing (the original calls
## scr_text_spr(0, 0, txt) just for the value — e.g. nicknameWidth)
static func scr_text_spr_width(str_: String) -> float:
	var x := 0.0
	var max_width := 0.0
	for i in str_.length():
		var c := str_[i]
		if c == "\n":
			x = 0.0
			continue
		if c == " ":
			x += 5
			continue
		if ["\\", "@", "&", "/", "|", "`", "№", "~"].has(c):
			continue
		x += 6
		if _WIDE_CHARS.has(c):
			x += 2
		if x >= max_width:
			max_width = x
	return max_width


## scr_number_spr port (spr_number digits, 5px apart)
static func scr_number_spr(
	ci: CanvasItem, xx: float, yy: float, str_: String, color: Color = C_WHITE, alpha: float = 1.0
) -> void:
	var x := xx
	var col := color
	for i in str_.length():
		var c := str_[i]
		if c >= "0" and c <= "9":
			var ind := int(c.unicode_at(0) - 48)
			var tex := GM.sprite_texture("spr_number", ind)
			if tex:
				ci.draw_texture(
					tex, ci.to_local(Vector2(x - (str_.length() - 1) * 2, yy)), Color(col, alpha)
				)
		x += 5


## scr_counter_draw_s port (spr_counter, 11px apart)
static func scr_counter_draw_s(ci: CanvasItem, number: int, xx: float, yy: float) -> void:
	var s := str(number)
	for i in s.length():
		var num := int(s[i])
		var tex := GM.sprite_texture("spr_counter", num)
		if tex:
			ci.draw_texture(tex, ci.to_local(Vector2(xx + 11 * i, yy)))


# ------------------------------------------------------------------ CPU palette swap (shd_colour port)
static var _swap_cache: Dictionary = {}


func _exit_tree() -> void:
	# Godot's Dummy renderer can crash when ImageTextures are released during
	# autoload teardown. Interactive clients release the GPU cache normally.
	if DisplayServer.get_name() != "headless":
		_swap_cache.clear()


## Exact port of the GM palette-swap: replaces matched colors on a copy of the
## frame texture and caches the result. Avoids shader colorspace pitfalls.
static func swapped_texture(spr: String, frame: int, from: Array, to: Array) -> Texture2D:
	if from.is_empty() or from == to or from.size() != to.size() or from.size() % 4 != 0:
		return GM.sprite_texture(spr, frame)
	var frames = GM.sprite_count(spr)
	if frames > 0:
		frame = posmod(frame, frames)
	var key := "%s#%d#%d#%d" % [spr, frame, from.hash(), to.hash()]
	if _swap_cache.has(key):
		return _swap_cache[key]
	var base := GM.sprite_texture(spr, frame)
	if base == null:
		return null
	var img: Image = base.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var count := int(from.size() / 4.0)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			for i in count:
				var j := i * 4
				if (
					absf(c.r - float(from[j])) < 0.01
					and absf(c.g - float(from[j + 1])) < 0.01
					and absf(c.b - float(from[j + 2])) < 0.01
					and absf(c.a - float(from[j + 3])) < 0.01
				):
					img.set_pixel(
						x,
						y,
						Color(float(to[j]), float(to[j + 1]), float(to[j + 2]), float(to[j + 3]))
					)
					break
	var tex := ImageTexture.create_from_image(img)
	if _swap_cache.size() >= 2048:
		for stale in _swap_cache.keys().slice(0, 128):
			_swap_cache.erase(stale)
	_swap_cache[key] = tex
	return tex


# ------------------------------------------------------------------ misc GML helpers
static func gml_lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t


static func keycode_to_key(code: int) -> String:
	match code:
		-1:
			return "???"
		VK_BACKSPACE:
			return "backspace"
		VK_TAB:
			return "tab"
		VK_ENTER:
			return "enter"
		VK_SPACE:
			return "space"
		VK_SHIFT:
			return "shift"
		VK_CONTROL:
			return "ctrl"
		VK_ALT:
			return "alt"
		VK_LSHIFT:
			return "lshift"
		VK_LCONTROL:
			return "lctrl"
		VK_LALT:
			return "lalt"
		164:
			return "ralt"
		161:
			return "rshift"
		163:
			return "rctrl"
		19:
			return "pause"
		20:
			return "capslock"
		VK_ESCAPE:
			return "esc"
		34:
			return "pdown"
		33:
			return "pup"
		35:
			return "end"
		36:
			return "home"
		VK_LEFT:
			return "left"
		VK_UP:
			return "up"
		VK_RIGHT:
			return "right"
		VK_DOWN:
			return "down"
		45:
			return "insert"
		46:
			return "delete"
		96:
			return "num 0"
		97:
			return "num 1"
		98:
			return "num 2"
		99:
			return "num 3"
		100:
			return "num 4"
		101:
			return "num 5"
		102:
			return "num 6"
		103:
			return "num 7"
		104:
			return "num 8"
		105:
			return "num 9"
		112:
			return "f1"
		113:
			return "f2"
		114:
			return "f3"
		115:
			return "f4"
		116:
			return "f5"
		117:
			return "f6"
		118:
			return "f7"
		119:
			return "f8"
		120:
			return "f9"
		121:
			return "f10"
		122:
			return "f11"
		123:
			return "f12"
		_:
			return char(code).to_lower()


## scr_pallete_shift port (h,s,v shifts on [r,g,b,a,...] float arrays, 0..1 floats)
static func scr_pallete_shift(colours: Array, h: float, s: float, v: float) -> Array:
	var out: Array = []
	var i := 0
	while i < colours.size():
		var r: float = colours[i]
		var g: float = colours[i + 1]
		var b: float = colours[i + 2]
		var a: float = colours[i + 3]
		var hsv := _rgb_to_hsv(r, g, b)
		var rgb := _hsv_to_rgb(
			fposmod(hsv[0] * 255.0 + h, 256.0), hsv[1] * 255.0 + s, hsv[2] * 255.0 + v
		)
		out.append(rgb[0] / 255.0)
		out.append(rgb[1] / 255.0)
		out.append(rgb[2] / 255.0)
		out.append(a)
		i += 4
	return out


static func _rgb_to_hsv(r: float, g: float, b: float) -> Array:
	var max_val: float = max(r, max(g, b))
	var min_val: float = min(r, min(g, b))
	var delta: float = max_val - min_val
	var hue := 0.0
	var saturation := 0.0
	var value := max_val
	if delta != 0:
		saturation = delta / max_val
		var delta_r: float = (((max_val - r) / 6.0) + (delta / 2.0)) / delta
		var delta_g: float = (((max_val - g) / 6.0) + (delta / 2.0)) / delta
		var delta_b: float = (((max_val - b) / 6.0) + (delta / 2.0)) / delta
		if r == max_val:
			hue = delta_b - delta_g
		elif g == max_val:
			hue = (1.0 / 3.0) + delta_r - delta_b
		elif b == max_val:
			hue = (2.0 / 3.0) + delta_g - delta_r
		if hue < 0:
			hue += 1
		if hue > 1:
			hue -= 1
	return [hue, saturation, value]


static func _hsv_to_rgb(hue: float, saturation: float, value: float) -> Array:
	var h := fmod(hue, 256.0) / 255.0
	var s := clampf(saturation / 255.0, 0.0, 1.0)
	var v := clampf(value / 255.0, 0.0, 1.0)
	var c := v * s
	var bb := c * (1.0 - absf(fmod(h * 6.0, 2.0) - 1.0))
	var m := v - c
	var rgb: Array
	if h < 1.0 / 6.0:
		rgb = [c, bb, 0.0]
	elif h < 2.0 / 6.0:
		rgb = [bb, c, 0.0]
	elif h < 3.0 / 6.0:
		rgb = [0.0, c, bb]
	elif h < 4.0 / 6.0:
		rgb = [0.0, bb, c]
	elif h < 5.0 / 6.0:
		rgb = [bb, 0.0, c]
	else:
		rgb = [c, 0.0, bb]
	return [
		roundi((rgb[0] + m) * 255.0), roundi((rgb[1] + m) * 255.0), roundi((rgb[2] + m) * 255.0)
	]
