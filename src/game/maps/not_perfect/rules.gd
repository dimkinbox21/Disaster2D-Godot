extends "res://src/game/maps/shared/rules.gd"
## Not Perfect: presentation and network effects.
var np_state := 0
var np_warning := false
var particles: Array = []
var particles2: Array = []
var bg_scroll := 0.0
var _exit_seen := false


func _ready() -> void:
	process_physics_priority = 60
	z_index = -250
	for i in 15:
		particles.append(Vector2(randi_range(0, 24) * 20, i * 24))
	for i in 10:
		particles2.append(Vector2(i * 48, randi_range(0, 27) * 10))
	for n in GMNode.all_of("obj_np_background"):
		n.gm_visible = false


func np_packet(warn: bool, state: int, previous: int) -> void:
	if state not in range(4) or previous not in range(4):
		return
	# A repeated reliable snapshot must not move the actor a second time.
	if warn and state == np_state:
		return
	np_warning = not warn
	for tile in get_tree().get_nodes_in_group("map_tiles"):
		if tile.depth == 90:
			tile.image_alpha = 0
			tile.visible = np_warning
			tile.queue_redraw()
	if not warn:
		return
	flash = 1
	GameAudio.play_sound("snd_npteleport")
	var p: GMNode = Globals.player
	if is_instance_valid(p):
		p.position -= Vector2(2904 if previous in [1, 3] else 0, 1368 if previous in [2, 3] else 0)
		p.position += Vector2(2904 if state in [1, 3] else 0, 1368 if state in [2, 3] else 0)
		if p.isStuck:
			p.isStuck = false
			p.isGliding = false
			p.glideTimer = 900
		if Globals.character == 5:
			p.ringsTimer = 1800 if p.revivalTimes >= 2 else 2400
			p.ringsSpawn = 0
		# Finite passes replace the original clone's unbounded push-out loops.
		for _pass in 3:
			for group in ["obj_leftvitalkivatel", "obj_rightvitalkivatel"]:
				for push in GMNode.all_of(group):
					if Rect2(p.position - Vector2(6, 20), Vector2(12, 38)).intersects(
						push.bbox_rect()
					):
						p.position.x = (
							push.bbox_rect().position.x - 20
							if group == "obj_leftvitalkivatel"
							else push.bbox_rect().end.x + 14
						)
						p.xspd = 0
						p.yspd = 0
	np_state = state


func _physics_process(_dt: float) -> void:
	frame += 1
	flash = maxf(0, flash - 0.1)
	var p: GMNode = Globals.player
	if not is_instance_valid(p):
		return
	if Net.gameEnds:
		return
	for tile in get_tree().get_nodes_in_group("map_tiles"):
		if tile.depth == 90 and tile.image_alpha < 1:
			tile.image_alpha = minf(1, tile.image_alpha + 1.0 / 300)
			tile.queue_redraw()
	for region in GMNode.all_of("obj_np_teleporn"):
		if (
			int(region.properties.get("tid", 0)) == np_state
			and not region.bbox_rect().intersects(p.bbox_rect())
		):
			p.position = Vector2(
				float(region.properties.get("pX", 0)), float(region.properties.get("pY", 0))
			)
	var exit_seen := not GMNode.all_of("obj_bigring").is_empty()
	if exit_seen and not _exit_seen:
		flash = 1
		_exit_seen = true
	if exit_seen:
		var colour_layer = map.get_node_or_null("Colour")
		if colour_layer != null:
			colour_layer.colour = Color.BLACK
			colour_layer.queue_redraw()
		VisualEffects.set_layer_parameter("Tiles", "g_Intensity", 1.0)
		VisualEffects.set_layer_parameter("ShadowTiles", "g_Intensity", 1.0)
	for bg in GMNode.all_of("gm_background"):
		var side: bool = bg.image_index >= 107 and bg.image_index < 217
		bg_scroll += -0.5 if side else 0.5
		bg.follow_camera = true
		bg._scroll.x = bg_scroll
		bg.queue_redraw()
		bg.layer_colour = Color.RED if exit_seen else Color.WHITE
	queue_redraw()


func _draw() -> void:
	var origin := Vector2.ZERO
	for c in GMNode.all_of("obj_camera"):
		origin = c.render_origin
	draw_rect(
		Rect2(origin, Vector2(480, 270)), Color.BLACK if _exit_seen else Color(0, 0, 63.0 / 255)
	)
	for i in particles.size():
		var pos: Vector2 = particles[i]
		pos.x -= 1
		if pos.x <= -64:
			pos.x = 500
		particles[i] = pos
		var side := false
		for bg in GMNode.all_of("gm_background"):
			side = bg.image_index >= 107 and bg.image_index < 217
		if not side:
			draw_texture(GM.sprite_texture("background_notperf3", int(_exit_seen)), origin + pos)
	for i in particles2.size():
		var pos: Vector2 = particles2[i]
		pos.x = i * 48 + sin(Time.get_ticks_msec() / 400.0 + i) * 2
		pos.y -= 1
		if pos.y <= -16:
			pos.y = 286 + randi_range(0, 32)
		particles2[i] = pos
		var side := false
		for bg in GMNode.all_of("gm_background"):
			side = bg.image_index >= 107 and bg.image_index < 217
		if side:
			draw_texture(GM.sprite_texture("background_notperf2", int(_exit_seen)), origin + pos)


func _process(_dt: float) -> void:
	for bg in GMNode.all_of("gm_background"):
		for camera in GMNode.all_of("obj_camera"):
			bg.position = camera.render_origin + Vector2(bg_scroll, 0)
		bg.queue_redraw()
