extends "res://src/game/maps/shared/rules.gd"
## Nasty Paradise: presentation and network effects.
var tick := 0
var particles: Array = []
var balls: Dictionary = {}


func _ready():
	process_physics_priority = 60
	z_index = 200


func effect(sprite: String, at: Vector2, motion := Vector2.ZERO):
	var debris := sprite.ends_with("_part")
	var fx = (
		load("res://src/game/maps/debris.gd" if debris else "res://src/game/obj_quickfx.gd").new()
	)
	fx.sprite_name = sprite
	fx.position = at
	fx.motion = motion
	if debris:
		fx.image_index = randi_range(0, GM.sprite_count(sprite) - 1)
		fx.image_speed = 0
	else:
		fx.fade = false
	map.add_child(fx)


func ice(state: int, id: int):
	for node in GMNode.all_of("obj_nap_iceblock"):
		if node.nid != id:
			continue
		node.change(state == 1)
		if state == 0:
			for i in 4:
				effect(
					"spr_nap_iceblock_part",
					node.position + Vector2(20, (i % 2) * 20),
					Vector2(-2 if i < 2 else 2, -3)
				)


func waypoints(id: int) -> Array:
	var points := GMNode.all_of("obj_nap_snowball_waypoint").filter(
		func(n): return int(n.properties.get("nid", 0)) == id
	)
	points.sort_custom(
		func(a, b): return int(a.properties.get("wid", 0)) < int(b.properties.get("wid", 0))
	)
	return points


func snowball(state: int, id: int, direction := 1, waypoint := 0, frame := 0, progress := 0.0):
	if state == 2:
		if balls.has(id):
			var node: GMNode = balls[id].node
			for i in 6:
				effect(
					"spr_nap_snowball_part",
					node.position - Vector2(0, 48),
					Vector2(randf_range(-5, 5), randf_range(-5, -2))
				)
			GameAudio.play_sound_at("snd_snowball_break", node.position)
			node.queue_free()
			balls.erase(id)
		return
	if not balls.has(id):
		var node = load("res://src/menu/gm_plain.gd").new()
		node.sprite_name = "spr_nap_snowball"
		node.image_speed = 0
		node.depth = 102
		node.image_alpha = 0
		node.image_xscale = direction
		map.add_child(node)
		balls[id] = {
			"node": node, "waypoint": 0, "frame": 0.0, "progress": 0.0, "timer": 0, "growth": 0.0
		}
	var data: Dictionary = balls[id]
	data.waypoint = waypoint
	data.frame = float(frame)
	data.progress = progress
	var path := waypoints(id)
	if waypoint + 1 >= path.size():
		return
	data.node.position = (
		path[waypoint].position.lerp(path[waypoint + 1].position, progress) + Vector2(32, 64)
	)
	data.node.image_index = frame
	data.node.queue_redraw()


func request(type: int, id: int, ray := false):
	var packet := Net.cpacket_tcp(type)
	packet.put_u8(id)
	if type == Net.PacketType.CLIENT_KAFMONITOR_ACTIVATE:
		packet.put_u8(int(ray))
	Net.send_server_tcp(packet)


func before_player(p):
	if p.isDead:
		return
	for block in GMNode.all_of("obj_nap_iceblock"):
		if not block.collision_active:
			continue
		var box: Rect2 = block.bbox_rect()
		var impact := false
		for foot in [
			Vector2(p.position.x - 6, p.position.y + 18),
			Vector2(p.position.x + 6, p.position.y + 18)
		]:
			if (
				p.yspd >= 0
				and p.position.y + 19 > box.position.y
				and box.has_point(foot + Vector2(0, 2 + p.yspd))
			):
				impact = true
		if impact:
			p.yspd = -5
			p.isJumping = true
			p.isGrounded = false
		if (
			impact
			or (
				(p.isAttacking or (Globals.character == 2 and p.isGliding))
				and box.intersects(p.bbox_rect())
			)
		):
			activate_ice(block)


func activate_ice(block):
	if block.request_cooldown > 0:
		return
	block.request_cooldown = 10
	request(Net.PacketType.CLIENT_NAPICE_ACTIVATE, block.nid)


func _physics_process(_dt):
	tick += 1
	flash = maxf(0, flash - 0.016)
	var p: GMNode = Globals.player
	if not is_instance_valid(p) or Net.gameEnds:
		return
	for block in GMNode.all_of("obj_nap_iceblock"):
		if not block.collision_active:
			continue
		for ray in GMNode.all_of("obj_tails_projectile"):
			if ray.is_owner and ray.bbox_rect().intersects(block.bbox_rect()):
				activate_ice(block)
	for data in balls.values():
		data.node.image_alpha = minf(1, data.node.image_alpha + 0.016)
		data.node.queue_redraw()
		data.timer += 1
		if data.timer % 30 == 0:
			GameAudio.play_sound_at("snd_snowball_roll", data.node.position)
		if data.frame >= 8 and data.node.bbox_rect().intersects(p.bbox_rect()):
			p.apply_slow(180, 0.6)
	weather(p)


func weather(p):
	var camera := Vector2.ZERO
	for c in GMNode.all_of("obj_camera"):
		camera = c.render_origin
	var inside := false
	for zone in GMNode.all_of("obj_nap_trigger"):
		if zone.bbox_rect().intersects(p.bbox_rect()):
			inside = true
	if not inside:
		for i in 10 if map.lvl_id == 12 else 5:
			particles.append(
				{
					"at":
					(
						camera + Vector2(randf_range(-120, 560), -1)
						if i % 5 < 3
						else camera + Vector2(481, randf_range(-120, 350))
					),
					"speed": randf_range(-1, 0) if map.lvl_id == 12 else randf_range(-1, 1),
					"life": 90 if map.lvl_id == 12 else 120
				}
			)
	for i in range(particles.size() - 1, -1, -1):
		var a: Dictionary = particles[i]
		a.at += Vector2(-3 - a.speed, (5 if map.lvl_id == 12 else 2) + a.speed)
		a.life -= 1
		if a.life <= 0:
			particles.remove_at(i)
	queue_redraw()


func _draw():
	var texture := GM.sprite_texture("spr_ghz_rain" if map.lvl_id == 12 else "spr_nap_snow", 0)
	for item in particles:
		if texture != null:
			draw_texture(texture, item.at.floor())
