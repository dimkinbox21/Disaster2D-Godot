extends "res://src/game/maps/shared/rules.gd"
## Limp City: presentation and network effects.
var state: Dictionary = {}
var previous_chain := 2
var request_until := 0
var eye_target: GMNode = null
var local_eye := -1


func _ready():
	process_physics_priority = 60
	z_index = -250
	for node in GMNode.all_of("obj_ycr_smokearea"):
		node.gm_visible = false
	map.add_child.call_deferred(load("res://src/game/maps/city_ambient.gd").new())


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


func receive(data: Dictionary):
	if int(data.get("map", -1)) != 5:
		return
	state = data
	update_city()


func update_city():
	var chain := int(state.chain)
	if chain != previous_chain:
		for n in nodes("obj_soundemitter"):
			if str(n.properties.get("stype", "")) in ["1", "SOUNDEMT_LCCHAIN"] and chain in [0, 1]:
				GameAudio.play_sound_at(
					"snd_echain_prepare" if chain == 0 else "snd_echain", n.position
				)
	previous_chain = chain
	eye_target = null
	local_eye = -1
	for n in nodes("obj_limpcity_eyeB"):
		n.sprite_name = "spr_limpcity_eye_recharge"
		n.image_index = 5
		n.set_meta("used", false)
	for id in state.eyes:
		var data: Dictionary = state.eyes[id]
		for n in nodes("obj_limpcity_eyeA"):
			if int(n.properties.nid) == int(id):
				n.image_index = floori(float(data.charge) / 100 * 5)
		if data.used:
			for n in nodes("obj_limpcity_eyeB"):
				if int(n.properties.nid) == int(data.target):
					n.sprite_name = "spr_limpcity_eye"
					n.set_meta("used", true)
					if int(data.owner) == Net.nid:
						eye_target = n
						local_eye = int(id)


func _physics_process(_delta):
	frame += 1
	var p: GMNode = Globals.player
	if not is_instance_valid(p) or Net.gameEnds:
		eye_target = null
		return
	for n in nodes("obj_limpcity_echain1") + nodes("obj_limpcity_echain2"):
		n.image_index = int(Time.get_ticks_msec() / 50) % 2 if previous_chain == 1 else 0
		n.image_speed = 0
		n.queue_redraw()
	var held: bool = p.isLookingDown or p.isLookingUp
	if local_eye >= 0 and (not held or p.isDead or p.isHurt):
		if frame >= request_until:
			request(Net.PacketType.CLIENT_LCEYE_REQUEST_ACTIVATE, local_eye, 0, false)
			request_until = frame + 10
		eye_target = null
	elif (
		local_eye < 0
		and held
		and frame >= request_until
		and Globals.character > 0
		and not p.isDead
		and p.revivalTimes < 2
	):
		for n in nodes("obj_limpcity_eyeA"):
			if n.bbox_rect().grow(4).intersects(p.bbox_rect()):
				request(
					Net.PacketType.CLIENT_LCEYE_REQUEST_ACTIVATE,
					int(n.properties.nid),
					int(n.properties.target1 if p.isLookingDown else n.properties.target2)
				)
				request_until = frame + 30
				break
