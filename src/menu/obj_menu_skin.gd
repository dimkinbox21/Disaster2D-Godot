extends "res://src/menu/obj_menu_button.gd"
## Port of obj_menu_skin (skins shop with palette previews).

var character := 0
var palette := -1
var demon := false
var exe := false
var price := 0
var tradeName := ""

var skinName := ["default", "classic", "eccentric", "custom"]
var tableIndex := 0
var percent := ""
var from: Array = []
var to: Array = []

func _ready() -> void:
	super._ready()
	image_speed = 0.0
	offset = 0.0
	sY = position.y

	skinName = ["default", "classic", "eccentric", "custom"]
	tableIndex = character
	percent = ""
	if demon:
		tableIndex += Globals.PALETTE_DEMON
	if exe:
		tableIndex += Globals.PALETTE_EXE

	if exe:
		match character:
			Globals.EXE_ORIGINAL:
				skinName[2] = "coldblood"
			Globals.EXE_CHAOS:
				skinName[1] = "prismarine"
				skinName[2] = "vermillion"
			Globals.EXE_EXETIOR:
				skinName[2] = "menace"
			Globals.EXE_EXELLER:
				skinName[2] = "oldschool"

	if palette == -1:
		from = [0, 0, 0, 0]
		to = [0, 0, 0, 0]
	else:
		var pal: Dictionary = Unlockables.palettes[tableIndex]
		if palette != 2:
			var list: Array = Palletes.palettes[tableIndex]
			var entry: Dictionary = list[palette] if palette < list.size() else list[0]
			from = entry["from"]
			to = entry["to"]
		else:
			if pal.get("custom", false):
				from = pal["from"]
				to = pal["to"]
			else:
				from = pal["from"]
				to = pal["to"]
				if exe:
					match character:
						Globals.EXE_EXELLER, Globals.EXE_EXETIOR:
							to = GM.scr_pallete_shift(to, 0, 0, -60)
							percent = _percent_value(from, to)
						_:
							to = GM.scr_pallete_shift(to, 60, 0, 0)
							percent = _percent_hue(from, to)
				else:
					to = GM.scr_pallete_shift(to, 60, 0, 0)
					percent = _percent_hue(from, to)

func _percent_hue(f: Array, t: Array) -> String:
	var h1 := Color(f[0], f[1], f[2]).h
	var h2 := Color(t[0], t[1], t[2]).h
	if is_equal_approx(h1, h2):
		return "\n(def.)"
	return "\n(%d)" % int(h2 * 255.0)

func _percent_value(f: Array, t: Array) -> String:
	var v1 := Color(f[0], f[1], f[2]).v
	var v2 := Color(t[0], t[1], t[2]).v
	if is_equal_approx(v1, v2):
		return "\n(def.)"
	return "\n(%d)" % int(v2 * 255.0)

func _idle_sprites() -> Array:
	# returns [sprite, frame, offX, offY]
	if not exe:
		match character:
			0:
				return ["spr_merfurmu", 0, 0, 0]
			Globals.CHARACTER_TAILS:
				return ["spr_etails_idle" if demon else "spr_tails_idle", 0, 4, 0]
			Globals.CHARACTER_KNUX:
				return ["spr_eknux_idle" if demon else "spr_knux_idle", 0, 0, 0]
			Globals.CHARACTER_EGGMAN:
				return ["spr_eegg_idle" if demon else "spr_egg_idle", 0, 0, 7]
			Globals.CHARACTER_CREAM:
				return ["spr_ecream_idle" if demon else "spr_cream_idle", 0, 2, 0]
			Globals.CHARACTER_AMY:
				return ["spr_eamy_idle" if demon else "spr_amy_idle", 0, 0, 0]
			Globals.CHARACTER_SALLY:
				return ["spr_esally_idle" if demon else "spr_sally_idle", 0, 0, 4]
	else:
		match character:
			Globals.EXE_ORIGINAL:
				return ["spr_exe_idle", 0, 0, 0]
			Globals.EXE_CHAOS:
				return ["spr_chaos_won", 3, 0, 0]
			Globals.EXE_EXETIOR:
				return ["spr_exetior_idle", 0, 0, 0]
			Globals.EXE_EXELLER:
				return ["spr_exeller_idle", 0, 0, 0]
	return ["spr_merfurmu", 0, 0, 0]

