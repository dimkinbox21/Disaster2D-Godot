extends "res://src/menu/obj_menu_button.gd"
## Port of obj_menu_icon (lobby icons shop).

@export_storage var index := 0
var price := 25


func _ready() -> void:
	super._ready()
	image_speed = 0.0
	offset = 0.0
	sY = position.y
	price = 25
	if index == 0:
		price = 0
	if index >= 9 and index <= 17:
		price = 50
	if index >= 18 and index <= 24:
		price = 75


func isAvaiable() -> bool:
	if price == 0:
		return true
	return Unlockables.trades.has("icon%d" % index)


func click() -> void:
	var menu := _menu()
	if menu:
		menu.buttonSelected(bid, bcolumn, 0, true)
	if not isAvaiable():
		if Achievements.mercoins >= price:
			Achievements.mercoins -= price
			Unlockables.trades.append("icon%d" % index)
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
	Unlockables.lobbyIcon = index
	Unlockables.save()
	GameAudio.play_sound("snd_menu_press")


func _gm_draw() -> void:
	var menu := _menu()
	if menu == null:
		return
	if menu.bSelected == bid and menu.bSelectedColumn == bcolumn:
		image_blend = Color("910000")
	else:
		image_blend = GM.C_WHITE
		if Unlockables.lobbyIcon == index:
			image_blend = GM.C_GREEN
	draw_self()
	draw_sprite("spr_menu_lobbyicon", index, position.x + 32, position.y + 32)
	var state := "\\price `%d~" % price
	if isAvaiable():
		state = "|equip~"
		if Unlockables.lobbyIcon == index:
			state = "@equipped~"
	var state_width := GM.scr_text_spr(self, -200, -200, state)
	GM.scr_text_spr(
		self, position.x - state_width / 2 + 32, position.y + sprite_height() - 12, state
	)
