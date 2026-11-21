extends GMNode
var properties: Dictionary = {}
var record: Dictionary = {}
var active = false
var fade = 0.0
var variant = 0
var lantern_frame = 0.0
var light_origin = Vector2.ZERO
var light_alpha = 0.0


func _ready():
	if gm_name == "obj_pf_lift":
		image_alpha = 0
		depth = -2
		image_speed = 0
	if (
		gm_name.begins_with("obj_weed_lantern")
		or gm_name in ["obj_marijuna_crystal", "obj_marijuna_guko", "obj_marijuna_judger"]
	):
		image_speed = 0
	light_origin = (
		position
		+ Vector2(
			0, sprite_height() / 2 if gm_name == "obj_weed_lantern" else sprite_height() + 16.5
		)
	)
	variant = int(image_index)
	super._ready()
	if gm_name == "obj_vv_lavacolumn":
		add_child(load("res://src/game/maps/freedom_lava_audio.gd").new())


func _gm_step():
	if gm_name.begins_with("obj_weed_lantern"):
		light_alpha = move_toward(light_alpha, 1 if active else 0, 1.0 / 30)
		lantern_frame = lantern_frame + 0.16 if active else 0
		if lantern_frame >= 3:
			lantern_frame = 1
		if gm_name == "obj_weed_lantern":
			image_index = lantern_frame
		else:
			sprite_rotation = -((sin(Time.get_ticks_msec() / 400.0) + 1) / 2) * 4
	elif gm_name == "obj_marijuna_crystal":
		fade = move_toward(fade, 1 if active else 0, 0.016)
	elif gm_name == "obj_marijuna_guko":
		if not all_of("obj_bigring").is_empty():
			fade = minf(1, fade + 0.016)
		image_index = variant
		image_alpha = 1 - fade


func _gm_draw():
	if gm_name == "obj_weed_selfinsert":
		if all_of("obj_bigring").is_empty():
			draw_sprite("spr_selfinsert2", 0, 3968, 974)
		else:
			draw_self()
		return
	if gm_name == "obj_marijuna_crystal":
		draw_sprite("spr_marijuna_crystal", 0, position.x, position.y)
		draw_sprite(
			"spr_marijuna_crystal2",
			int(Time.get_ticks_msec() / 100),
			position.x,
			position.y,
			1,
			1,
			0,
			Color.WHITE,
			fade
		)
		return
	draw_self()
	if gm_name in ["obj_weed_lantern2", "obj_weed_lantern3"]:
		var radians = deg_to_rad(-sprite_rotation)
		var target = (
			position + Vector2(sin(radians) * sprite_height(), cos(radians) * sprite_height())
		)
		draw_sprite("spr_weed_latern", int(lantern_frame), target.x, target.y)
		if active:
			draw_sprite(
				"spr_weed_light", int(Time.get_ticks_msec() / 500), target.x, target.y + 16.5
			)
	elif gm_name == "obj_marijuna_guko":
		draw_sprite(
			"spr_marijuna_guko2", variant, position.x, position.y, 1, 1, 0, Color.WHITE, fade
		)
