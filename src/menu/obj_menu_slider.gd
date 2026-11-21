extends GMNode
## Port of obj_menu_slider.

var bid := 0
var value := 0.5


func _gm_interact() -> void:
	var menu: GMNode = null
	for m in GMNode.all_of("obj_menu"):
		menu = m
		break
	if menu == null:
		return
	if position_meeting(GM.mouse_x, GM.mouse_y):
		if GM.mouse_pressed(2):
			menu.buttonSelected(bid, -1, 0, false)
		if GM.mouse_down(2):
			var bb := bbox_rect()
			var raw := (GM.mouse_x - bb.position.x) / maxf(bb.size.x, 1.0)
			value = floorf(raw * 5) / 5.0
	menu.sliderChanged(value)
	image_index = value * 5
	queue_redraw()


func _gm_draw() -> void:
	draw_self()
