extends "res://src/game/maps/shared/rules.gd"
## Dark Tower: presentation and network effects.
var state: Dictionary = {}
var doll: GMNode
var stals: Dictionary = {}
var darkness = 0.0
var jumpscare = 0
var scare_camera = false
var received_frame = 0


func nodes(type: String) -> Array:
	return GMNode.all_of(type)


func _ready():
	process_physics_priority = 60
	for type in [
		"obj_darktower_darkness",
		"obj_darktower_fog",
		"obj_darktower_jumpscare",
		"obj_majong_controller",
		"obj_majong_trigger",
		"obj_majong_trigger_point"
	]:
		for n in nodes(type):
			n.gm_visible = false
			n.set_physics_process(false)
	var layer = CanvasLayer.new()
	layer.layer = 9
	map.add_child(layer)
	var overlay = load("res://src/game/maps/dark_tower/overlay.gd").new()
	overlay.rules = self
	layer.add_child(overlay)
	doll = visual("spr_darktower_tailsol", Vector2.ZERO)


func visual(sprite: String, at: Vector2) -> GMNode:
	var n = load("res://src/menu/gm_plain.gd").new()
	n.sprite_name = sprite
	n.position = at
	n.image_speed = 0
	map.add_child(n)
	return n


func receive(data: Dictionary):
	if int(data.get("map", -1)) != 16:
		return
	state = data
	received_frame = frame
	doll.position = Vector2(data.doll.x, data.doll.y)
	doll.image_index = data.doll.state
	doll.image_xscale = 1 if float(data.doll.vx) >= 0 else -1
	doll.queue_redraw()
	for n in nodes("obj_darktower_ball"):
		n.position.y = (
			float(n.record.position[1])
			+ (
				float(data.ball)
				* float(n.properties.get("dir", 1))
				* float(n.properties.get("dist", 100))
			)
		)
		n.queue_redraw()
	for id in data.stals:
		var item: Dictionary = data.stals[id]
		if int(item.state) == 0:
			if stals.has(id):
				stals[id].queue_free()
				stals.erase(id)
		else:
			if not stals.has(id):
				stals[id] = visual("spr_darktower_staloktiti", Vector2(item.x, item.y))
				stals[id].depth = 101
				stals[id].image_alpha = 0
			stals[id].position = Vector2(item.x, item.y)
			stals[id].queue_redraw()
	for event in data.get("events", []):
		if int(event.owner) >= 0 and int(event.owner) != Net.nid:
			continue
		var at = Vector2(event.x, event.y)
		match str(event.kind):
			"doll_notice":
				GameAudio.play_sound_at("snd_tailsball", at, 500)
			"doll_chase":
				GameAudio.play_sound_at("snd_tailsball_chase", at, 500)
			"jumpscare":
				jumpscare = 60
				GameAudio.play_sound("snd_tailsball_jumpscare")
				GameAudio.play_sound_at("snd_tailsball_jumpscare2", at)
			"stal_notice":
				GameAudio.play_sound_at("snd_sisi_notice", at)
			"stal_break":
				GameAudio.play_sound_at("snd_snowball_break", at)
				for camera in nodes("obj_camera"):
					if (
						is_instance_valid(Globals.player)
						and Globals.player.position.distance_to(at) < 150
					):
						camera.camera_shake(
							25, 1 - Globals.player.position.distance_to(at) / 500.0, 0.2
						)
				for index in 4:
					var part = load("res://src/game/maps/tower_particle.gd").new()
					part.sprite_name = "spr_darktower_staloktiti2"
					part.position = at + Vector2(40, 0)
					part.velocity = Vector2(
						(-1 if index < 2 else 1) * (1 + float(index % 2) / 10), -randi_range(4, 7)
					)
					part.direction = -1 if index < 2 else 1
					map.add_child(part)


func _physics_process(_delta):
	frame += 1
	flash = maxf(0, flash - 0.32)
	jumpscare = maxi(0, jumpscare - 1)
	var p = Globals.player
	if is_instance_valid(p):
		if jumpscare > 0:
			if Time.get_ticks_msec() % 22 <= 10:
				var warp = float(randi_range(-60, 60))
				for camera in nodes("obj_camera"):
					if is_instance_valid(camera._cam2d):
						camera._cam2d.zoom = Vector2(480 / (480 + warp), 270 / (270 + warp))
						camera._cam2d.offset = Vector2(-warp, -warp)
			scare_camera = true
		elif scare_camera:
			for camera in nodes("obj_camera"):
				if is_instance_valid(camera._cam2d):
					camera._cam2d.zoom = Vector2.ONE
					camera._cam2d.offset = Vector2.ZERO
			scare_camera = false
	if not is_instance_valid(p) or Net.gameEnds:
		return
	var age = int(state.get("age", frame)) + frame - received_frame
	darkness = move_toward(darkness, 1.0 if age % 662 >= 601 else 0.0, 0.016)
	var center = p.position
	for camera in nodes("obj_camera"):
		center = camera.render_origin + Vector2(240, 135)
		break
	for n in stals.values():
		n.image_alpha = minf(1, n.image_alpha + 0.016)
		n.queue_redraw()
		if frame % 8 == 0 and n.position.distance_squared_to(center) < 360000:
			var drop = load("res://src/game/maps/tower_drop.gd").new()
			drop.sprite_name = "spr_darktower_staloktiti1"
			drop.position = (
				n.position + Vector2(40 + randi_range(-14, 14), 40 + randi_range(-10, 10))
			)
			map.add_child(drop)
	if not state.is_empty() and frame > received_frame:
		doll.position += (
			Vector2(state.doll.vx, state.doll.vy) if int(state.doll.state) == 2 else Vector2.ZERO
		)
		doll.queue_redraw()
		for id in stals:
			var item: Dictionary = state.stals[id]
			if int(item.state) == 2:
				stals[id].position.y += float(item.vy) + 0.164 * (frame - received_frame)
	for n in nodes("obj_darktower_ball"):
		if not state.is_empty():
			n.position.y = (
				float(n.record.position[1])
				+ (
					clampf(
						(
							float(state.ball)
							+ 0.015 * (frame - received_frame) * float(state.ball_dir)
						),
						-1,
						1
					)
					* float(n.properties.get("dir", 1))
					* float(n.properties.get("dist", 100))
				)
			)
			n.queue_redraw()
	if jumpscare > 0:
		for camera in nodes("obj_camera"):
			camera.camera_shake(1, 4)
