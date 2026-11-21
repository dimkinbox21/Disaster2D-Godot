extends "res://src/game/maps/shared/rules.gd"
## Ravine Mist: presentation and network effects.
var state: Dictionary = {}
var shards: Dictionary = {}
var slugs: Dictionary = {}
var shard_count := 0
var request_until := 0
var eye_target: GMNode = null


func _ready():
	process_physics_priority = 60
	z_index = -250
	for node in GMNode.all_of("obj_ycr_smokearea"):
		node.gm_visible = false


func nodes(type: String) -> Array:
	return GMNode.all_of(type)


func request(type: int, id: int, target := 0, active := true, ray := false):
	# Send movement first so server contact validation uses this frame.
	Net._send_player_data()
	var packet := Net.cpacket_tcp(type)
	if type == Net.PacketType.CLIENT_LCEYE_REQUEST_ACTIVATE:
		packet.put_u8(int(active))
		packet.put_u8(id)
		packet.put_u8(target)
	else:
		packet.put_u16(id)
		if type == Net.PacketType.CLIENT_RMZSLIME_HIT:
			packet.put_u8(int(ray))
	Net.send_server_tcp(packet)


func visual(sprite: String, at: Vector2) -> GMNode:
	var n = load("res://src/menu/gm_plain.gd").new()
	n.sprite_name = sprite
	n.position = at
	n.depth = 0
	map.add_child(n)
	return n


func receive(data: Dictionary):
	if int(data.get("map", -1)) != 1:
		return
	state = data
	var count := int(data.count)
	if count > shard_count:
		GameAudio.play_sound("snd_shard")
	shard_count = count
	update_ravine()


func update_ravine():
	for id in shards.keys():
		if not state.shards.has(id) or int(state.shards[id].owner) >= 0:
			var n: GMNode = shards[id]
			var fx = load("res://src/game/obj_quickfx.gd").new()
			fx.sprite_name = "spr_shard_sparkle"
			fx.position = n.position
			map.add_child(fx)
			n.queue_free()
			shards.erase(id)
	var counts: Dictionary = {}
	for id in state.shards:
		var data: Dictionary = state.shards[id]
		var owner := int(data.owner)
		if owner >= 0:
			counts[owner] = counts.get(owner, 0) + 1
			continue
		if not shards.has(id):
			shards[id] = visual("spr_ravinemist_shard", Vector2(data.x, data.y))
		var n: GMNode = shards[id]
		n.position = Vector2(data.x, data.y)
		n.set_meta("origin_y", float(data.y))
		n.set_meta("fall", data.fall)
	if is_instance_valid(Globals.player):
		Globals.player.shards = counts.get(Net.nid, 0)
	for p in nodes("obj_player_puppet"):
		p.shards = counts.get(p.master_id, 0)
	for id in state.slugs:
		var data: Dictionary = state.slugs[id]
		if not data.active:
			if slugs.has(id):
				var n: GMNode = slugs[id]
				var fx = load("res://src/game/obj_quickfx.gd").new()
				fx.fade = false
				fx.sprite_name = "spr_ravinemist_sonicdead"
				fx.position = n.position
				fx.image_xscale = n.image_xscale
				map.add_child(fx)
				n.queue_free()
				slugs.erase(id)
				GameAudio.play_sound_at("snd_slime", n.position)
			continue
		if not slugs.has(id):
			slugs[id] = visual("spr_ravinemist_sonic", Vector2(data.x, data.y))
			slugs[id].image_alpha = 0
		var n: GMNode = slugs[id]
		n.set_meta("target", Vector2(data.x, data.y))
		n.sprite_name = ["spr_ravinemist_sonic", "spr_ravinemist_sonic2", "spr_ravinemist_sonic3"][
			int(data.state) / 2
		]
		n.image_xscale = 1 if int(data.state) % 2 == 0 else -1


func _physics_process(_delta):
	frame += 1
	var p: GMNode = Globals.player
	if not is_instance_valid(p) or Net.gameEnds:
		eye_target = null
		return
	for id in shards:
		var n: GMNode = shards[id]
		if not n.get_meta("fall", false):
			n.position.y = n.get_meta("origin_y") + sin(Time.get_ticks_msec() / 200.0) * 3
		n.queue_redraw()
		if (
			frame >= request_until
			and Globals.character > 0
			and not p.isDead
			and p.revivalTimes < 2
			and n.bbox_rect().intersects(p.bbox_rect())
		):
			request(Net.PacketType.CLIENT_RMZSHARD_COLLECT, int(id))
			request_until = frame + 10
	for id in slugs:
		var n: GMNode = slugs[id]
		n.position = n.position.lerp(n.get_meta("target"), 0.5)
		n.image_alpha = minf(1, n.image_alpha + 0.016)
		n.queue_redraw()
		var ray := false
		for shot in nodes("obj_tails_projectile") + nodes("obj_exetior_stompballs"):
			if (
				(shot.get("is_owner") == true or shot.gm_name == "obj_exetior_stompballs")
				and shot.bbox_rect().intersects(n.bbox_rect())
			):
				ray = true
		var contact: bool = n.bbox_rect().intersects(p.bbox_rect())
		var attacking: bool = (
			p.isAttacking
			or (Globals.character > 0 and (p.isJumping or p.isSpinning))
			or (Globals.character == 4 and p.state == p.FALL)
			or (Globals.character == 6 and p.state == 16)
		)
		if n.image_alpha >= 1 and frame >= request_until and (ray or (contact and attacking)):
			if contact and p.isJumping:
				p.yspd = -5
				p.isGrounded = false
			request(Net.PacketType.CLIENT_RMZSLIME_HIT, int(id), 0, true, ray)
			request_until = frame + 10
