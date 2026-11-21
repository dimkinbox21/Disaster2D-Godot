extends Node2D
var rules: Node


func _process(_delta):
	queue_redraw()


func _draw():
	if not is_instance_valid(rules):
		return
	var fog = GM.sprite_texture("spr_darktower_fog", 0)
	if fog != null:
		draw_texture(fog, Vector2(-247.5 + sin(Time.get_ticks_msec() / 4000.0) * 200, 0))
	if rules.darkness > 0:
		draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, rules.darkness))
	if rules.jumpscare > 0:
		var red = GM.sprite_texture("spr_redring_fore", int(Time.get_ticks_msec() / 200))
		if red != null:
			draw_texture(red, Vector2.ZERO, Color(1, 1, 1, 0.4))
		if Time.get_ticks_msec() % 22 <= 10:
			var face = GM.sprite_texture("spr_darktower_jumpscare", 0)
			if face != null:
				draw_texture_rect(
					face,
					Rect2(Vector2(randi_range(-4, 4), randi_range(-4, 4)), Vector2(480, 270)),
					false
				)
