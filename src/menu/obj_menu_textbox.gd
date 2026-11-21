extends GMNode
## Port of obj_menu_textbox.

var bid := 0
@export_storage var submenu := 0
@export_storage var tid := "0"
@export_storage var placeholder := ""
@export_storage var limit := 15

var text := ""
var prevText := ""


func _gm_step() -> void:
	var menu: GMNode = null
	for m in GMNode.all_of("obj_menu"):
		menu = m
		break
	if menu == null:
		return
	if menu.bSelected == bid and menu.submenu == submenu:
		if GM.key_down(GM.VK_CONTROL) and GM.key_pressed(86):  # Ctrl+V
			GM.keyboard_string = DisplayServer.clipboard_get()
		if GM.keyboard_string != prevText:
			if GM.keyboard_string.length() > limit:
				GM.keyboard_string = GM.keyboard_string.substr(0, limit)
			text = GM.keyboard_string.to_lower()
			text = text.replace("\r", "").replace("\t", "").replace("\n", "")
			menu.textChanged(bid, text)
			prevText = GM.keyboard_string
		menu.ignoreButtons = true
	# placeholder text handling is in draw


func _gm_draw() -> void:
	var menu: GMNode = null
	for m in GMNode.all_of("obj_menu"):
		menu = m
		break
	if menu == null:
		return
	draw_self()
	GM.scr_text_spr(
		self,
		position.x + 2,
		position.y + 5,
		text if text != "" else placeholder,
		GM.C_WHITE if text != "" else GM.C_GRAY
	)


func _gm_interact() -> void:
	if GM.mouse_pressed(0) and position_meeting(GM.mouse_x, GM.mouse_y):
		for menu in GMNode.all_of("obj_menu"):
			if menu.submenu == submenu:
				menu.buttonSelected(bid, -1, 0, false)
