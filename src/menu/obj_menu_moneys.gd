extends GMNode
## Port of obj_menu_moneys (boosty popup).

var popup := false


func _gm_interact() -> void:
	if popup:
		if GM.mouse_pressed(0):
			if GM.mouse_x >= 105 and GM.mouse_x <= 128 and GM.mouse_y >= 208 and GM.mouse_y <= 212:
				OS.shell_open("https://boosty.to/handyrka")
			if GM.mouse_x >= 105 and GM.mouse_x <= 128 and GM.mouse_y >= 222 and GM.mouse_y <= 226:
				OS.shell_open("https://boosty.to/merfamphetamine")
	if GM.mouse_pressed(0):
		if position_meeting(GM.mouse_x, GM.mouse_y):
			popup = not popup
		else:
			popup = false
	if popup and GM.key_pressed(GM.VK_ANYKEY):
		popup = false


func _gm_draw() -> void:
	if popup:
		draw_sprite("spr_pay_us_money2", 0, position.x - 4, position.y)
	draw_self()
