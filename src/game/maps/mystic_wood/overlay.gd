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
	if (
		rules.lantern >= 0
		and Globals.character > 0
		and not p.isDead
		and p.revivalTimes < 2
		and not rules.state.is_empty()
		and int(rules.state.age) - int(rules.state.lantern_since) < 1200
	):
		for n in GMNode.all_of("obj_weed_lantern"):
			if int(n.properties.nid) == rules.lantern:
				var target: Vector2 = rules.lantern_target(n)
				var tex = GM.sprite_texture("spr_sindicator3", 0)
				var meta = GM.sprite_meta("spr_sindicator3")
				if tex != null:
					draw_set_transform((p.position - cam).ceil(), (target - p.position).angle())
					draw_texture(tex, -Vector2(meta.xorigin, meta.yorigin))
					draw_set_transform(Vector2.ZERO)
	if Globals.character > 0:
		if rules.wood_anim >= 0:
			spr(
				"spr_weed_arms",
				int(rules.wood_anim),
				Vector2(
					-10 + sin(Time.get_ticks_msec() / 300.0) * 8,
					-10 + cos(Time.get_ticks_msec() / 300.0) * 8
				)
			)
		if rules.wood_progress > 0:
			spr("spr_weed_vinjetk", 0, Vector2.ZERO, rules.wood_progress)
	for n in GMNode.all_of("obj_weed_lantern"):
		if n.light_alpha > 0:
			spr("spr_weed_light", 0, n.light_origin - cam, n.light_alpha)
