extends Node2D
var rules: Node


func _process(_delta):
	queue_redraw()


func spr(name: String, frame: int, at: Vector2, alpha := 1.0):
	var tex = GM.sprite_texture(name, frame)
	if tex != null:
		var meta = GM.sprite_meta(name)
		draw_texture(tex, at - Vector2(meta.xorigin, meta.yorigin), Color(1, 1, 1, alpha))


func _draw():
	if not is_instance_valid(rules) or not is_instance_valid(Globals.player):
		return
	var p = Globals.player
	var cam = Vector2.ZERO
	for c in GMNode.all_of("obj_camera"):
		cam = c.render_origin
		break
	if rules.inversion_left > 0:
		spr(
			"spr_marijuna_boohoo",
			0,
			(
				(
					p.position
					- cam
					- Vector2(
						0,
						(
							36
							if Globals.character == 3
							else 25 if Globals.character in [2, 4, 6] else 20
						)
					)
				)
				. ceil()
			)
		)
	if not GMNode.all_of("obj_bigring").is_empty():
		spr("spr_static", int(rules.frame / 2), Vector2.ZERO, 0.1)
