extends Node2D
var rules: Node


func _process(_dt):
	queue_redraw()


func _draw():
	if not is_instance_valid(rules):
		return
	if rules.loss_ticks > 0:
		var texture = GM.sprite_texture("spr_boom", (30 - rules.loss_ticks) / 2)
		if texture != null:
			draw_texture(texture, Vector2.ZERO)
	if rules.flash > 0:
		draw_rect(Rect2(0, 0, 480, 270), Color(1, 1, 1, rules.flash))
