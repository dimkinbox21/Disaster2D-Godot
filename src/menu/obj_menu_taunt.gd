extends "res://src/menu/obj_menu_button.gd"
## Port of obj_menu_taunt (taunts shop).

var index := 0
var price := 0

var char_name := "exe"
var spr := "spr_exe_emotion3"
var off := 0.0

func _ready() -> void:
	super._ready()
	image_speed = 0.0
	offset = 0.0
	off = 0.0
	sY = position.y
	char_name = "exe"
	match int(floor(index / 2.0)):
		0:
			spr = "spr_exe_emotion3" if index % 2 == 0 else "spr_exe_emotion2"
			char_name = "exe"
		1:
			spr = "spr_chaos_emotion1" if index % 2 == 0 else "spr_chaos_emotion2"
			char_name = "chaos"
		2:
			spr = "spr_exetior_emotion3" if index % 2 == 0 else "spr_exetior_emotion2"
			char_name = "exetior"
		3:
			if index % 2 == 0:
				spr = "spr_exeller_emotion3"
				off = 16
			else:
				spr = "spr_exeller_emotion2"
			char_name = "exeller"

func isAvaiable() -> bool:
	if price == 0:
		return true
	return Unlockables.trades.has("t%s%d" % [char_name, index % 2])

func click() -> void:
	var menu := _menu()
	if menu:
		menu.buttonSelected(bid, bcolumn, 0, true)
	if not isAvaiable():
		if Achievements.mercoins >= price:
			Achievements.mercoins -= price
			Unlockables.trades.append("t%s%d" % [char_name, index % 2])
			Unlockables.save()
			Achievements.save()
			GameAudio.play_sound("snd_cash")
			if menu:
				menu.buttonSelected(bid, bcolumn, 0, true)
		else:
			GameAudio.play_sound("snd_nono")
			return
	else:
		GameAudio.play_sound("snd_menu_press")

func _gm_draw() -> void:
	var menu := _menu()
	if menu == null:
		return
	if menu.bSelected == bid and menu.bSelectedColumn == bcolumn:
		image_blend = Color("910000")
	else:
		image_blend = GM.C_WHITE
		if Unlockables.trades.has("t%s%d" % [char_name, index % 2]):
			image_blend = GM.C_GREEN
	draw_self()
	draw_sprite(spr, float(Time.get_ticks_msec()) / 100.0, position.x + 32 + off, position.y + 32)
	var state := "\\price `%d~" % price
	if Unlockables.trades.has("t%s%d" % [char_name, index % 2]):
		state = "@equipped~"
	var state_width := GM.scr_text_spr(self, -200, -200, state)
	GM.scr_text_spr(self, position.x - state_width / 2 + 32, position.y + sprite_height() - 12, state)
	if GM.mouse_pressed(0) and position_meeting(GM.mouse_x, GM.mouse_y):
		menu.buttonPressed(bid, bcolumn)
