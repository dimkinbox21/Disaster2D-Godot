extends GMNode
## Port of obj_menu_money (mercoins counter on Extra screens).

func _gm_draw() -> void:
	GM.scr_counter_draw_s(self, Achievements.mercoins, position.x, position.y)
