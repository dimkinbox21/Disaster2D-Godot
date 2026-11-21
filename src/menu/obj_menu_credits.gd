extends GMNode
## Port of obj_menu_credits (scrolling credits image).


func _gm_step() -> void:
	if not is_visible_in_tree():
		return
	if kd(Globals.KeyDown):
		position.y -= 2
	elif kd(Globals.KeyUp):
		position.y += 2
	else:
		position.y -= 0.25

	if position.y <= -sprite_height() - 38:
		position.y = 270.0 - 1 - 38
	if position.y >= 270.0 + 38:
		position.y = -sprite_height() + 1 + 38


func _gm_draw() -> void:
	draw_self()
