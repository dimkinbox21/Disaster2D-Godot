extends "res://src/game/maps/shared/rules.gd"
## Priceless Freedom: presentation and network effects.
var state: Dictionary = {}
var received_frame = 0
var rings: Dictionary = {}
var requests: Dictionary = {}
var held_lift = -1
var held_controls = true


func nodes(type: String) -> Array:
	return GMNode.all_of(type)


func _ready():
	process_physics_priority = 60
	for type in ["obj_weed", "obj_weed_zone", "obj_marijuna_crystalcontroller"]:
		for n in nodes(type):
			n.gm_visible = false
			n.set_physics_process(false)
	var layer = CanvasLayer.new()
	layer.layer = 9
	map.add_child(layer)
	var overlay = load("res://src/game/maps/priceless_freedom/overlay.gd").new()
	overlay.rules = self
	layer.add_child(overlay)


func _exit_tree():
	if held_lift >= 0:
		Globals.playerControls = held_controls


func request(type: int, id: int):
	var key = str(type) + ":" + str(id)
	if frame < int(requests.get(key, 0)):
		return
	requests[key] = frame + 10
	Net._send_player_data()
	var b = Net.cpacket_tcp(type)
	if type == Net.PacketType.CLIENT_BRING_COLLECTED:
		b.put_u16(id)
	else:
		b.put_u8(id)
	Net.send_server_tcp(b)


func receive(data: Dictionary):
	if int(data.get("map", -1)) != 10:
		return
	var old: Dictionary = state
	state = data
	received_frame = frame
	for id in data.rings:
		var item: Dictionary = data.rings[id]
		if item.active:
			if not rings.has(id):
				var n = load("res://src/game/hunters/black_ring.gd").new()
				n.nid = int(id)
				n.position = Vector2(item.x, item.y)
				map.add_child(n)
				rings[id] = n
		elif rings.has(id):
			Net.consume_black_ring(int(id), false)
			rings.erase(id)
	for event in data.get("events", []):
		if int(event.owner) >= 0 and int(event.owner) != Net.nid:
			continue
		var at = Vector2(event.x, event.y)
		match str(event.kind):
			"lift_start", "lift_end", "lift_reset":
				if event.kind == "lift_end":
					for n in nodes("obj_pf_lift"):
						GameAudio.play_sound_at("snd_lift", n.position)
				if (
					event.kind == "lift_end"
					and int(event.player) == Net.nid
					and is_instance_valid(Globals.player)
				):
					Globals.player.position = at
					Globals.player.yspd = -3
					Globals.player.isGrounded = false


func _physics_process(_delta):
	frame += 1
	var p = Globals.player
	if not is_instance_valid(p):
		return
	if Net.gameEnds:
		if_release()
		return
	var cam = Vector2.ZERO
	for camera in nodes("obj_camera"):
		cam = camera.render_origin
		break
	update_lifts(p)


func if_release():
	if held_lift >= 0:
		Globals.playerControls = held_controls
		held_lift = -1


func update_lifts(p):
	var local_lift = -1
	for n in nodes("obj_pf_lift"):
		var id = str(int(n.properties.nid))
		var lift: Dictionary = state.get("lifts", {}).get(id, {})
		if lift.is_empty():
			continue
		n.position.y = float(lift.y)
		if int(lift.owner) >= 0:
			n.position.y = maxf(
				float(lift.end), n.position.y - float(lift.speed) * (frame - received_frame)
			)
		n.image_alpha = move_toward(n.image_alpha, 0 if int(lift.cooldown) > 0 else 1, 0.016)
		n.image_index = 1 if int(lift.owner) >= 0 else 0
		n.queue_redraw()
		if int(lift.owner) == Net.nid:
			local_lift = int(id)
			if held_lift < 0:
				held_controls = Globals.playerControls
			held_lift = local_lift
			Globals.playerControls = false
			p.position = Vector2(n.position.x, n.position.y - 16)
			p.xspd = 0
			p.yspd = 0
			p.gspd = 0
			p.isHurt = false
			p.isFlying = false
			p.isSpinning = false
			p.isJumping = false
			p.isGrounded = false
			p.isAttacking = false
			p.state = 5
			p.image_speed = 0.5
			if (
				Globals.character == 0
				and Globals.exeCharacter == Globals.EXE_ORIGINAL
				and p.invisTimer > 0
			):
				p.sprite_name = "spr_exe_invis_hurt"
			elif (
				Globals.character == 0
				and Globals.exeCharacter == Globals.EXE_CHAOS
				and p.hunter != null
				and p.hunter.slimeTimer > 0
			):
				p.sprite_name = "spr_chaos_sidle"
			elif not p.anims_cur.is_empty():
				p.sprite_name = p.anims_cur[5]
		elif int(lift.owner) >= 0:
			for puppet in nodes("obj_player_puppet"):
				if puppet.master_id == int(lift.owner):
					puppet.position = Vector2(n.position.x, n.position.y - 16)
					puppet.pstate = 5
					puppet.apply_anim()
		elif (
			p.hp > 0
			and n.image_alpha >= 1
			and int(lift.cooldown) == 0
			and n.bbox_rect().intersects(p.bbox_rect())
		):
			request(Net.PacketType.CLIENT_PFLIT_ACTIVATE, int(id))
	if local_lift < 0:
		if_release()
