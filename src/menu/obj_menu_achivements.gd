extends GMNode
## Port of obj_menu_achivements (scrollable achievements list).

var scroll := 0.0
var tmpScroll := 0.0


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			move(6)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			move(-6)


func move(dir: float) -> void:
	tmpScroll += dir * 8
	if tmpScroll < -sprite_height():
		tmpScroll = -sprite_height()
	elif tmpScroll > 0:
		tmpScroll = 0


func _gm_step() -> void:
	if not is_visible_in_tree():
		return
	scroll = GM.gml_lerp(scroll, tmpScroll, 0.2)
	if kd(Globals.KeyUp):
		move(1)
	elif kd(Globals.KeyDown):
		move(-1)


func _gm_draw() -> void:
	for i in 50:
		var col := GM.C_GREEN if Achievements.achivements[i] else GM.C_WHITE
		draw_sprite_part(
			"spr_achivements",
			0,
			Rect2(0, i * 38, 428, 38),
			480.0 / 2 - sprite_width() / 2,
			270.0 / 2 + i * 38 + scroll,
			1,
			1,
			col,
			1
		)
	for c in Achievements.changed:
		draw_sprite(
			"spr_achivements_new", 0, 480.0 / 2 - sprite_width() / 2, 270.0 / 2 + c * 38 + scroll
		)
