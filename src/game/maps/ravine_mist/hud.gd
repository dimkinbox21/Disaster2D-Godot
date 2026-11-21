extends Node2D
var rules: Node


func _process(_dt):
	queue_redraw()


func _draw():
	if not is_instance_valid(rules):
		return
	if rules.flash > 0:
		draw_rect(Rect2(0, 0, 480, 270), Color(1, 1, 1, rules.flash))
	var texture := GM.sprite_texture("spr_ravinemist_ui", clampi(rules.shard_count, 0, 7))
	if texture != null:
		draw_texture(
			texture,
			(
				Vector2(154, 231)
				- Vector2(
					GM.sprite_meta("spr_ravinemist_ui").xorigin,
					GM.sprite_meta("spr_ravinemist_ui").yorigin
				)
			)
		)