func isAvaiable() -> bool:
	if price == 0:
		return true
	return Unlockables.trades.has(tradeName)

func click() -> void:
	var menu := _menu()
	if menu:
		menu.buttonSelected(bid, bcolumn, 0, true)
	if not isAvaiable():
		if Achievements.mercoins >= price:
			Achievements.mercoins -= price
			Unlockables.trades.append(tradeName)
			Achievements.save()
			Unlockables.save()
			GameAudio.play_sound("snd_cash")
			if menu:
				menu.buttonSelected(bid, bcolumn, 0, true)
			return
		else:
			GameAudio.play_sound("snd_nono")
			return
	else:
		GameAudio.play_sound("snd_menu_press")

	var pal: Dictionary = Unlockables.palettes[tableIndex]
	if palette == 2:
		if not pal.get("custom", false):
			pal["custom"] = true
			pal["from"] = from
			pal["to"] = to
			pal["name"] = skinName[palette + 1]
			Unlockables.save()
			return
		if exe:
			match character:
				Globals.EXE_EXELLER, Globals.EXE_EXETIOR:
					var v1 := Color(from[0], from[1], from[2]).v
					if v1 < 155.0 / 255.0:
						to = GM.scr_pallete_shift(to, 0, 0, 75)
					else:
						to = GM.scr_pallete_shift(to, 0, 0, -15)
					percent = _percent_value(from, to)
				_:
					to = GM.scr_pallete_shift(to, 15, 0, 0)
					percent = _percent_hue(from, to)
		else:
			to = GM.scr_pallete_shift(to, 10, 0, 0)
			percent = _percent_hue(from, to)
	else:
		pal["custom"] = false

	pal["from"] = from
	pal["to"] = to
	pal["name"] = skinName[palette + 1]
	Unlockables.save()

func _gm_draw() -> void:
	var menu := _menu()
	if menu == null:
		return
	var pal: Dictionary = Unlockables.palettes[tableIndex]
	if menu.bSelected == bid and menu.bSelectedColumn == bcolumn:
		image_blend = Color("910000")
	else:
		image_blend = GM.C_WHITE
		if pal.get("name", "") == skinName[palette + 1]:
			image_blend = GM.C_GREEN
	draw_self()

	var s := _idle_sprites()
	var spr: String = s[0]
	var frame: int = s[1]
	var off_x: float = s[2]
	var off_y: float = s[3]

	# palette-swapped character preview (tail drawn first — behind the body,
	# exactly like the original Draw event order)
	if not exe and character == Globals.CHARACTER_TAILS:
		var tail := "spr_etails_tail2" if demon else "spr_tails_tail2"
		_draw_swapped(tail, 0, position.x + 32 + 2 + off_x, position.y + 44 + 4, from, to)
	_draw_swapped(spr, frame, position.x + 32 + off_x, position.y + 44 + off_y, from, to)

	var state := "\\price `%d~" % price
	if isAvaiable():
		state = "|equip~"
		if pal.get("name", "") == skinName[palette + 1]:
			state = "@equipped~"

	var skin_text: String = skinName[palette + 1] + percent
	var skin_width := GM.scr_text_spr(self, -200, -200, skin_text)
	var state_width := GM.scr_text_spr(self, -200, -200, state)
	GM.scr_text_spr(self, position.x - skin_width / 2 + 32, position.y + 6, skin_text)
	GM.scr_text_spr(self, position.x - state_width / 2 + 32, position.y + sprite_height() - 12, state)

	if GM.mouse_pressed(0) and position_meeting(GM.mouse_x, GM.mouse_y):
		menu.buttonPressed(bid, bcolumn)

func _draw_swapped(spr_name: String, frame: int, gx: float, gy: float, pat: Array, repl: Array) -> void:
	var tex := GM.swapped_texture(spr_name, frame, pat, repl)
	if tex == null:
		return
	var m := GM.sprite_meta(spr_name)
	draw_texture(tex, to_local(Vector2(gx, gy)) - Vector2(m["xorigin"], m["yorigin"]))
