extends GMNode
## Port of obj_menu_link1/obj_menu_link2 (clickable web links).

@export_storage var open_url := ""


func _gm_interact() -> void:
	if GM.mouse_pressed(0) and position_meeting(GM.mouse_x, GM.mouse_y):
		OS.shell_open(open_url)
