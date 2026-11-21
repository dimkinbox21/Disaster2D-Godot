extends GMNode
## Port of obj_menu_abouttext (styled description text on About screens).

@export_storage var text := "aaaaaaaaaaaaaaaaaaaaaa"


func _gm_draw() -> void:
	GM.scr_text_spr(self, position.x, position.y, text)
