extends "res://src/menu/obj_menu_button.gd"
## Port of obj_menu_serverbutton.

var region := ""
var timer := 0.0

func default_sprite_name() -> String:
	return "spr_menu_public"

func _ready() -> void:
	super._ready()
	timer = 0

func _gm_draw() -> void:
	if submenu == 999:
		image_blend = Color("666666")
	var menu := _menu()
	if menu and menu.bSelected == bid and menu.bSelectedColumn == bcolumn:
		draw_sprite("spr_menu_public2", timer, position.x, position.y + offset)
		timer += 0.25
		var mes := GM.scr_text_spr(self, -999, -999, region)
		GM.scr_text_spr(self, 480.0 / 2 - mes / 2, 214, region)
	draw_self()
	if GM.mouse_pressed(0) and position_meeting(GM.mouse_x, GM.mouse_y):
		if menu:
			menu.buttonPressed(bid, bcolumn)
