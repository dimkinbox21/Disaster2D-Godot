extends GMFloor
## Port of obj_solid_block / obj_solid_block2 — INVISIBLE collision blocks
## (the original obj_solid_parent has an empty Draw event).


func default_sprite_name() -> String:
	return "spr_block"


func _gm_draw() -> void:
	if OS.get_environment("SHOW_BLOCKS") != "1":
		pass  # original: empty Draw event — collision is invisible
