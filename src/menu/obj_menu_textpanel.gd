extends GMNode
## Port of obj_menu_textpanel.

var tid := ""

var text := ""


func _gm_draw() -> void:
	draw_self()
	GM.scr_text_spr(self, position.x + 4, position.y + 4, text, GM.C_WHITE)
