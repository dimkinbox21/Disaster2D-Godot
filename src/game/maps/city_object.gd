extends GMNode
var properties: Dictionary = {}
var record: Dictionary = {}
var origin := Vector2.ZERO
var sway := 0.0
var turn := 0
var linked: GMNode = null
var offset := 14.0


func _ready():
	super._ready()
	origin = position
	image_speed = 0
	if gm_name.contains("chain"):
		depth = 100 + float(properties.get("range", 1))
	else:
		depth = 90
	z_index = -int(depth)


func _gm_step():
	var time := Time.get_ticks_msec() / 200.0
	var tid := int(properties.get("tid", -1))
	if not is_instance_valid(linked) and tid >= 0:
		for n in all_of("obj_limpcity_eyechain") + all_of("obj_limpcity_eyechain2"):
			if int(n.properties.get("sid", -2)) == tid:
				linked = n
				break
	if is_instance_valid(linked):
		var m := GM.sprite_meta(linked.sprite_name)
		var a := deg_to_rad(-linked.sprite_rotation)
		var inverted := linked.gm_name.ends_with("chain2")
		origin = (
			linked.position
			+ Vector2(
				sin(a) * m.h + (m.w / 2.0 + 2 if inverted else -m.w / 2.0 - 2),
				cos(a) * m.h + (2 if inverted else -2)
			)
		)
		offset = -14 if inverted else 14
	if gm_name.contains("chain"):
		var amount := float(properties.get("range", 1))
		sprite_rotation = -(180 if gm_name.ends_with("chain2") else 0) - sin(time) * amount * 8
		position = origin + Vector2(sin(time) * amount, cos(time) * amount)
	else:
		position = origin + Vector2(sin(time + 40) * 2, offset)
		turn -= 1
		if turn <= 0:
			sway = [-16, 16, -8, 8].pick_random()
			turn = 60
		sprite_rotation = -sway
		sway = move_toward(sway, 0, 0.5)


func _gm_draw():
	draw_self()
	if (
		gm_name == "obj_limpcity_eyeA"
		and is_instance_valid(Globals.player)
		and bbox_rect().intersects(Globals.player.bbox_rect())
	):
		draw_sprite(
			"spr_limpcity_eye_hint", int(Time.get_ticks_msec() / 400) % 4, position.x, position.y
		)
	elif gm_name == "obj_limpcity_eyeB" and get_meta("used", false):
		var nearest: GMNode = null
		var distance := 270.0
		for n in all_of("obj_player") + all_of("obj_player_puppet"):
			if not n.visible:
				continue
			var d := position.distance_to(n.position)
			if d < distance:
				nearest = n
				distance = d
		draw_sprite(
			"spr_limpcity_eyelid" if nearest != null else "spr_limpcity_eye_recharge",
			5,
			position.x,
			position.y,
			1,
			1,
			(nearest.position - position).angle() * 180 / PI if nearest != null else 0
		)
