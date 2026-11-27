extends "res://src/game/maps/shared/rules.gd"
## Volcano Valley: presentation and network effects.
var state: Dictionary = {}
var received_frame = 0
var requests: Dictionary = {}


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
	var overlay = load("res://src/game/maps/volcano_valley/overlay.gd").new()
	overlay.rules = self
	layer.add_child(overlay)


func _exit_tree():
	pass


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
	if int(data.get("map", -1)) != 11:
		return
	var old: Dictionary = state
	state = data
	received_frame = frame
	for n in nodes("obj_vv_vase"):
		if data.vases.get(str(int(n.properties.nid)), false):
			n.gm_visible = false
			n.visible = false
	for event in data.get("events", []):
		if int(event.owner) >= 0 and int(event.owner) != Net.nid:
			continue
		var at = Vector2(event.x, event.y)
		match str(event.kind):
			"vase":
				GameAudio.play_sound_at("snd_vasebreak", at)
				for count in randi_range(6, 8):
					var n = load("res://src/game/maps/freedom_piece.gd").new()
					n.sprite_name = "spr_vv_vasepiece"
					n.position = at
					n.velocity = Vector2(
						randi_range(2, 4) * [-1, 1].pick_random(), randi_range(-4, -2)
					)
					map.add_child(n)
				if (
					int(event.player) == Net.nid
					and is_instance_valid(Globals.player)
					and not event.heal
				):
					GameAudio.play_sound("snd_heal" if event.heal else "snd_ring")
					Globals.player.quick_effect(
						Globals.player.position.x,
						Globals.player.position.y,
						"spr_heal_part" if event.heal else "spr_ring_sparkle"
					)


func _physics_process(_delta):
	frame += 1
	var p = Globals.player
	if not is_instance_valid(p):
		return
	if Net.gameEnds:
		return
	var cam = Vector2.ZERO
	for camera in nodes("obj_camera"):
		cam = camera.render_origin
		break
	update_volcano(p)


func update_volcano(p):
	for n in nodes("obj_vv_lavacolumn"):
		var column: Dictionary = state.get("columns", {}).get(str(int(n.properties.nid)), {})
		if column.is_empty():
			continue
		n.position.y = predicted_lava(column)
		n.depth = 249
		n.z_index = -249
		if str(n.properties.isHigh).to_lower() in ["true", "1"]:
			n.sprite_name = "spr_vv_lavacolumn2"
		if int(column.state) in [2, 3] and frame % 19 == 0:
			GameAudio.play_sound_at("snd_lavaappear", n.position)
		n.queue_redraw()
	for n in nodes("obj_vv_vase"):
		if not n.visible:
			continue
		var attacking = (
			p.isAttacking and Globals.character in [2, 3, 4, 6]
			or p.isSpinning
			or (not p.isGrounded and p.yspd > 0)
			or (Globals.character == 4 and p.state == 15)
			or (Globals.character == 6 and p.state == 16)
		)
		if (
			Globals.character > 0
			and p.hp > 0
			and p.revivalTimes < 2
			and attacking
			and n.bbox_rect().intersects(p.bbox_rect())
		):
			request(Net.PacketType.CLIENT_VVVASE_BREAK, int(n.properties.nid))


func predicted_lava(item: Dictionary) -> float:
	var ticks = clampi(frame - received_frame, 0, 6)
	var phase = int(item.state)
	var y = float(item.y)
	if phase in [0, 3]:
		return (
			float(item.sy)
			- (float(item.dist) if phase == 3 else 0)
			+ sin((float(item.timer) - ticks) / 25) * 6
		)
	if phase == 1:
		return minf(float(item.sy) + 20, y + ticks * 0.15)
	for tick in ticks:
		y += (1 if phase == 4 else -1) * minf(5, float(item.speed) + tick * 0.08)
	return minf(float(item.sy), y) if phase == 4 else maxf(float(item.sy) - float(item.dist), y)
