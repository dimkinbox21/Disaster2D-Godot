extends GMNode
## Port of obj_menu_achvarrow (achievement list scroll arrows).

func _gm_draw() -> void:
	draw_self()
	if GM.mouse_down(2) and position_meeting(GM.mouse_x, GM.mouse_y):
		for a in GMNode.all_of("obj_menu_achivements"):
			a.move(image_yscale)
