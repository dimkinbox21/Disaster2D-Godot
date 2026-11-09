extends GMNode
## Port of obj_menu_button (base for togglebutton, skin, icon, taunt, pet, serverbutton).

var bid := 0
var bcolumn: Variant = -1
var submenu := 0
var tid := "0"

var offset := 0.0
var sY := 0.0

func _ready() -> void:
	sprite_name = default_sprite_name() if sprite_name == "" else sprite_name
	image_speed = 0.0
	offset = 0.0
	sY = position.y
	super._ready()

func default_sprite_name() -> String:
	return "spr_menu_buttons"

func _gm_step() -> void:
	if offset > 0:
		position.y = sY - offset
		offset -= 0.2
	else:
		position.y = sY

func click() -> void:
	pass

func _gm_draw() -> void:
	if submenu == 999:
		image_blend = Color("666666")
	draw_self()
	if GM.mouse_pressed(0) and position_meeting(GM.mouse_x, GM.mouse_y):
		var menu := _menu()
		if menu:
			menu.buttonPressed(bid, bcolumn)

func _menu() -> GMNode:
	for m in GMNode.all_of("obj_menu"):
		return m
	return null
