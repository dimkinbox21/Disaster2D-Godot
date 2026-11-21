extends GMNode
## Port of obj_menu_gif (mechanics demo animation).

var spr := "spr_menu_spin"


func _gm_step() -> void:
	sprite_name = spr
