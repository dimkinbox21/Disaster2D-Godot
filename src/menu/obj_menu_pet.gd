extends "res://src/menu/obj_menu_button.gd"
## Port of obj_menu_pet (pets shop).

var index := 0
var price := 0

var offff := 0.0
var spr := "spr_pet_flicky"
var percent := ""
var pet_name := ""
var from: Array = [0, 0, 0, 0]
var to: Array = [0, 0, 0, 0]


func _ready() -> void:
	super._ready()
	image_speed = 0.0
	offset = 0.0
	sY = position.y
	offff = randf() * 99999.0
	spr = "spr_pet_flicky"
	percent = ""
	pet_name = ""
	match index:
		-1:
			price = 0
			spr = "spr_pet_none"
		0:
			spr = "spr_pet_flicky"
			pet_name = "flicky"
			percent = "(def.)"
		1:
			spr = "spr_pet_chao"
			pet_name = "chao"
			percent = "(def.)"
		2:
			spr = "spr_pet_metal"
			pet_name = "metal"
			percent = "(def.)"
		3:
			spr = "spr_pet_daldol_b"
			pet_name = "t. doll"
			percent = "(def.)"
		4:
			spr = "spr_pet_majin"
			pet_name = "majong"
			percent = "(def.)"
		5:
			spr = "spr_pet_mknux"
			pet_name = "m. knux"
			percent = "(def.)"
		6:
			pet_name = "eggor"
			percent = "(def.)"
			spr = "spr_pet_egg"
	if index != -1:
		from = Unlockables.petPallettes[index]["from"]
		to = Unlockables.petPallettes[index]["to"]


func isAvaiable() -> bool:
	if price == 0:
		return true
	return Unlockables.trades.has("pet%d" % index)


func click() -> void:
	var menu := _menu()
	if menu:
		menu.buttonSelected(bid, bcolumn, 0, true)
	if not isAvaiable():
		if Achievements.mercoins >= price:
			Achievements.mercoins -= price
			Unlockables.trades.append("pet%d" % index)
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

	if Unlockables.pet == index and index != -1:
		to = GM.scr_pallete_shift(to, 15, 0, 0)
		percent = "\n(%d)" % int(Color(to[0], to[1], to[2]).h * 255.0)
		Unlockables.petPallettes[index]["to"] = to
	Unlockables.pet = index
	Unlockables.save()


func _gm_draw() -> void:
	var menu := _menu()
	if menu == null:
		return
	if menu.bSelected == bid and menu.bSelectedColumn == bcolumn:
		image_blend = Color("910000")
	else:
		image_blend = GM.C_WHITE
		if Unlockables.pet == index:
			image_blend = GM.C_GREEN
	draw_self()

	var time_ := sin(Time.get_ticks_msec() / 400.0 + offff)
	var spd := Time.get_ticks_msec() / 150.0
	if index == 1:
		spd /= 10.0
	if spr == "spr_pet_none":
		time_ = 0.0
	_draw_swapped(spr, int(spd), position.x + 32, position.y + 32 + time_ * 3)

	var state := "\\price `%d~" % price
	if isAvaiable():
		state = "|equip~"
		if Unlockables.pet == index:
			state = "@equipped~"

	var skin_text: String = "none" if index == -1 else pet_name + percent
	var skin_width := GM.scr_text_spr(self, -200, -200, skin_text)
	GM.scr_text_spr(self, position.x - skin_width / 2 + 32, position.y + 6, skin_text)
	var state_width := GM.scr_text_spr(self, -200, -200, state)
	GM.scr_text_spr(
		self, position.x - state_width / 2 + 32, position.y + sprite_height() - 12, state
	)


func _draw_swapped(spr_name: String, frame: int, gx: float, gy: float) -> void:
	var tex := GM.swapped_texture(spr_name, frame, from, to)
	if tex == null:
		return
	var m := GM.sprite_meta(spr_name)
	draw_texture(tex, to_local(Vector2(gx, gy)) - Vector2(m["xorigin"], m["yorigin"]))
