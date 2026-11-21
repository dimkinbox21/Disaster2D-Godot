extends GMNode
var colour = Color.BLACK


func _process(_dt):
	queue_redraw()


func _gm_draw():
	var origin = Vector2.ZERO
	for camera in all_of("obj_camera"):
		origin = camera.render_origin
		break
	draw_rect(Rect2(origin, Vector2(480, 270)), colour)
